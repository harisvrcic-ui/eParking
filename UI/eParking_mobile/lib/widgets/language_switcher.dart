import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';

class LanguageSwitcher extends StatelessWidget {
  const LanguageSwitcher({super.key});

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    final code = LocaleController.instance.locale.languageCode;

    return InputDecorator(
      decoration: InputDecoration(
        labelText: s.languageName,
        filled: true,
        fillColor: Colors.white,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: code,
          isExpanded: true,
          items: [
            DropdownMenuItem(value: 'bs', child: Text(s.languageBs)),
            DropdownMenuItem(value: 'en', child: Text(s.languageEn)),
          ],
          onChanged: (v) {
            if (v != null) LocaleController.instance.setLanguageCode(v);
          },
        ),
      ),
    );
  }
}
