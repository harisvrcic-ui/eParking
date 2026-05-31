# eParking

Sistem za rezervaciju parking mjesta — REST API, desktop admin aplikacija i mobilna korisnička aplikacija.

## Struktura projekta

```
eParking/
├── .env.example                 # Predložak centralne konfiguracije
├── eParking.WebAPI/             # ASP.NET Core REST API
├── eParking.Services/           # Poslovna logika
├── eParking.Model/              # DTO modeli
├── eParking.Services.Tests/     # Unit testovi (pricing, state machine)
├── eParking.Worker/             # RabbitMQ consumer (async obavještenja)
├── UI/eParking_desktop/         # Flutter admin (Windows)
├── UI/eParking_mobile/          # Flutter mobilna app (Android/iOS)
└── docker-compose.yml           # SQL Server + RabbitMQ + API + Worker
```

## Preduvjeti

- .NET 9 SDK
- SQL Server (lokalno) **ili** Docker Desktop
- Flutter SDK (za UI)

## Konfiguracija 

Svi osjetljivi i operativni podaci su **centralizirani u `.env`** datoteci u korijenu repozitorija.
`appsettings.json` sadrži samo logging — **bez** connection stringa, JWT key-a, RabbitMQ lozinki itd.

```powershell
cd eParking
copy .env.example .env
```

| Varijabla | Opis |
|-----------|------|
| `ConnectionStrings__DefaultConnection` | SQL Server connection string |
| `Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience` | JWT autentifikacija |
| `RabbitMQ__Host`, `RabbitMQ__Username`, `RabbitMQ__Password`, `RabbitMQ__Port` | RabbitMQ |
| `RabbitMQ__Enabled` | `true` = RabbitMQ + Worker; `false` = direktan upis notifikacija u bazu |
| `Smtp__*` | Reset lozinke (e-mail s kodom); prazan `Host` = dev mod (kod u API odgovoru) |
| `Stripe__SecretKey` | Rezervisano (nije u upotrebi) |

**Lokalni `dotnet run`:** u `.env` postavi lokalni connection string i `RabbitMQ__Enabled=false` (vidi komentare u `.env.example`).

**Docker:** `.env.example` već sadrži Docker vrijednosti (`sqlserver`, `rabbitmq` hostovi).

**Flutter API URL** — isključivo preko `--dart-define` (čita se u kodu preko `String.fromEnvironment('API_BASE_URL')`):

```powershell
# Desktop (Windows)
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5126

# Android emulator
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5126

# Fizički uređaj (zamijeni IP računara)
flutter run --dart-define=API_BASE_URL=http://192.168.1.10:5126
```

## Pokretanje — lokalno (bez Docker-a)

### 1. Konfiguracija + API

```powershell
cd eParking
copy .env.example .env
# uredi .env za lokalni SQL (Trusted_Connection) i RabbitMQ__Enabled=false
dotnet run --project eParking.WebAPI\eParking.WebAPI.csproj --launch-profile http
```

API: `http://localhost:5126`  
Scalar dokumentacija: `http://localhost:5126/scalar/v1`

### 2. Desktop admin

```powershell
cd UI\eParking_desktop
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5126
```

### 3. Mobilna aplikacija

```powershell
cd UI\eParking_mobile
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5126
```

### 4. Unit testovi

```powershell
dotnet test eParking.Services.Tests
```

## Pokretanje — Docker

Pokreni iz **korijena repozitorija** (gdje je `docker-compose.yml` i `eParking.sln`):

```powershell
cd eParking
copy .env.example .env
docker compose down -v
docker builder prune -f
docker compose up --build
```

API će biti dostupan na `http://localhost:5126` (prvi put SQL Server može trebati ~1 min).

**Servisi u stacku:** SQL Server, RabbitMQ (management UI: `http://localhost:15672`, kredencijali iz `.env`), API i Worker.

Flutter klijenti prema Docker API-ju:

```powershell
flutter run -d windows --dart-define=API_BASE_URL=http://localhost:5126
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:5126
```

### Mikroservisi 
Asinkroni tok obavještenja pri kreiranju rezervacije:

```
Mobile/Desktop → API (POST rezervacija)
       ↓
   RabbitMQ queue: eparking.notifications
       ↓
   eParking.Worker → upis u UserNotifications (SQL)
```

- API publisha poruku u RabbitMQ (`RabbitMQ__Enabled=true` u `.env` za Docker).
- **Worker** je zaseban proces/kontejner koji konzumira poruke i kreira zapis u tabeli `UserNotifications`.
- Lokalno bez RabbitMQ-a (`RabbitMQ__Enabled=false`): API koristi `DirectNotificationQueuePublisher` i upisuje notifikacije direktno u bazu.
- Test: mobile kreira rezervaciju (**Pending**) → desktop admin **Potvrdi** → u mobile profilu / desktop **Obavještenja** treba se pojaviti poruka.

Lokalno s RabbitMQ-om (opcionalno):

```powershell
docker run -d --name eparking-rabbit -p 5672:5672 -p 15672:15672 rabbitmq:3.13-management
# u .env postavi RabbitMQ__Enabled=true i guest kredencijale
dotnet run --project eParking.Worker\eParking.Worker.csproj
```

### Uobičajene Docker greške

| Greška | Uzrok | Rješenje |
|--------|--------|----------|
| `pre-login handshake` | API se spoji prije nego SQL bude spreman | Čekaj healthcheck; API ponavlja init do 30× |
| `MSB1009: Project file does not exist` | Pogrešan build context | `docker compose` pokreni iz foldera s `eParking.sln` |
| `Invalid object name` | Stara/prazna baza, legacy SQL | `docker compose down -v` pa ponovo `up --build` |
| `failed to compute cache key` | Ogromni Flutter `build/` u contextu | `.dockerignore` isključuje `UI/`, `bin/`, `obj/` |
| `Index was out of range` | Rijetko u seed hashu | Ispravljeno u `PasswordHasher` |

Ako port **1433** na hostu već koristi lokalni SQL Server, zaustavi ga ili promijeni mapiranje porta u `docker-compose.yml`.

## Korisnički nalozi



| Kontekst | Korisničko ime | Lozinka | JWT rola | Aplikacija |
|----------|----------------|---------|----------|------------|
| Desktop verzija | `desktop` | `test` | **Admin** | Desktop → `POST /Auth/admin-login` |
| Mobilna verzija | `mobile` | `test` | **User** | Mobile → `POST /Auth/login` |
| Više korisničkih uloga | `admin` | `admin` | **Admin** | Desktop (alias) |
| Više korisničkih uloga | `user` | `user` | **User** | Mobile (alias) |
| Više korisničkih uloga | `haris` | `haris` | **User** | Mobile (dodatni demo) |

Uloge u JWT-u odgovaraju seed podacima: `IsAdmin=true` → rola `Admin`, `IsUser=true` → rola `User` (vidi `AppRoles` i `JwtTokenService`).

> Pri svakom pokretanju API-ja lozinke se usklađuju s gornjim vrijednostima ako korisnik još nije promijenio lozinku (dev seed).

**Promjena lozinke (mobilni korisnik):** Profil → Uredi profil → sekcija *Promjena lozinke* (trenutna + nova lozinka).  
API: `PUT /Account/me/password` (zahtijeva JWT).

**Zaboravljena lozinka:** `POST /Auth/forgot-password` → `POST /Auth/reset-password` (anonimno, kao login/register).

## Autentifikacija

API koristi **JWT Bearer token** s `jti` claimom. Nakon prijave, klijenti šalju header:

```
Authorization: Bearer <token>
```

JWT konfiguracija je u **`.env`** (`Jwt__Key`, `Jwt__Issuer`, `Jwt__Audience`).

- **Globalna politika:** svi endpointi zahtijevaju JWT osim `[AllowAnonymous]` (`/Auth/login`, `/Auth/admin-login`, `/Auth/register`, `/Auth/forgot-password`, `/Auth/reset-password`).
- **Registracija:** `POST /Auth/register` — kreira korisnika s ulogom `User` (`IsAdmin` se ne prihvaća od klijenta); vraća JWT kao login.
- **Admin CRUD:** POST/PUT/DELETE na parking lokacijama, mjestima, recenzijama i favoritima — samo uloga `Admin`.
- **Korisnički resursi:** vozila i rezervacije se filtriraju i provjeravaju prema `userId` iz JWT-a (mobilni klijent ne šalje `userId` u tijelu).
- **Slike (vozila, brendovi, news):** upload kao base64; server provjerava magic bytes (JPEG, PNG, GIF, WebP).
- **Odjava:** `POST /Auth/logout` (zahtijeva JWT) stavlja token na blacklist do isteka; klijenti zovu endpoint pri odjavi.

## Poslovna logika rezervacija 

- **Statusi:** `Pending` → `Confirmed` → `Completed` / `Cancelled` (bez hard delete-a).
- **Kreiranje (mobile):** rezervacija ostaje **`Pending`** dok admin ne potvrdi; mjesto se blokira odmah (Pending + Confirmed).
- **Potvrda (admin):** `POST /Reservations/{id}/confirm` — samo za `Pending`; ponovna provjera zauzetosti/duplikata.
- **State machine:** `ReservationStateMachine` — svi prelazi centralizovani u servisu.
- **Otkazivanje:** `POST /Reservations/{id}/cancel` (korisnik i admin); **odbijanje:** `POST /Reservations/{id}/reject` (admin, obavezan razlog, samo `Pending`).
- **Audit:** `StatusChangedAt`, `StatusChangedByUserId`, `StatusNote` na svakoj rezervaciji.
- **Zauzetost:** overlap provjera na backendu; otkazane/završene rezervacije ne blokiraju mjesto.
- **Recenzije:** dozvoljene tek nakon **Completed** rezervacije na tom parkingu.
- **Cijena:** `ReservationPricing` — unit testovi u `eParking.Services.Tests` (25h, 48h, daily/hourly).

**Demo flow:** mobile kreira → **Pending** → desktop admin **Potvrdi** / **Odbij** → mobile notifikacija + ažuriran status.

## Sistemske notifikacije i obavijesti 

### Notifikacije (`UserNotifications`)

- Polja: **pročitano/nepročitano** (`IsRead`), **naslov**, **tekst**, **datum** (`CreatedAt`)
- **Označi pročitano:** `PUT /UserNotifications/{id}/read`
- **Auto-refresh:** mobile polling svakih **12 s** (home badge + ekran notifikacija)
- **Događaji:** slanje zahtjeva (`Pending`), admin potvrda, otkazivanje, odbijanje, automatski završetak (`Completed` — `ReservationCompletionBackgroundService`, svaki minut)
- **Pipeline:** RabbitMQ + Worker (Docker) ili direktan upis u bazu kad je `RabbitMQ__Enabled=false`

### Obavijesti / News (`NewsItems`)

- Polja: **naslov**, **tekst**, **slika**, **datum**
- **API:** `GET /News` (korisnici vide aktivne, **bez slike u listi** — polje `HasImage`); puna slika na `GET /News/{id}`; admin CRUD na desktopu (**News** meni)
- **Mobile:** horizontalna lista obavijesti na home ekranu

## Desktop izvještaji (PDF)

U sekciji **Izvještaji i analitika** dostupna su **dva PDF izvještaja**:

| Izvještaj | Sadržaj |
|-----------|---------|
| **1. Mjesečni sažetak** | Prihod, rezervacije, novi korisnici, lista zadnjih rezervacija |
| **2. Korisnici** | Broj rezervacija i ukupna potrošnja po korisniku (top 30) |

Za svaki izvještaj: **Štampaj** (print dijalog) i **Preuzmi** (spremi PDF).

## Recommender sistem

Mobilna aplikacija prikazuje preporučene parkinge na home ekranu.  
Glavna logika: `UI/eParking_mobile/lib/services/recommendation_engine.dart`

## Tehnički i projektni standard 

- Nema ASP.NET template ostataka (`WeatherForecastController`), `NotImplementedException` ni `Console.WriteLine` u backendu.
- Logiranje preko **`ILogger<T>`** (API filter, servisi, Worker, RabbitMQ publisher).
- Backend servisi centralizovani u `eParking.Services` — bez dupliciranih klasa na dva mjesta.
- Flutter klijenti pozivaju isključivo postojeće API rute (vidi sekcije Auth, Rezervacije, Notifikacije).
- Konfiguracija u **`.env`**; `appsettings.json` samo logging.

## Performanse, paginacija i validacija 

- **Paginacija:** svi list endpointi vraćaju `PagedResponse<T>` (`items`, `totalCount`, `page`, `pageSize`); max **100** po stranici (`PaginationHelper.MaxPageSize`). Uključuje `GET /ParkingLots/overview`.
- **List vs detail:** liste **auta** i **brendova** ne vraćaju base64 slike u listi (slike na `GET /{id}`); **news** lista vraća `HasImage` bez bloba — puna slika na `GET /News/{id}` (mobile učitava detalj po stavci).
- **Filtriranje u bazi:** `ParkingLotService.GetOverviewAsync` / `GetDetailAsync` filtriraju spotove SQL `Where` (legacy `DisplayNameSearch` + `Zone.ParkingLotId`), ne učitavaju sve spotove pa filtriraju u memoriji.
- **Background poslovi:** `ReservationCompletionBackgroundService` (WebAPI) periodično završava istekle rezervacije; Worker i dalje konzumira RabbitMQ notifikacije.
- **Keš:** `LookupService` koristi `IMemoryCache` (10 min) za šifarnike.
- **SQL filter:** aktivne rezervacije filtrirane u bazi (`StartDate`/`EndDate`), ne u memoriji.
- **RefreshSpotCounts:** samo pri write operacijama, ne pri svakom read-u parkinga.
- **Async:** EF `*Async` metode; `Task.Delay` u bootstrap/background servisima (ne `Thread.Sleep`).

Klijenti: `getList()` automatski učitava **sve stranice** (`pageSize=100`) dok `totalCount` nije ispunjen.
