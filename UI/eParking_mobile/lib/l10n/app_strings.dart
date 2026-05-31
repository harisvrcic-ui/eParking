import 'package:flutter/material.dart';

import 'locale_controller.dart';

/// Prijevodi BS / EN za mobilnu aplikaciju.
abstract class AppStrings {
  static AppStrings of(Locale locale) {
    return locale.languageCode == 'en' ? AppStringsEn() : AppStringsBs();
  }

  static AppStrings get current => of(LocaleController.instance.locale);

  String get languageName;
  String get languageBs;
  String get languageEn;

  String get loginTitle;
  String get loginSubtitle;
  String get username;
  String get password;
  String get signIn;

  String get registerTitle;
  String get registerSubtitle;
  String get createAccount;
  String get noAccountYet;
  String get alreadyHaveAccount;
  String get signInInstead;
  String get confirmPassword;
  String get gender;

  String get forgotPasswordLink;
  String get forgotPasswordTitle;
  String get forgotPasswordSubtitle;
  String get forgotPasswordSubmit;
  String get resetPasswordTitle;
  String get resetPasswordSubtitle;
  String get resetCode;
  String get resetCodeHint;
  String get passwordResetSuccess;
  String get changeProfilePhoto;
  String get removeProfilePhoto;
  String get profilePhotoUpdated;
  String get profilePhotoSelectedHint;
  String get profilePhotoPickFailed;
  String get validationResetCodeRequired;
  String get validationResetCodeFormat;
  String devResetCodeHint(String code);

  String get reviewsTitle;
  String get noReviews;
  String reviewsAverage(double avg, int count);
  String get addReview;
  String get editMyReview;
  String get reviewComment;
  String get reviewCommentHint;
  String get reviewSaved;
  String get reviewNeedCompleted;
  String get ratingLabel;

  String get navHome;
  String get navSearch;
  String get navReservations;
  String get navProfile;

  String hello(String name);
  String get mySettings;
  String get searchParkingHint;
  String get retry;
  String get noParkingLots;
  String spotsAvailable(int count);

  String get myPreferences;
  String get preferEv;
  String get preferBudget;
  String get preferNearby;
  String get preferCovered;
  String get geographicZone;
  String get allZones;
  String get zone1Centar;
  String get zone2Periferija;
  String get save;
  String get back;

  String get searchTitle;
  String get searchByNameHint;
  String get noFilterResults;
  String get city;
  String get allCities;
  String get availability;
  String get allAvailability;
  String get availableOnly;
  String get viewParking;

  String get parkingLotsTitle;
  String get details;
  String get distance;
  String get zonesInLot;

  String get profile;
  String get editProfile;
  String get profileUpdated;
  String get vehicleAdded;
  String get vehicleUpdated;
  String get myVehicles;
  String get myFavorites;
  String get myFavoritesTitle;
  String get noFavorites;
  String get addedToFavorites;
  String get removedFromFavorites;
  String get viewHistory;
  String get viewHistoryTitle;
  String get noViewHistory;
  String viewCountLabel(int count);
  String lastViewedLabel(String when);
  String get notifications;
  String get signOut;

  String get myReservations;
  String get activeReservations;
  String get reservationHistory;
  String get cancelReservation;
  String get cancelReservationQuestion;
  String get cancelReservationConfirm;
  String get no;
  String get yesCancel;
  String get reservationCancelled;
  String get reserved;
  String get completed;

  String get myVehiclesTitle;
  String get addVehicle;
  String get noVehicles;
  String get editVehicle;
  String get newVehicle;
  String get brand;
  String get color;
  String get saveChanges;
  String get deleteVehicleQuestion;
  String get deleteVehicleBody;
  String get delete;
  String get deleteConfirmTitle;
  String get irreversibleActionWarning;
  String deleteConfirmQuestion(String itemName);

  String get editProfileTitle;
  String get firstName;
  String get lastName;
  String get phone;
  String get changePasswordSection;
  String get currentPassword;
  String get newPassword;
  String get confirmNewPassword;
  String get passwordChanged;
  String get validationPasswordMismatch;
  String get validationCurrentPasswordWrong;
  String get requiredField;
  String get notificationsTitle;

  String get reserveSpot;
  String get selectFreeSpotFirst;
  String get noSpotsToShow;
  String get reservationTitle;
  String get confirmReservation;
  String get endAfterStart;
  String get reservationConfirmed;
  String get reservationSubmitted;
  String get reservationSubmittedMessage;
  String get statusPending;
  String get statusConfirmed;
  String get ok;
  String get vehicle;
  String get date;
  String get startTime;
  String get endTime;
  String get reservationType;
  String get confirmReservationQuestion;
  String get priceLabel;

  String validationRequired(String fieldName);
  String validationMinLength(String fieldName, int min);
  String validationMaxLength(String fieldName, int max);
  String get validationEmail;
  String get validationPhoneFormat;
  String get validationUsername;
  String get validationUsernameNoSpaces;
  String get validationPassword;
  String validationPasswordMin(int min);
  String get validationLicensePlate;
  String get validationLicensePlateFormat;
  String validationSelect(String fieldName);
  String get validationVehicle;
  String get validationReservationType;
  String get validationEndAfterStartDetailed;
  String get validationReviewRating;

  String get badgeTopPick;
  String get badgeEv;
  String get badgeAffordable;
  String get badgeCovered;
  String get preferredNameSuffix;
  String get hintTopPickDefault;
  String get hintEv;
  String get hintAffordable;
  String get hintCovered;
  String get hintTopPickWithHistory;
  String get noMobileAccess;
}

class AppStringsBs extends AppStrings {
  @override
  String get languageName => 'Jezik';
  @override
  String get languageBs => 'Bosanski';
  @override
  String get languageEn => 'English';

  @override
  String get loginTitle => 'eParking';
  @override
  String get loginSubtitle => 'Prijavite se na svoj račun';
  @override
  String get username => 'Korisničko ime';
  @override
  String get password => 'Lozinka';
  @override
  String get signIn => 'Prijava';

  @override
  String get registerTitle => 'Registracija';
  @override
  String get registerSubtitle => 'Kreirajte novi korisnički račun';
  @override
  String get createAccount => 'Registruj se';
  @override
  String get noAccountYet => 'Nemate račun?';
  @override
  String get alreadyHaveAccount => 'Već imate račun?';
  @override
  String get signInInstead => 'Prijava';
  @override
  String get confirmPassword => 'Potvrdite lozinku';
  @override
  String get gender => 'Spol';
  @override
  String get forgotPasswordLink => 'Zaboravili ste lozinku?';
  @override
  String get forgotPasswordTitle => 'Reset lozinke';
  @override
  String get forgotPasswordSubtitle =>
      'Unesite e-mail adresu računa. Poslat ćemo vam kod za reset lozinke.';
  @override
  String get forgotPasswordSubmit => 'Pošalji kod';
  @override
  String get resetPasswordTitle => 'Nova lozinka';
  @override
  String get resetPasswordSubtitle =>
      'Unesite kod iz e-maila i odaberite novu lozinku.';
  @override
  String get resetCode => 'Kod za reset';
  @override
  String get resetCodeHint => '6 cifara iz e-mail poruke';
  @override
  String get passwordResetSuccess =>
      'Lozinka je uspješno promijenjena. Prijavite se ponovo.';
  @override
  String get changeProfilePhoto => 'Promijeni fotografiju';
  @override
  String get removeProfilePhoto => 'Ukloni fotografiju';
  @override
  String get profilePhotoUpdated => 'Profilna fotografija je ažurirana.';
  @override
  String get profilePhotoSelectedHint =>
      'Fotografija odabrana. Pritisnite Spremi da je sačuvate.';
  @override
  String get profilePhotoPickFailed =>
      'Odabir slike nije uspio. Pokušajte ponovo.';
  @override
  String get validationResetCodeRequired =>
      'Kod za reset je obavezan — unesite 6-cifreni kod iz e-maila.';
  @override
  String get validationResetCodeFormat =>
      'Kod mora imati tačno 6 cifara (npr. 123456).';
  @override
  String devResetCodeHint(String code) =>
      'Development: kod za reset je $code (SMTP nije konfigurisan).';

  @override
  String get reviewsTitle => 'Recenzije';
  @override
  String get noReviews => 'Nema recenzija za ovu lokaciju.';
  @override
  String reviewsAverage(double avg, int count) =>
      'Prosječna ocjena: ${avg.toStringAsFixed(1)} ★ ($count)';
  @override
  String get addReview => 'Ostavi recenziju';
  @override
  String get editMyReview => 'Uredi moju recenziju';
  @override
  String get reviewComment => 'Komentar';
  @override
  String get reviewCommentHint => 'Opcionalno — podijelite iskustvo';
  @override
  String get reviewSaved => 'Recenzija je sačuvana.';
  @override
  String get reviewNeedCompleted =>
      'Recenziju možete ostaviti nakon završene rezervacije na ovoj lokaciji.';
  @override
  String get ratingLabel => 'Ocjena';

  @override
  String get navHome => 'Početna';
  @override
  String get navSearch => 'Pretraga';
  @override
  String get navReservations => 'Rezervacije';
  @override
  String get navProfile => 'Profil';

  @override
  String hello(String name) => 'Zdravo, $name! 👋';
  @override
  String get mySettings => 'Moje postavke (Zone, EV, itd.)';
  @override
  String get searchParkingHint => 'Pretraži parkinge';
  @override
  String get retry => 'Pokušaj ponovo';
  @override
  String get noParkingLots => 'Nema parkinza.';
  @override
  String spotsAvailable(int count) => '$count mjesta dostupno';

  @override
  String get myPreferences => 'Moje postavke';
  @override
  String get preferEv => 'Preferiram EV punjače';
  @override
  String get preferBudget => 'Povoljnije cijene';
  @override
  String get preferNearby => 'Prioritet blizine';
  @override
  String get preferCovered => 'Natkriven / zaštićen prostor';
  @override
  String get geographicZone => 'Geografska zona';
  @override
  String get allZones => 'Sve zone';
  @override
  String get zone1Centar => 'Zona 1 — centar';
  @override
  String get zone2Periferija => 'Zona 2 — periferija';
  @override
  String get save => 'Spremi';

  @override
  String get back => 'Nazad';

  @override
  String get searchTitle => 'Pretraga parkinga';
  @override
  String get searchByNameHint => 'Pretraži po nazivu parkinga';
  @override
  String get noFilterResults => 'Nema rezultata za odabrane filtere.';
  @override
  String get city => 'Grad';
  @override
  String get allCities => 'Svi gradovi';
  @override
  String get availability => 'Dostupnost';
  @override
  String get allAvailability => 'Sve';
  @override
  String get availableOnly => 'Slobodno';
  @override
  String get viewParking => 'Pogledaj parking';

  @override
  String get parkingLotsTitle => 'Parkinzi';
  @override
  String get details => 'Detalji';
  @override
  String get distance => 'Udaljenost';
  @override
  String get zonesInLot => 'Zone u parkiralištu';

  @override
  String get profile => 'Profil';
  @override
  String get editProfile => 'Uredi profil';
  @override
  String get profileUpdated => 'Profil ažuriran.';
  @override
  String get vehicleAdded => 'Vozilo je uspješno dodano.';
  @override
  String get vehicleUpdated => 'Vozilo je uspješno ažurirano.';
  @override
  String get myVehicles => 'Moja vozila';
  @override
  String get myFavorites => 'Omiljena parkirališta';
  @override
  String get myFavoritesTitle => 'Omiljena parkirališta';
  @override
  String get noFavorites => 'Nemate sačuvanih parkirališta.';
  @override
  String get addedToFavorites => 'Dodano u omiljena.';
  @override
  String get removedFromFavorites => 'Uklonjeno iz omiljenih.';
  @override
  String get viewHistory => 'Historija pregleda';
  @override
  String get viewHistoryTitle => 'Historija pregleda';
  @override
  String get noViewHistory => 'Još niste pregledali nijedno parkiralište.';
  @override
  String viewCountLabel(int count) => 'Pregleda: $count';
  @override
  String lastViewedLabel(String when) => 'Zadnji put: $when';
  @override
  String get notifications => 'Obavještenja';
  @override
  String get signOut => 'Odjava';

  @override
  String get myReservations => 'Moje rezervacije';
  @override
  String get activeReservations => 'Aktivne rezervacije';
  @override
  String get reservationHistory => 'Historija rezervacija';
  @override
  String get cancelReservation => 'Otkaži rezervaciju';
  @override
  String get cancelReservationQuestion => 'Otkaži rezervaciju?';
  @override
  String get cancelReservationConfirm => 'Da, otkaži';
  @override
  String get no => 'Ne';
  @override
  String get yesCancel => 'Da, otkaži';
  @override
  String get reservationCancelled => 'Rezervacija otkazana.';
  @override
  String get reserved => 'Rezervisano';
  @override
  String get completed => 'Završeno';

  @override
  String get myVehiclesTitle => 'Moja vozila';
  @override
  String get addVehicle => 'Dodaj vozilo';
  @override
  String get noVehicles => 'Nemate registriranih vozila.';
  @override
  String get editVehicle => 'Uredi vozilo';
  @override
  String get newVehicle => 'Novo vozilo';
  @override
  String get brand => 'Marka';
  @override
  String get color => 'Boja';
  @override
  String get saveChanges => 'Spremi promjene';
  @override
  String get deleteVehicleQuestion => 'Obriši vozilo?';
  @override
  String get deleteVehicleBody => 'Ova radnja se ne može poništiti.';
  @override
  String get delete => 'Obriši';

  @override
  String get deleteConfirmTitle => 'Potvrda brisanja';

  @override
  String get irreversibleActionWarning =>
      'Ova radnja je nepovratna i ne može se poništiti. Provjerite podatke prije nastavka.';

  @override
  String deleteConfirmQuestion(String itemName) =>
      'Jeste li sigurni da želite obrisati: $itemName?';

  @override
  String get editProfileTitle => 'Uredi profil';
  @override
  String get firstName => 'Ime';
  @override
  String get lastName => 'Prezime';
  @override
  String get phone => 'Telefon';
  @override
  String get changePasswordSection => 'Promjena lozinke';
  @override
  String get currentPassword => 'Trenutna lozinka';
  @override
  String get newPassword => 'Nova lozinka';
  @override
  String get confirmNewPassword => 'Potvrdi novu lozinku';
  @override
  String get passwordChanged => 'Lozinka je promijenjena.';
  @override
  String get validationPasswordMismatch => 'Nova lozinka i potvrda se ne podudaraju.';
  @override
  String get validationCurrentPasswordWrong => 'Trenutna lozinka nije ispravna.';
  @override
  String get requiredField => 'Obavezno polje';
  @override
  String get notificationsTitle => 'Obavještenja';

  @override
  String get reserveSpot => 'Rezerviši';
  @override
  String get selectFreeSpotFirst => 'Prvo odaberi slobodno mjesto.';
  @override
  String get noSpotsToShow => 'Nema mjesta za prikaz.';
  @override
  String get reservationTitle => 'Rezervacija mjesta';
  @override
  String get confirmReservation => 'Potvrdi rezervaciju';
  @override
  String get endAfterStart => 'Kraj mora biti poslije početka.';
  @override
  String get reservationConfirmed => 'Rezervacija potvrđena';
  @override
  String get reservationSubmitted => 'Zahtjev poslan';
  @override
  String get reservationSubmittedMessage =>
      'Vaša rezervacija je poslana i čeka potvrdu administratora. Obavijest ćete dobiti u profilu.';
  @override
  String get statusPending => 'Na čekanju';
  @override
  String get statusConfirmed => 'Potvrđeno';
  @override
  String get ok => 'OK';
  @override
  String get vehicle => 'Vozilo';
  @override
  String get date => 'Datum';
  @override
  String get startTime => 'Početak';
  @override
  String get endTime => 'Kraj';
  @override
  String get reservationType => 'Tip rezervacije';
  @override
  String get confirmReservationQuestion => 'Želite li potvrditi rezervaciju?';
  @override
  String get priceLabel => 'Cijena';

  @override
  String validationRequired(String fieldName) =>
      'Polje "$fieldName" je obavezno — unesite vrijednost.';
  @override
  String validationMinLength(String fieldName, int min) =>
      'Polje "$fieldName" mora imati najmanje $min znaka.';
  @override
  String validationMaxLength(String fieldName, int max) =>
      'Polje "$fieldName" smije imati najviše $max znakova.';
  @override
  String get validationEmail =>
      'Unesite ispravnu e-mail adresu u formatu korisnik@domena.com.';
  @override
  String get validationPhoneFormat =>
      'Telefon: 8–15 cifara, dozvoljeni +, razmaci i crtice (npr. +387 61 123 456).';
  @override
  String get validationUsername =>
      'Korisničko ime je obavezno — najmanje 3 znaka, bez razmaka.';
  @override
  String get validationUsernameNoSpaces =>
      'Korisničko ime ne smije sadržavati razmake (npr. korisnik1).';
  @override
  String get validationPassword => 'Lozinka je obavezna — unesite lozinku.';
  @override
  String validationPasswordMin(int min) =>
      'Lozinka mora imati najmanje $min znakova (slova i/ili brojevi).';
  @override
  String get validationLicensePlate =>
      'Registarske tablice su obavezne — unesite oznaku vozila.';
  @override
  String get validationLicensePlateFormat =>
      'Tablice: 4–12 znakova, slova, brojevi i crtice (npr. A12-B-345).';
  @override
  String validationSelect(String fieldName) =>
      'Polje "$fieldName" je obavezno — odaberite vrijednost iz liste.';
  @override
  String get validationVehicle =>
      'Vozilo je obavezno — odaberite registrirano vozilo iz liste.';
  @override
  String get validationReservationType =>
      'Tip rezervacije je obavezan — odaberite tip (npr. satna, dnevna).';
  @override
  String get validationEndAfterStartDetailed =>
      'Kraj rezervacije mora biti poslije početka (kasniji datum ili sat).';
  @override
  String get validationReviewRating =>
      'Ocjena je obavezna — odaberite 1 do 5 zvjezdica.';

  @override
  String get badgeTopPick => 'Top Pick for You ⭐';
  @override
  String get badgeEv => 'Perfect for EV ⚡';
  @override
  String get badgeAffordable => 'Affordable Pick 🏷️';
  @override
  String get badgeCovered => 'Covered parking 🏗️';
  @override
  String get preferredNameSuffix => ' (Preferred)';
  @override
  String get hintTopPickDefault => 'Najbolji sklad s vašim postavkama';
  @override
  String get hintEv => 'Dostupna mjesta s EV punjačem';
  @override
  String get hintAffordable => 'Povoljniji cjenovni rang';
  @override
  String get hintCovered => 'Dostupan natkriven / zaštićen prostor';
  @override
  String get hintTopPickWithHistory => 'usklađeno s vašim rezervacijama i pregledima';
  @override
  String get noMobileAccess => 'Nemate pristup mobilnoj aplikaciji.';
}

class AppStringsEn extends AppStrings {
  @override
  String get languageName => 'Language';
  @override
  String get languageBs => 'Bosnian';
  @override
  String get languageEn => 'English';

  @override
  String get loginTitle => 'eParking';
  @override
  String get loginSubtitle => 'Sign in to your account';
  @override
  String get username => 'Username';
  @override
  String get password => 'Password';
  @override
  String get signIn => 'Sign in';

  @override
  String get registerTitle => 'Register';
  @override
  String get registerSubtitle => 'Create a new account';
  @override
  String get createAccount => 'Create account';
  @override
  String get noAccountYet => "Don't have an account?";
  @override
  String get alreadyHaveAccount => 'Already have an account?';
  @override
  String get signInInstead => 'Sign in';
  @override
  String get confirmPassword => 'Confirm password';
  @override
  String get gender => 'Gender';
  @override
  String get forgotPasswordLink => 'Forgot password?';
  @override
  String get forgotPasswordTitle => 'Reset password';
  @override
  String get forgotPasswordSubtitle =>
      'Enter your account email. We will send you a reset code.';
  @override
  String get forgotPasswordSubmit => 'Send code';
  @override
  String get resetPasswordTitle => 'New password';
  @override
  String get resetPasswordSubtitle =>
      'Enter the code from your email and choose a new password.';
  @override
  String get resetCode => 'Reset code';
  @override
  String get resetCodeHint => '6 digits from the email';
  @override
  String get passwordResetSuccess =>
      'Password changed successfully. Please sign in again.';
  @override
  String get changeProfilePhoto => 'Change photo';
  @override
  String get removeProfilePhoto => 'Remove photo';
  @override
  String get profilePhotoUpdated => 'Profile photo updated.';
  @override
  String get profilePhotoSelectedHint =>
      'Photo selected. Tap Save to apply it.';
  @override
  String get profilePhotoPickFailed =>
      'Could not pick an image. Please try again.';
  @override
  String get validationResetCodeRequired =>
      'Reset code is required — enter the 6-digit code from email.';
  @override
  String get validationResetCodeFormat =>
      'Code must be exactly 6 digits (e.g. 123456).';
  @override
  String devResetCodeHint(String code) =>
      'Development: reset code is $code (SMTP not configured).';

  @override
  String get reviewsTitle => 'Reviews';
  @override
  String get noReviews => 'No reviews for this location yet.';
  @override
  String reviewsAverage(double avg, int count) =>
      'Average rating: ${avg.toStringAsFixed(1)} ★ ($count)';
  @override
  String get addReview => 'Leave a review';
  @override
  String get editMyReview => 'Edit my review';
  @override
  String get reviewComment => 'Comment';
  @override
  String get reviewCommentHint => 'Optional — share your experience';
  @override
  String get reviewSaved => 'Review saved.';
  @override
  String get reviewNeedCompleted =>
      'You can leave a review after a completed reservation at this location.';
  @override
  String get ratingLabel => 'Rating';

  @override
  String get navHome => 'Home';
  @override
  String get navSearch => 'Search';
  @override
  String get navReservations => 'Reservations';
  @override
  String get navProfile => 'Profile';

  @override
  String hello(String name) => 'Hello, $name! 👋';
  @override
  String get mySettings => 'My settings (Zones, EV, etc.)';
  @override
  String get searchParkingHint => 'Search parking lots';
  @override
  String get retry => 'Try again';
  @override
  String get noParkingLots => 'No parking lots found.';
  @override
  String spotsAvailable(int count) => '$count spots available';

  @override
  String get myPreferences => 'My preferences';
  @override
  String get preferEv => 'Prefer EV charging';
  @override
  String get preferBudget => 'Lower prices';
  @override
  String get preferNearby => 'Prioritize nearby';
  @override
  String get preferCovered => 'Covered / sheltered parking';
  @override
  String get geographicZone => 'Parking zone';
  @override
  String get allZones => 'All zones';
  @override
  String get zone1Centar => 'Zone 1 — city center';
  @override
  String get zone2Periferija => 'Zone 2 — outskirts';
  @override
  String get save => 'Save';

  @override
  String get back => 'Back';

  @override
  String get searchTitle => 'Search parking';
  @override
  String get searchByNameHint => 'Search by parking name';
  @override
  String get noFilterResults => 'No results for selected filters.';
  @override
  String get city => 'City';
  @override
  String get allCities => 'All cities';
  @override
  String get availability => 'Availability';
  @override
  String get allAvailability => 'All';
  @override
  String get availableOnly => 'Available';
  @override
  String get viewParking => 'View parking';

  @override
  String get parkingLotsTitle => 'Parking lots';
  @override
  String get details => 'Details';
  @override
  String get distance => 'Distance';
  @override
  String get zonesInLot => 'Zones in this lot';

  @override
  String get profile => 'Profile';
  @override
  String get editProfile => 'Edit profile';
  @override
  String get profileUpdated => 'Profile updated.';
  @override
  String get vehicleAdded => 'Vehicle added successfully.';
  @override
  String get vehicleUpdated => 'Vehicle updated successfully.';
  @override
  String get myVehicles => 'My vehicles';
  @override
  String get myFavorites => 'Favorite parking lots';
  @override
  String get myFavoritesTitle => 'Favorite parking lots';
  @override
  String get noFavorites => 'You have no saved parking lots.';
  @override
  String get addedToFavorites => 'Added to favorites.';
  @override
  String get removedFromFavorites => 'Removed from favorites.';
  @override
  String get viewHistory => 'View history';
  @override
  String get viewHistoryTitle => 'View history';
  @override
  String get noViewHistory => 'You have not viewed any parking lots yet.';
  @override
  String viewCountLabel(int count) => 'Views: $count';
  @override
  String lastViewedLabel(String when) => 'Last viewed: $when';
  @override
  String get notifications => 'Notifications';
  @override
  String get signOut => 'Sign out';

  @override
  String get myReservations => 'My reservations';
  @override
  String get activeReservations => 'Active reservations';
  @override
  String get reservationHistory => 'Reservation history';
  @override
  String get cancelReservation => 'Cancel reservation';
  @override
  String get cancelReservationQuestion => 'Cancel reservation?';
  @override
  String get cancelReservationConfirm => 'Yes, cancel';
  @override
  String get no => 'No';
  @override
  String get yesCancel => 'Yes, cancel';
  @override
  String get reservationCancelled => 'Reservation cancelled.';
  @override
  String get reserved => 'Reserved';
  @override
  String get completed => 'Completed';

  @override
  String get myVehiclesTitle => 'My vehicles';
  @override
  String get addVehicle => 'Add vehicle';
  @override
  String get noVehicles => 'You have no registered vehicles.';
  @override
  String get editVehicle => 'Edit vehicle';
  @override
  String get newVehicle => 'New vehicle';
  @override
  String get brand => 'Brand';
  @override
  String get color => 'Color';
  @override
  String get saveChanges => 'Save changes';
  @override
  String get deleteVehicleQuestion => 'Delete vehicle?';
  @override
  String get deleteVehicleBody => 'This action cannot be undone.';
  @override
  String get delete => 'Delete';

  @override
  String get deleteConfirmTitle => 'Confirm deletion';

  @override
  String get irreversibleActionWarning =>
      'This action is permanent and cannot be undone. Please check the details before continuing.';

  @override
  String deleteConfirmQuestion(String itemName) =>
      'Are you sure you want to delete: $itemName?';

  @override
  String get editProfileTitle => 'Edit profile';
  @override
  String get firstName => 'First name';
  @override
  String get lastName => 'Last name';
  @override
  String get phone => 'Phone';
  @override
  String get changePasswordSection => 'Change password';
  @override
  String get currentPassword => 'Current password';
  @override
  String get newPassword => 'New password';
  @override
  String get confirmNewPassword => 'Confirm new password';
  @override
  String get passwordChanged => 'Password changed.';
  @override
  String get validationPasswordMismatch => 'New password and confirmation do not match.';
  @override
  String get validationCurrentPasswordWrong => 'Current password is incorrect.';
  @override
  String get requiredField => 'Required field';
  @override
  String get notificationsTitle => 'Notifications';

  @override
  String get reserveSpot => 'Reserve';
  @override
  String get selectFreeSpotFirst => 'Select an available spot first.';
  @override
  String get noSpotsToShow => 'No spots to display.';
  @override
  String get reservationTitle => 'Reserve a spot';
  @override
  String get confirmReservation => 'Confirm reservation';
  @override
  String get endAfterStart => 'End time must be after start time.';
  @override
  String get reservationConfirmed => 'Reservation confirmed';
  @override
  String get reservationSubmitted => 'Request submitted';
  @override
  String get reservationSubmittedMessage =>
      'Your reservation was submitted and is awaiting admin approval. You will be notified in your profile.';
  @override
  String get statusPending => 'Pending';
  @override
  String get statusConfirmed => 'Confirmed';
  @override
  String get ok => 'OK';
  @override
  String get vehicle => 'Vehicle';
  @override
  String get date => 'Date';
  @override
  String get startTime => 'Start';
  @override
  String get endTime => 'End';
  @override
  String get reservationType => 'Reservation type';
  @override
  String get confirmReservationQuestion => 'Do you want to confirm this reservation?';
  @override
  String get priceLabel => 'Price';

  @override
  String validationRequired(String fieldName) =>
      'Field "$fieldName" is required — enter a value.';
  @override
  String validationMinLength(String fieldName, int min) =>
      'Field "$fieldName" must be at least $min characters.';
  @override
  String validationMaxLength(String fieldName, int max) =>
      'Field "$fieldName" must be at most $max characters.';
  @override
  String get validationEmail =>
      'Enter a valid email address (e.g. user@example.com).';
  @override
  String get validationPhoneFormat =>
      'Phone: 8–15 digits; +, spaces and hyphens allowed (e.g. +387 61 123 456).';
  @override
  String get validationUsername =>
      'Username is required — at least 3 characters, no spaces.';
  @override
  String get validationUsernameNoSpaces =>
      'Username must not contain spaces (e.g. user1).';
  @override
  String get validationPassword => 'Password is required.';
  @override
  String validationPasswordMin(int min) =>
      'Password must be at least $min characters (letters and/or digits).';
  @override
  String get validationLicensePlate =>
      'License plate is required — enter the vehicle registration.';
  @override
  String get validationLicensePlateFormat =>
      'Plate: 4–12 chars, letters, digits and hyphens (e.g. A12-B-345).';
  @override
  String validationSelect(String fieldName) =>
      'Field "$fieldName" is required — select from the list.';
  @override
  String get validationVehicle =>
      'Vehicle is required — select a registered vehicle from the list.';
  @override
  String get validationReservationType =>
      'Reservation type is required — select a type (e.g. hourly, daily).';
  @override
  String get validationEndAfterStartDetailed =>
      'End time must be after start (later date or time).';
  @override
  String get validationReviewRating =>
      'Rating is required — select 1 to 5 stars.';

  @override
  String get badgeTopPick => 'Top Pick for You ⭐';
  @override
  String get badgeEv => 'Perfect for EV ⚡';
  @override
  String get badgeAffordable => 'Affordable Pick 🏷️';
  @override
  String get badgeCovered => 'Covered parking 🏗️';
  @override
  String get preferredNameSuffix => ' (Preferred)';
  @override
  String get hintTopPickDefault => 'Best match for your preferences';
  @override
  String get hintEv => 'EV charging spots available';
  @override
  String get hintAffordable => 'Lower price range';
  @override
  String get hintCovered => 'Covered / sheltered spaces available';
  @override
  String get hintTopPickWithHistory => 'aligned with your reservations and views';
  @override
  String get noMobileAccess => 'You do not have access to the mobile app.';
}

extension AppStringsContext on BuildContext {
  AppStrings get s => AppStrings.of(LocaleController.instance.locale);
}
