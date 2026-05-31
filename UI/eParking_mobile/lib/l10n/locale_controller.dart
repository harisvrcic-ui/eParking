import 'package:flutter/material.dart';

/// Trenutni jezik aplikacije (bs / en).
class LocaleController extends ChangeNotifier {
  LocaleController._();
  static final LocaleController instance = LocaleController._();

  Locale _locale = const Locale('bs');

  Locale get locale => _locale;

  bool get isEnglish => _locale.languageCode == 'en';

  void setLocale(Locale locale) {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
  }

  void setLanguageCode(String code) {
    setLocale(Locale(code));
  }
}
