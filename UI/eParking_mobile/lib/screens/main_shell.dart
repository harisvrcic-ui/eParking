import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../widgets/dialog_helpers.dart';
import '../models/login_response.dart';
import '../models/user_preferences.dart';
import '../services/auth_service.dart';
import '../services/location_service.dart';
import '../services/preferences_service.dart';
import 'home_page.dart';
import 'profile_page.dart';
import 'reservations_page.dart';
import 'search_page.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key, required this.user});

  final LoginResponse user;

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _index = 0;
  int _prefsVersion = 0;
  UserPreferences _preferences = const UserPreferences();
  bool _prefsReady = false;

  @override
  void initState() {
    super.initState();
    AuthService.currentUser = widget.user;
    _loadPreferences();
    LocationService().requestLocationPermission();
  }

  Future<void> _loadPreferences() async {
    final prefs = await PreferencesService.load();
    if (mounted) {
      setState(() {
        _preferences = prefs;
        _prefsReady = true;
      });
    }
  }

  void _openPreferences() {
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        var prefs = _preferences;
        return ListenableBuilder(
          listenable: LocaleController.instance,
          builder: (context, _) {
            final s = AppStrings.of(LocaleController.instance.locale);
            return StatefulBuilder(
          builder: (context, setModalState) {
            final bottomInset = MediaQuery.viewPaddingOf(ctx).bottom;
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 8, 20, bottomInset + 24),
              child: SingleChildScrollView(
                child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  dialogTitleBar(ctx, s.myPreferences),
                  const SizedBox(height: 16),
                  SwitchListTile(
                    title: Text(s.preferEv),
                    value: prefs.preferEvCharging,
                    onChanged: (v) => setModalState(() => prefs = prefs.copyWith(preferEvCharging: v)),
                  ),
                  SwitchListTile(
                    title: Text(s.preferBudget),
                    value: prefs.preferBudget,
                    onChanged: (v) => setModalState(() => prefs = prefs.copyWith(preferBudget: v)),
                  ),
                  SwitchListTile(
                    title: Text(s.preferNearby),
                    value: prefs.preferNearby,
                    onChanged: (v) => setModalState(() => prefs = prefs.copyWith(preferNearby: v)),
                  ),
                  SwitchListTile(
                    title: Text(s.preferCovered),
                    value: prefs.preferCovered,
                    onChanged: (v) => setModalState(() => prefs = prefs.copyWith(preferCovered: v)),
                  ),
                  const SizedBox(height: 8),
                  Text(s.geographicZone, style: Theme.of(context).textTheme.titleSmall),
                  RadioListTile<GeographicZonePreference>(
                    title: Text(s.allZones),
                    value: GeographicZonePreference.any,
                    groupValue: prefs.zonePreference,
                    onChanged: (v) => setModalState(
                      () => prefs = prefs.copyWith(zonePreference: v ?? GeographicZonePreference.any),
                    ),
                  ),
                  RadioListTile<GeographicZonePreference>(
                    title: Text(s.zone1Centar),
                    value: GeographicZonePreference.zona1Centar,
                    groupValue: prefs.zonePreference,
                    onChanged: (v) => setModalState(
                      () => prefs = prefs.copyWith(zonePreference: v ?? GeographicZonePreference.any),
                    ),
                  ),
                  RadioListTile<GeographicZonePreference>(
                    title: Text(s.zone2Periferija),
                    value: GeographicZonePreference.zona2Periferija,
                    groupValue: prefs.zonePreference,
                    onChanged: (v) => setModalState(
                      () => prefs = prefs.copyWith(zonePreference: v ?? GeographicZonePreference.any),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: () async {
                      setState(() {
                        _preferences = prefs;
                        _prefsVersion++;
                      });
                      await PreferencesService.save(prefs);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    style: FilledButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                    child: Text(s.save),
                  ),
                ],
                ),
              ),
            );
          },
        );
          },
        );
      },
    ).then((_) {
      if (_index == 0) setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_prefsReady) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final pages = [
      HomePage(
        key: ValueKey('home_${_prefsVersion}_${LocaleController.instance.locale.languageCode}'),
        user: widget.user,
        preferences: _preferences,
        onPreferencesTap: _openPreferences,
      ),
      SearchPage(userId: widget.user.id),
      ReservationsPage(userId: widget.user.id),
      ProfilePage(user: widget.user),
    ];

    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final s = context.s;
        return Scaffold(
          backgroundColor: Colors.grey.shade100,
          body: pages[_index],
          bottomNavigationBar: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: (i) => setState(() => _index = i),
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.home_outlined),
                selectedIcon: const Icon(Icons.home),
                label: s.navHome,
              ),
              NavigationDestination(icon: const Icon(Icons.search), label: s.navSearch),
              NavigationDestination(
                icon: const Icon(Icons.event_outlined),
                selectedIcon: const Icon(Icons.event),
                label: s.navReservations,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: s.navProfile,
              ),
            ],
          ),
        );
      },
    );
  }
}

