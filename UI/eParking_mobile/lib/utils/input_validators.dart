import '../l10n/app_strings.dart';

/// Eksplicitne poruke validacije za mobilnu aplikaciju (RS2).
class InputValidators {
  static String requiredField(String fieldName, AppStrings s) =>
      s.validationRequired(fieldName);

  static String? text(
    String? value,
    String fieldName,
    AppStrings s, {
    int minLength = 1,
    int? maxLength,
  }) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return requiredField(fieldName, s);
    if (t.length < minLength) return s.validationMinLength(fieldName, minLength);
    if (maxLength != null && t.length > maxLength) {
      return s.validationMaxLength(fieldName, maxLength);
    }
    return null;
  }

  static String? email(String? value, AppStrings s) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return requiredField('Email', s);
    if (!RegExp(r'^[\w\.\-]+@[\w\-]+\.[A-Za-z]{2,}$').hasMatch(t)) {
      return s.validationEmail;
    }
    return null;
  }

  /// Opcionalno polje — ako je popunjeno, mora biti ispravan format.
  static String? phone(String? value, AppStrings s, {bool required = false}) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return required ? requiredField('Telefon', s) : null;
    if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(t)) {
      return s.validationPhoneFormat;
    }
    final digits = t.replaceAll(RegExp(r'\D'), '');
    if (digits.length < 8 || digits.length > 15) {
      return s.validationPhoneFormat;
    }
    return null;
  }

  static String? username(String? value, AppStrings s) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return s.validationUsername;
    if (t.length < 3) return s.validationMinLength(s.username, 3);
    if (t.contains(' ')) return s.validationUsernameNoSpaces;
    return null;
  }

  /// Prijava — samo obavezno polje (ne mijenja pravila servera za postojeće korisnike).
  static String? passwordLogin(String? value, AppStrings s) {
    if (value == null || value.isEmpty) return s.validationPassword;
    return null;
  }

  /// Nova lozinka / registracija — minimalna duljina.
  static String? passwordNew(String? value, AppStrings s, {int minLen = 6}) {
    if (value == null || value.isEmpty) return s.validationPassword;
    if (value.length < minLen) return s.validationPasswordMin(minLen);
    return null;
  }

  static String? passwordConfirm(String? value, String? other, AppStrings s) {
    if (value == null || value.isEmpty) return s.validationPassword;
    if (value != other) return s.validationPasswordMismatch;
    return null;
  }

  /// Ako je bilo koje polje popunjeno, sva tri su obavezna.
  static bool passwordChangeRequested(
    String? current,
    String? newPass,
    String? confirm,
  ) {
    return (current?.isNotEmpty ?? false) ||
        (newPass?.isNotEmpty ?? false) ||
        (confirm?.isNotEmpty ?? false);
  }

  static String? licensePlate(String? value, AppStrings s) {
    final t = value?.trim().toUpperCase() ?? '';
    if (t.isEmpty) return s.validationLicensePlate;
    if (t.length < 4 || t.length > 12) {
      return s.validationLicensePlateFormat;
    }
    if (!RegExp(r'^[A-Z0-9\-]+$').hasMatch(t)) {
      return s.validationLicensePlateFormat;
    }
    return null;
  }

  static String? reviewRating(int? value, AppStrings s) {
    if (value == null || value < 1 || value > 5) return s.validationReviewRating;
    return null;
  }

  /// Komentar je opcionalan; ako je unesen, provjerava se maksimalna duljina.
  static String? reviewComment(String? value, AppStrings s, {int maxLen = 1000}) {
    final t = value ?? '';
    if (t.isEmpty) return null;
    if (t.length > maxLen) return s.validationMaxLength('Komentar', maxLen);
    return null;
  }

  static String? resetCode(String? value, AppStrings s) {
    final t = value?.trim() ?? '';
    if (t.isEmpty) return s.validationResetCodeRequired;
    if (!RegExp(r'^\d{6}$').hasMatch(t)) return s.validationResetCodeFormat;
    return null;
  }

  static String? dropdownInt(int? value, String fieldName, AppStrings s) {
    if (value == null) return s.validationSelect(fieldName);
    return null;
  }
}
