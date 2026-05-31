# eParking UI

Flutter klijenti za parking rezervacije.

## Struktura

```
UI/
├── eParking_desktop/   # Admin (Windows / Web / desktop)
└── eParking_mobile/    # Korisnici (Android / iOS)
```

Svaki projekat ima standardnu Flutter strukturu: `lib/`, `android/`, `ios/`, `windows/`, `web/`, `test/`, `pubspec.yaml`, itd.

## Pokretanje

Backend API mora raditi (`dotnet run` u `eParking.WebAPI`).

**Desktop (Windows):**
```bash
cd UI/eParking_desktop
flutter run -d windows
```

**Mobilna (emulator ili uređaj):**
```bash
cd UI/eParking_mobile
flutter run
```

## API

Podrazumijevani URL: `http://localhost:5126`  
Dokumentacija: `http://localhost:5126/scalar/v1`
