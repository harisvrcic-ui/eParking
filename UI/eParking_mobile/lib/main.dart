import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'l10n/locale_controller.dart';
import 'screens/login_screen.dart';
import 'services/view_history_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await ViewHistoryService.init();
  runApp(
    ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) => const EParkingMobileApp(),
    ),
  );
}

class EParkingMobileApp extends StatelessWidget {
  const EParkingMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    final locale = LocaleController.instance.locale;

    return MaterialApp(
      title: 'eParking',
      locale: locale,
      supportedLocales: const [
        Locale('bs'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF2563EB)),
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.grey.shade100,
      ),
      home: const LoginScreen(),
    );
  }
}
