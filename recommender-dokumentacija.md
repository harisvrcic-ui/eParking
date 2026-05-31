 Sistem preporuke parking lokacija — eParking 

Dokument opisuje implementirani content-based recommender u mobilnoj aplikacji eParking.  
Glavna implementacija: UI/eParking_mobile/lib/services/recommendation_engine.dart.
 1. Svrha
Sistem preporuke rangira parking lokacije na home ekranu mobilne aplikacije i ističe najrelevantnije opcije korisniku (badge Top pick, EV, povoljno, natkriveno). Cilj je skratiti vrijeme pretrage i predložiti lokacije koje odgovaraju:

- eksplicitnim korisničkim preferencijama (postavke profila),
- historiji rezervacija,
- historiji pregleda detalja parkirališta,
- trenutnoj dostupnosti mjesta,
- geografskoj udaljenosti (GPS ili demo koordinate).

 2. Tip preporuke

| Karakteristika | eParking |
| Pristup | Content-based filtering|
| Collaborative filtering | Ne — ne koriste se preferencije drugih korisnika |
| Lokacija izvršavanja |Klijent (Flutter mobilna app) |
| Backend u scoring-u |Ne — API isporučuje podatke; rangiranje je na klijentu |

Content-based pristup znači da se svaka lokacija opisuje atributima sadržaja (zona, tipovi mjesta, cjenovni rang, EV/natkriveno), a korisnik se profilira prema vlastitoj historiji i postavkama.

 3. Komponente sistema
┌─────────────────────────────────────────────────────────────────┐
│                     Mobilna aplikacija                          │
├─────────────────────────────────────────────────────────────────┤
│  HomePage                                                       │
│    ├── ParkingService      → GET /ParkingLots/overview, spots   │
│    ├── ReservationService  → GET /Reservations (moje)         │
│    ├── PreferencesService  → SharedPreferences (preferencije)   │
│    ├── ViewHistoryService  → lokalni cache + POST .../record    │
│    ├── LocationService     → GPS / demo udaljenosti             │
│    └── RecommendationEngine → buildDisplayList() → rang lista   │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  REST API (podaci, ne rangiranje)                               │
│    • ParkingLots/overview — dostupnost po lokaciji              │
│    • ParkingSpots — tipovi mjesta po lokaciji                   │
│    • Reservations — historija korisnika                         │
│    • ParkingLotViewHistories/record — broj pregleda u bazi      │
└─────────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────────┐
│  Desktop admin                                                  │
│    • CRUD ParkingLotViewHistories — pregled signala po korisniku│
└─────────────────────────────────────────────────────────────────┘ 
4. Ulazni podaci

| Izvor | Podatak | Namjena |
| API ParkingLots/overview | lista lokacija, availableSpots, koordinate | baza za rangiranje |
| API parking spotovi | tip mjesta (Regular, Electric, …), zona | atributi lokacije |
| UserPreferences | EV, budget, nearby, covered, Zona 1/2 | eksplicitne preferencije |
| Reservation historija | lokacija, cijena rezervacije | profil korisnika |
| ViewHistoryService | broj pregleda po parkingLotId | implicitni interes |
| Geolocator | trenutna pozicija korisnika | udaljenost u km |
| LocationService | demo udaljenosti (Vijećnica, Baščaršija, Aria Mall) | fallback bez GPS-a |

Preferencije se čuvaju lokalno (PreferencesService - SharedPreferences).  
Pregledi se bilježe pri otvaranju ParkingLotDetailScreen(ViewHistoryService.recordLotView).

5. Atributi lokacije (LotFeatures)

Za svaku parking lokaciju iz spotova se izvode:

| Atribut | Opis |
| cityZone | Gradska zona (Zona 1 centar / Zona 2 periferija) |
| priceTier | low /mid / high — prosjek množilaca tipova mjesta |
| hasEv | postoji li Electric tip mjesta |
| hasCovered | Electric, Large, Covered, Indoor, Garage tipovi |

Cjenovni množitelji po tipu mjesta:

| Tip | Množilac |
| disabled | 0.5 |
| compact | 0.9 |
| regular | 1.0 |
| large | 1.2 |
| electric | 1.3 |

Prosjek množitelja - tier: < 0.95 = low, > 1.15 = high, inače mid.

6. Profil korisnika iz historije (UserContentProfile)
Iz rezervacija i pregleda gradi se profil bez podataka drugih korisnika:
| Polje | Način izračuna |
| reservationCountByLotId | broj rezervacija po lokaciji |
| mostFrequentLotId | lokacija s najviše rezervacija |
| preferredZone | zona s najviše rezervacija (glasovi po imenu lokacije) |
| preferredPriceTier | prosjek finalPrice: < 8 low, > 15 high, inače mid |
| hasReservationHistory | ima li ikakvu rezervaciju |
|hasViewHistory | ima li pregleda u viewCountByLotId |

7. Formula bodovanja (scoreLot)

Početni bodovi = availableSpots (više slobodnih mjesta - viši prioritet).

Dodatni bodovi:

| Signal | Uslov | Bodovi |
| EV preferencija | preferEvCharging && lokacija ima EV | +12 |
| Budget preferencija | preferBudget && priceTier == low | +10 |
| Natkriveno | preferCovered && hasCovered | +10 |
| Zona 1 | korisnik birao Zona 1 && lokacija u Zona 1 | +15 |
| Zona 2 | korisnik birao Zona 2 && lokacija u Zona 2 | +15 |
| Ista zona kao historija | preferredZone == zona lokacije | +12 |
| Isti cjenovni rang | preferredPriceTier == tier lokacije | +8 |
| Rezervacije | po rezervaciji na toj lokaciji | +6 |
| Pregledi | po pregledu detalja lokacije | +3 |
| Blizina |preferNearby && poznata udaljenost | (20 - min(km, 20)) |

Udaljenost (effectiveDistanceKm):

1. demo udaljenost po imenu lokacije (ako postoji),
2. udaljenost od GPS pozicije korisnika,
3. udaljenost od najčešće korištene lokacije (prostorna analiza),
4. uzima se minimum dostupnih udaljenosti.

8. Sortiranje liste

| Mod | Pravilo |
| preferNearby == true| prvo po udaljenosti , zatim po score |
| inače | samo po score  |

Prva stavka nakon sortiranja s score > 0 dobija badge Top pick.

9. Badge-ovi i objašnjenja (UI)

| Badge | Uslov |
| Top pick | index 0 nakon sortiranja, score > 0 |
| EV | preferencija EV && lokacija ima EV (prva takva u listi) |
| Affordable| preferencija budget && niska cijena |
| Covered | preferencija natkriveno && lokacija ima natkrivena mjesta |

Hint tekst za Top pick razlikuje slučaj s historijom rezervacija/pregleda od default preporuke.

Rezultat: lista ParkingLotDisplay na home ekranu (ParkingLotCard).

10. Persistencija i API signal pregleda
 Lokalno (mobilna app)

-Preferencije: SharedPreferences  (PreferencesService)
-Pregledi: SharedPreference + in-memory mapa (ViewHistoryService)
 Backend
- Tabela ParkingLotViewHistories: UserId, ParkingLotId, ViewCount, LastViewedAt
- Endpoint: POST /ParkingLotViewHistories/record — inkrement pregleda pri otvaranju detalja
- Admin desktop: sekcija Historija pregleda — CRUD i izvještajni signal za recommender
Ako API nije dostupan, pregled se i dalje bilježi lokalno (offline-friendly signal).
 
11. Tok podataka (korisni scenarij)

1. Korisnik se prijavi → učitaju se preferencije iz SharedPreferences.
2. Home ekran dohvaća overview parkinga, spotove, rezervacije, GPS.
3. ViewHistoryService.init() učita lokalne preglede.
4. RecommendationEngine.buildDisplayList() izračuna score za svaku lokaciju.
5. Lista se sortira i prikaže s badge-ovima.
6. Korisnik otvori detalj lokacije → recordLotView → lokalno + API.
7. Sljedeći refresh home ekrana koristi ažurirane preglede u scoring-u.

 12. Ograničenja i dizajnerske odluke

Nema ML modela — interpretabilan rule-based scoring 
Nema preporuke drugih korisnika — privatnost i jednostavnost.
Rangiranje na klijentu smanjuje opterećenje API-ja; podaci su već učitani za prikaz liste.
Demo udaljenosti omogućava smislene preporuke i na emulatoru bez GPS-a.

13. Povezani fajlovi

| Fajl | Uloga |
| UI/eParking_mobile/lib/services/recommendation_engine.dart | Scoring, sortiranje, badge-ovi |
| UI/eParking_mobile/lib/services/preferences_service.dart | Persistencija preferencija |
| UI/eParking_mobile/lib/services/view_history_service.dart | Signal pregleda |
| UI/eParking_mobile/lib/models/user_preferences.dart | Model preferencija |
| UI/eParking_mobile/lib/screens/home_page.dart | Poziv engine-a |
| UI/eParking_mobile/lib/screens/parking_lot_detail_screen.dart | Bilježenje pregleda |
| eParking.Services/ParkingLotViewHistoryService.cs | Backend CRUD + record |
| UI/eParking_desktop/lib/screens/pages/crud_pages.dart | Admin pregled historije |
 14. Testiranje preporuke

1. Prijava mobilnim nalogom (mobile / test).
2. Profil → Moje postavke — uključi/isključi EV, budget, nearby, zonu.
3. Otvori detalje različitih parkirališta (povećava view signal).
4. Napravi rezervaciju na jednoj lokaciji (povećava reservation signal).
5. Vrati se na home — redoslijed i Top pick badge trebaju reflektovati postavke i historiju.

15. Screenshoti i putanja

metode buildDisplayList i scoreLot
 
 


 
 
Emulator: home ekran nakon logina (mobile / test) s preporukom (Top pick) |
 
Putanja glavne logike recommender sistema:
UI/eParking_mobile/lib/services/recommendation_engine.dart
Putanja iz pokrenute aplikacije gdje se prikazuju preporuke:
UI/eParking_mobile/lib/screens/home_page.dart
 Koraci u aplikaciji (do preporuke)
1. Prijavi se: mobile / test (vidi README).
2. Otvori Početna — lista parkirališta s badge-om Top pick (ili drugim badge-om).
3. Po potrebi: Profil → Moje postavke → uključi preferencije, pa refresh home ekrana.





