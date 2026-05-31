import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../widgets/generic_crud_page.dart';
import '../../widgets/image_helpers.dart';
import '../../widgets/management_page_layout.dart';
import '../forms/form_helpers.dart';

class UsersPage extends StatelessWidget {
  const UsersPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Users Management',
        subtitle: 'Manage and view all users',
        endpoint: '/MyAppUsers',
        searchHint: 'Search by username, email or name...',
        totalItemLabel: 'Users',
        columnHeaders: const ['Username', 'Full Name', 'Email', 'Role'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['username']?.toString() ?? ''),
            Text('${item['firstName']} ${item['lastName']}'),
            Text(item['email']?.toString() ?? ''),
            Text(item['isAdmin'] == true ? 'Admin' : 'User'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _userForm,
      );

  static Future<void> _userForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final u = TextEditingController(text: item?['username']?.toString() ?? '');
    final p = TextEditingController();
    final pc = TextEditingController();
    var changePassword = item == null;
    final fn = TextEditingController(text: item?['firstName']?.toString() ?? '');
    final ln = TextEditingController(text: item?['lastName']?.toString() ?? '');
    final em = TextEditingController(text: item?['email']?.toString() ?? '');
    final ph = TextEditingController(text: item?['phoneNumber']?.toString() ?? '');
    var isAdmin = item?['isAdmin'] as bool? ?? false;
    var isUser = item?['isUser'] as bool? ?? true;
    var isActive = item?['isActive'] as bool? ?? true;
    final genders = await loadLookup('/Lookups/genders');
    final cities = await loadLookup('/Lookups/cities');
    int? genderId = item?['genderId'] as int?;
    int? cityId = item?['cityId'] as int?;

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add User' : 'Edit User',
      successMessage: item == null
          ? 'Korisnik je uspješno dodan.'
          : 'Podaci korisnika su uspješno ažurirani.',
      fields: [
        usernameField(u, 'Username'),
        StatefulBuilder(
          builder: (context, setS) => Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (item != null)
                compactCheckboxListTile(
                  title: 'Izmijeni lozinku',
                  value: changePassword,
                  onChanged: (v) => setS(() {
                    changePassword = v ?? false;
                    if (!changePassword) {
                      p.clear();
                      pc.clear();
                    }
                  }),
                ),
              if (item == null || changePassword) ...[
                passwordField(
                  p,
                  item == null ? 'Lozinka' : 'Nova lozinka',
                  required: item == null || changePassword,
                ),
                passwordConfirmField(
                  p,
                  pc,
                  'Potvrda lozinke',
                  required: item == null || changePassword,
                ),
              ],
            ],
          ),
        ),
        textField(fn, 'First name'),
        textField(ln, 'Last name'),
        emailField(em, 'Email'),
        phoneField(ph, 'Phone number'),
        if (genders.isNotEmpty)
          StatefulBuilder(
            builder: (c, s) => optionalIntDropdown(
              label: 'Gender',
              value: genderId,
              items: genders
                  .map((g) => DropdownMenuItem(
                        value: g['id'] as int,
                        child: Text(g['name'].toString()),
                      ))
                  .toList(),
              onChanged: (v) => s(() => genderId = v),
            ),
          ),
        if (cities.isNotEmpty)
          StatefulBuilder(
            builder: (c, s) => optionalIntDropdown(
              label: 'City',
              value: cityId,
              items: cities
                  .map((ci) => DropdownMenuItem(
                        value: ci['id'] as int,
                        child: Text(ci['name'].toString()),
                      ))
                  .toList(),
              onChanged: (v) => s(() => cityId = v),
            ),
          ),
        StatefulBuilder(builder: (c, s) => Column(children: [
              compactCheckboxListTile(title: 'Admin', value: isAdmin, onChanged: (v) => s(() => isAdmin = v ?? false)),
              compactCheckboxListTile(title: 'User', value: isUser, onChanged: (v) => s(() => isUser = v ?? true)),
              compactCheckboxListTile(title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true)),
            ])),
      ],
      onSave: () async {
        final body = {
          'username': u.text.trim(),
          'firstName': fn.text.trim(),
          'lastName': ln.text.trim(),
          'email': em.text.trim(),
          'phoneNumber': ph.text.trim().isEmpty ? null : ph.text.trim(),
          'genderId': genderId,
          'cityId': cityId,
          'isAdmin': isAdmin,
          'isUser': isUser,
          'isActive': isActive,
          if (p.text.isNotEmpty) 'password': p.text,
        };
        if (item == null) await api.post('/MyAppUsers', body);
        else await api.put('/MyAppUsers', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class ParkingSpotsPage extends StatelessWidget {
  const ParkingSpotsPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Parking Spots Management',
        subtitle: 'Manage and view all parking spots',
        endpoint: '/ParkingSpots',
        searchHint: 'Search by spot number...',
        totalItemLabel: 'Parking Spots',
        columnHeaders: const ['Number', 'Zone', 'Type', 'Lot', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['parkingNumber']?.toString() ?? ''),
            Text(item['zoneName']?.toString() ?? ''),
            Text(item['parkingSpotTypeName']?.toString() ?? ''),
            Text(item['parkingLotName']?.toString() ?? ''),
            statusBadge(item['isActive'] == true ? 'Active' : 'Inactive'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _spotForm,
      );

  static Future<void> _spotForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final zones = await loadLookup('/ParkingZones');
    final types = await loadLookup('/Lookups/parking-spot-types');
    if (item == null &&
        !guardInsertPrerequisites(ctx, {'Zone': zones, 'Tip mjesta': types})) {
      return;
    }
    final numC = TextEditingController(text: item?['parkingNumber']?.toString() ?? '');
    int? zoneId = item?['zoneId'] as int? ?? (zones.isNotEmpty ? zones.first['id'] as int : null);
    int? typeId = item?['parkingSpotTypeId'] as int? ?? (types.isNotEmpty ? types.first['id'] as int : null);
    var isActive = item?['isActive'] as bool? ?? true;

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Parking Spot' : 'Edit Parking Spot',
      successMessage: item == null
          ? 'Parking mjesto je uspješno dodano.'
          : 'Parking mjesto je uspješno ažurirano.',
      fields: [
        integerField(numC, 'Parking number', min: 1, helperText: 'Jedinstveni broj mjesta u zoni.'),
        StatefulBuilder(
          builder: (c, s) => Column(
            children: [
              requiredIntDropdown(
                label: 'Zone',
                value: zoneId,
                items: zones
                    .map((z) => DropdownMenuItem(value: z['id'] as int, child: Text(z['name'].toString())))
                    .toList(),
                onChanged: (v) => s(() => zoneId = v),
              ),
              requiredIntDropdown(
                label: 'Spot type',
                value: typeId,
                items: types
                    .map((t) => DropdownMenuItem(value: t['id'] as int, child: Text(t['name'].toString())))
                    .toList(),
                onChanged: (v) => s(() => typeId = v),
              ),
            ],
          ),
        ),
        StatefulBuilder(builder: (c, s) => compactCheckboxListTile(
              title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true))),
      ],
      onSave: () async {
        final body = {
          'parkingNumber': int.parse(numC.text.trim()),
          'zoneId': zoneId,
          'parkingSpotTypeId': typeId,
          'isActive': isActive,
        };
        if (item == null) await api.post('/ParkingSpots', body);
        else await api.put('/ParkingSpots', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class ParkingZonesPage extends StatelessWidget {
  const ParkingZonesPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Parking zone',
        subtitle: 'Samo 2 gradske zone: Zona 1 (centar), Zona 2 (periferija)',
        endpoint: '/ParkingZones',
        queryParams: const {'isActive': 'true'},
        searchHint: 'Search by zone name...',
        totalItemLabel: 'Aktivne zone',
        columnHeaders: const ['Name', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w500)),
            statusBadge(item['isActive'] == true ? 'Active' : 'Inactive'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _zoneForm,
      );

  static Future<void> _zoneForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final lots = await loadLookup('/ParkingLots');
    if (item == null && !guardInsertPrerequisites(ctx, {'Parking': lots})) return;
    final nameC = TextEditingController(text: item?['name']?.toString() ?? '');
    final descC = TextEditingController(text: item?['description']?.toString() ?? '');
    int? lotId = item?['parkingLotId'] as int? ?? (lots.isNotEmpty ? lots.first['id'] as int : null);
    var isActive = item?['isActive'] as bool? ?? true;

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Zone' : 'Edit Zone',
      successMessage: item == null
          ? 'Parking zona je uspješno dodana.'
          : 'Parking zona je uspješno ažurirana.',
      fields: [
        textField(nameC, 'Zone name'),
        textField(descC, 'Opis (npr. centar / periferija)', required: false, maxLines: 3),
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Parking lot',
            value: lotId,
            items: lots
                .map((l) => DropdownMenuItem(value: l['id'] as int, child: Text(l['name'].toString())))
                .toList(),
            onChanged: (v) => s(() => lotId = v),
          ),
        ),
        StatefulBuilder(builder: (c, s) => compactCheckboxListTile(
              title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true))),
      ],
      onSave: () async {
        final body = {
          'name': nameC.text.trim(),
          'description': descC.text.trim().isEmpty ? null : descC.text.trim(),
          'parkingLotId': lotId,
          'isActive': isActive,
        };
        if (item == null) await api.post('/ParkingZones', body);
        else await api.put('/ParkingZones', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class ParkingSpotTypesPage extends StatelessWidget {
  const ParkingSpotTypesPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Parking Spot Types Management',
        subtitle: 'Manage spot types and price multipliers',
        endpoint: '/ParkingSpotTypes',
        searchHint: 'Search by name...',
        totalItemLabel: 'Spot Types',
        columnHeaders: const ['Name', 'Description', 'Multiplier'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? ''),
            Text(item['description']?.toString() ?? ''),
            Text('${item['priceMultiplier']}'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _typeForm,
      );

  static Future<void> _typeForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    final d = TextEditingController(text: item?['description']?.toString() ?? '');
    final m = TextEditingController(text: '${item?['priceMultiplier'] ?? 1}');

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Spot Type' : 'Edit Spot Type',
      successMessage: item == null
          ? 'Tip parking mjesta je uspješno dodan.'
          : 'Tip parking mjesta je uspješno ažuriran.',
      fields: [
        textField(n, 'Name'),
        textField(d, 'Description', required: false),
        numberField(m, 'Price multiplier', min: 0.1, max: 10, helperText: 'Množitelj cijene (npr. 1.0 = standard).'),
      ],
      onSave: () async {
        final body = {'name': n.text.trim(), 'description': d.text.trim(), 'priceMultiplier': double.parse(m.text)};
        if (item == null) await api.post('/ParkingSpotTypes', body);
        else await api.put('/ParkingSpotTypes', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class ReservationsPage extends StatelessWidget {
  const ReservationsPage({super.key});
  @override
  Widget build(BuildContext context) => Builder(
        builder: (pageContext) => GenericCrudPage(
        title: 'Reservations Management',
        subtitle: 'Manage and view all reservations',
        endpoint: '/Reservations',
        cancelInsteadOfDelete: true,
        searchHint: 'Search by user or plate...',
        totalItemLabel: 'Reservations',
        columnHeaders: const ['User', 'Spot', 'From', 'To', 'Price', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) {
          final status = item['status']?.toString() ?? '';
          final isPending = status == 'Pending';
          final canModify = status == 'Pending' || status == 'Confirmed';
          return ManagementRow(
            cells: [
              Text(item['userFullName']?.toString() ?? ''),
              Text(item['parkingSpotDisplayName']?.toString() ?? ''),
              Text(_fmtDate(item['startDate'])),
              Text(_fmtDate(item['endDate'])),
              Text('${item['finalPrice']} KM'),
              _statusChip(status),
            ],
            extraActions: isPending
                ? [
                    _reservationActionIcon(
                      icon: Icons.check_circle_outline,
                      tooltip: 'Potvrdi',
                      color: AppColors.activeGreen,
                      onTap: () => _confirmReservation(pageContext, item, reload),
                    ),
                    _reservationActionIcon(
                      icon: Icons.cancel_outlined,
                      tooltip: 'Odbij',
                      color: Colors.red.shade700,
                      onTap: () => _rejectReservation(pageContext, item, reload),
                    ),
                  ]
                : const [],
            onEdit: canModify ? onEdit : null,
            onDelete: canModify ? onDelete : null,
          );
        },
        showForm: _resForm,
      ),
      );

  static Widget _statusChip(String status) {
    final (label, color, bg) = switch (status) {
      'Pending' => ('Na čekanju', Colors.orange.shade800, Colors.orange.shade50),
      'Confirmed' => ('Potvrđeno', AppColors.activeGreen, AppColors.activeGreenBg),
      'Cancelled' => ('Otkazano', Colors.red.shade700, Colors.red.shade50),
      'Completed' => ('Završeno', Colors.blue.shade800, Colors.blue.shade50),
      _ => (status, Colors.grey.shade700, Colors.grey.shade100),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 12),
      ),
    );
  }

  static Widget _reservationActionIcon({
    required IconData icon,
    required String tooltip,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(6),
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              border: Border.all(color: color.withValues(alpha: 0.4)),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
        ),
      ),
    );
  }

  static Future<void> _confirmReservation(
    BuildContext ctx,
    Map<String, dynamic> item,
    ListReload reload,
  ) async {
    final id = item['id'] as int;
    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: dialogTitleBar(dialogCtx, 'Potvrdi rezervaciju'),
        content: Text(
          'Potvrditi rezervaciju #${item['id']} za ${item['userFullName']}?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Odustani')),
          FilledButton(onPressed: () => Navigator.pop(dialogCtx, true), child: const Text('Potvrdi')),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiClient().post('/Reservations/$id/confirm', {});
      await reload();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Rezervacija je potvrđena.')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  static Future<void> _rejectReservation(
    BuildContext ctx,
    Map<String, dynamic> item,
    ListReload reload,
  ) async {
    final id = item['id'] as int;
    final reason = TextEditingController();
    final formKey = GlobalKey<FormState>();

    final ok = await showDialog<bool>(
      context: ctx,
      builder: (dialogCtx) => AlertDialog(
        title: dialogTitleBar(dialogCtx, 'Odbij rezervaciju'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text('Rezervacija #${item['id']} — ${item['userFullName']}'),
              const SizedBox(height: 12),
              TextFormField(
                controller: reason,
                decoration: const InputDecoration(
                  labelText: 'Razlog odbijanja',
                  helperText: 'Obavezno — korisnik prima notifikaciju s razlogom',
                ),
                maxLines: 3,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) {
                    return ValidationMsgs.required('Razlog odbijanja');
                  }
                  return null;
                },
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogCtx, false), child: const Text('Odustani')),
          FilledButton(
            onPressed: () {
              if (!formKey.currentState!.validate()) return;
              Navigator.pop(dialogCtx, true);
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red.shade700),
            child: const Text('Odbij'),
          ),
        ],
      ),
    );
    if (ok != true) return;

    try {
      await ApiClient().post('/Reservations/$id/reject', {'reason': reason.text.trim()});
      await reload();
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          const SnackBar(content: Text('Rezervacija je odbijena.')),
        );
      }
    } catch (e) {
      if (ctx.mounted) {
        ScaffoldMessenger.of(ctx).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      reason.dispose();
    }
  }

  static String _fmtDate(dynamic d) {
    if (d == null) return '';
    return DateTime.parse(d.toString()).toString().substring(0, 16);
  }

  static Future<void> _resForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final cars = await loadLookup('/Cars');
    final spots = await loadLookup('/ParkingSpots');
    final types = await loadLookup('/Lookups/reservation-types');
    if (item == null &&
        !guardInsertPrerequisites(ctx, {
          'Vozilo': cars,
          'Parking mjesto': spots,
          'Tip rezervacije': types,
        })) {
      return;
    }
    int? carId = item?['carId'] as int? ?? (cars.isNotEmpty ? cars.first['id'] as int : null);
    int? spotId = item?['parkingSpotId'] as int? ?? (spots.isNotEmpty ? spots.first['id'] as int : null);
    int? typeId = item?['reservationTypeId'] as int? ?? (types.isNotEmpty ? types.first['id'] as int : null);
    DateTime start = item != null ? DateTime.parse(item['startDate'].toString()) : DateTime.now();
    DateTime end = item != null ? DateTime.parse(item['endDate'].toString()) : DateTime.now().add(const Duration(hours: 2));

    final formKey = GlobalKey<FormState>();

    await showDialog(
      context: ctx,
      barrierDismissible: true,
      builder: (dialogCtx) => StatefulBuilder(
        builder: (context, setS) => AlertDialog(
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          title: dialogTitleBar(
            dialogCtx,
            item == null ? 'Add Reservation' : 'Edit Reservation',
          ),
          content: Form(
            key: formKey,
            autovalidateMode: AutovalidateMode.disabled,
            child: formDialogScrollableContent(
              context: context,
              width: 450,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                    requiredIntDropdown(
                      label: 'Car',
                      value: carId,
                      items: cars
                          .map((x) => DropdownMenuItem(
                                value: x['id'] as int,
                                child: Text(x['licensePlate'].toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => carId = v),
                    ),
                    requiredIntDropdown(
                      label: 'Parking spot',
                      value: spotId,
                      items: spots
                          .map((x) => DropdownMenuItem(
                                value: x['id'] as int,
                                child: Text(x['displayName']?.toString() ?? x['parkingNumber'].toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => spotId = v),
                    ),
                    requiredIntDropdown(
                      label: 'Reservation type',
                      value: typeId,
                      items: types
                          .map((x) => DropdownMenuItem(
                                value: x['id'] as int,
                                child: Text(x['name'].toString()),
                              ))
                          .toList(),
                      onChanged: (v) => setS(() => typeId = v),
                    ),
                    formDateTimeField(
                      label: 'Start',
                      value: start,
                      helperText: 'Obavezno — odaberite datum i vrijeme početka',
                      onTap: () => pickDateAndTime(
                        context,
                        initial: start,
                        onChanged: (v) => setS(() => start = v),
                      ),
                    ),
                    FormField<void>(
                      validator: (_) {
                        if (!end.isAfter(start)) return ValidationMsgs.endAfterStart;
                        return null;
                      },
                      builder: (state) {
                        final theme = Theme.of(context);
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            formDateTimeField(
                              label: 'End',
                              value: end,
                              helperText: 'Obavezno — mora biti poslije početka',
                              onTap: () => pickDateAndTime(
                                context,
                                initial: end,
                                onChanged: (v) {
                                  setS(() => end = v);
                                  state.didChange(null);
                                },
                              ),
                            ),
                            if (state.hasError)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Text(
                                  state.errorText!,
                                  style: TextStyle(
                                    color: theme.colorScheme.error,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                          ],
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(dialogCtx), child: const Text('Odustani')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                try {
                  final body = {
                    'carId': carId,
                    'parkingSpotId': spotId,
                    'reservationTypeId': typeId,
                    'startDate': start.toIso8601String(),
                    'endDate': end.toIso8601String(),
                  };
                  if (item == null) {
                    await api.post('/Reservations', body);
                  } else {
                    await api.put('/Reservations', item['id'] as int, {...body, 'id': item['id']});
                  }
                  await reload();
                  formKey.currentState?.reset();
                  if (dialogCtx.mounted) {
                    Navigator.pop(dialogCtx);
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      SnackBar(
                        content: Text(item == null
                            ? 'Rezervacija je kreirana i ceka potvrdu administratora.'
                            : 'Rezervacija je uspješno sačuvana.'),
                      ),
                    );
                  }
                } catch (e) {
                  if (dialogCtx.mounted) {
                    ScaffoldMessenger.of(dialogCtx).showSnackBar(
                      SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                    );
                  }
                }
              },
              child: const Text('Sačuvaj'),
            ),
          ],
        ),
      ),
    );
  }
}

class ReservationTypesPage extends StatelessWidget {
  const ReservationTypesPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Reservation Types Management',
        subtitle: 'Manage reservation types and pricing',
        endpoint: '/ReservationTypes',
        searchHint: 'Search by name...',
        totalItemLabel: 'Reservation Types',
        columnHeaders: const ['Name', 'Price'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [Text(item['name']?.toString() ?? ''), Text('${item['price']} KM')],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _rtForm,
      );

  static Future<void> _rtForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    final p = TextEditingController(text: '${item?['price'] ?? 0}');
    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Reservation Type' : 'Edit Reservation Type',
      successMessage: item == null
          ? 'Tip rezervacije je uspješno dodan.'
          : 'Tip rezervacije je uspješno ažuriran.',
      fields: [
        textField(n, 'Name'),
        numberField(p, 'Price', min: 0, max: 9999, helperText: 'Cijena u KM (npr. 2.50).'),
      ],
      onSave: () async {
        final body = {'name': n.text.trim(), 'price': double.parse(p.text)};
        if (item == null) await api.post('/ReservationTypes', body);
        else await api.put('/ReservationTypes', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class BrandsPage extends StatelessWidget {
  const BrandsPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Vehicle Brands Management',
        subtitle: 'Manage vehicle brands',
        endpoint: '/Brands',
        searchHint: 'Search by brand name...',
        totalItemLabel: 'Brands',
        columnHeaders: const ['Name', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? ''),
            statusBadge(item['isActive'] == true ? 'Active' : 'Inactive'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _brandForm,
      );

  static Future<void> _brandForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    var isActive = item?['isActive'] as bool? ?? true;
    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Brand' : 'Edit Brand',
      successMessage: item == null
          ? 'Marka vozila je uspješno dodana.'
          : 'Marka vozila je uspješno ažurirana.',
      fields: [
        textField(n, 'Name'),
        StatefulBuilder(builder: (c, s) => compactCheckboxListTile(
              title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true))),
      ],
      onSave: () async {
        final body = {'name': n.text.trim(), 'isActive': isActive};
        if (item == null) await api.post('/Brands', body);
        else await api.put('/Brands', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class ColorsPage extends StatelessWidget {
  const ColorsPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Vehicle Colors Management',
        subtitle: 'Manage vehicle colors',
        endpoint: '/Colors',
        searchHint: 'Search by color name...',
        totalItemLabel: 'Colors',
        columnHeaders: const ['Name', 'Boja'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? ''),
            Row(
              children: [
                colorSwatch(item['hexCode']?.toString()),
                const SizedBox(width: 8),
                Text(item['hexCode']?.toString() ?? '-'),
              ],
            ),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _colorForm,
      );

  static Future<void> _colorForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    final h = TextEditingController(text: item?['hexCode']?.toString() ?? '');
    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Color' : 'Edit Color',
      successMessage: item == null
          ? 'Boja je uspješno dodana.'
          : 'Boja je uspješno ažurirana.',
      fields: [textField(n, 'Name'), hexColorField(h, 'Hex code')],
      onSave: () async {
        final body = {'name': n.text.trim(), 'hexCode': h.text.trim().isEmpty ? null : h.text.trim()};
        if (item == null) await api.post('/Colors', body);
        else await api.put('/Colors', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class CitiesPage extends StatelessWidget {
  const CitiesPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Cities Management',
        subtitle: 'Manage cities',
        endpoint: '/Cities',
        searchHint: 'Search by city name...',
        totalItemLabel: 'Cities',
        columnHeaders: const ['Name', 'Country', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? ''),
            Text(item['countryName']?.toString() ?? '-'),
            statusBadge(item['isActive'] == true ? 'Active' : 'Inactive'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _cityForm,
      );

  static Future<void> _cityForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final countries = await loadLookup('/Lookups/countries');
    if (item == null && !guardInsertPrerequisites(ctx, {'Država': countries})) return;
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    int? countryId = item?['countryId'] as int? ?? (countries.isNotEmpty ? countries.first['id'] as int : null);
    var isActive = item?['isActive'] as bool? ?? true;
    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add City' : 'Edit City',
      successMessage: item == null
          ? 'Grad je uspješno dodan.'
          : 'Grad je uspješno ažuriran.',
      fields: [
        textField(n, 'Name'),
        StatefulBuilder(
          builder: (c, s) => lookupDropdownWithQuickAdd(
            label: 'Country',
            value: countryId,
            items: countries,
            labelBuilder: (co) => co['name'].toString(),
            onChanged: (v) => s(() => countryId = v),
            onAdd: () async {
              final created = await _quickAddCountry(c);
              if (created != null) {
                countries.add(created);
                s(() => countryId = created['id'] as int);
              }
            },
          ),
        ),
        StatefulBuilder(builder: (ctx2, s) => compactCheckboxListTile(
              title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true))),
      ],
      onSave: () async {
        final body = {
          'name': n.text.trim(),
          'countryId': countryId,
          'isActive': isActive,
        };
        if (item == null) await api.post('/Cities', body);
        else await api.put('/Cities', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }

  static Future<Map<String, dynamic>?> _quickAddCountry(BuildContext ctx) async {
    final api = ApiClient();
    final nameC = TextEditingController();
    Map<String, dynamic>? result;

    await showCrudDialog(
      context: ctx,
      title: 'Nova država',
      successMessage: 'Država je dodana.',
      fields: [textField(nameC, 'Naziv države')],
      onSave: () async {
        result = await api.post('/Countries', {'name': nameC.text.trim(), 'isActive': true});
      },
    );
    return result;
  }
}

Future<List<Map<String, dynamic>>> _loadUsers() async {
  final data = await ApiClient().getList('/MyAppUsers');
  return data.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> _loadParkingLots() async {
  final data = await ApiClient().getList('/ParkingLots');
  return data.cast<Map<String, dynamic>>();
}

Future<List<Map<String, dynamic>>> _loadReservations() async {
  final data = await ApiClient().getList('/Reservations');
  return data.cast<Map<String, dynamic>>();
}

class ParkingLotViewHistoriesPage extends StatelessWidget {
  const ParkingLotViewHistoriesPage({super.key});

  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Historija pregleda',
        subtitle: 'Broj pregleda parkirališta po korisniku (recommender signal)',
        endpoint: '/ParkingLotViewHistories',
        searchHint: 'Pretraži po korisniku ili parkingu...',
        totalItemLabel: 'Zapisi',
        columnHeaders: const ['Korisnik', 'Parking', 'Broj pregleda', 'Zadnji pregled'],
        filter: (item, q) {
          final user = item['userFullName']?.toString().toLowerCase() ?? '';
          final lot = item['parkingLotName']?.toString().toLowerCase() ?? '';
          return user.contains(q) || lot.contains(q);
        },
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['userFullName']?.toString() ?? item['username']?.toString() ?? '—'),
            Text(item['parkingLotName']?.toString() ?? ''),
            Text('${item['viewCount']}'),
            Text(FavoriteParkingLotsPage.formatDate(item['lastViewedAt'])),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _viewHistoryForm,
      );

  static Future<void> _viewHistoryForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final users = await _loadUsers();
    final lots = await _loadParkingLots();
    if (item == null &&
        !guardInsertPrerequisites(ctx, {'Korisnik': users, 'Parking': lots})) {
      return;
    }
    int? userId = item?['userId'] as int? ?? (users.isNotEmpty ? users.first['id'] as int : null);
    int? lotId = item?['parkingLotId'] as int? ?? (lots.isNotEmpty ? lots.first['id'] as int : null);
    final count = TextEditingController(text: '${item?['viewCount'] ?? 1}');

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Dodaj historiju' : 'Uredi historiju',
      successMessage: item == null
          ? 'Historija pregleda je uspješno dodana.'
          : 'Historija pregleda je uspješno ažurirana.',
      fields: [
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Korisnik',
            value: userId,
            items: users
                .map((u) => DropdownMenuItem(
                      value: u['id'] as int,
                      child: Text(userDropdownLabel(u)),
                    ))
                .toList(),
            onChanged: (v) => s(() => userId = v),
          ),
        ),
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Parking',
            value: lotId,
            items: lots
                .map((l) => DropdownMenuItem(
                      value: l['id'] as int,
                      child: Text(l['name']?.toString() ?? 'Parking'),
                    ))
                .toList(),
            onChanged: (v) => s(() => lotId = v),
          ),
        ),
        numberField(count, 'Broj pregleda', min: 1, max: 99999),
      ],
      onSave: () async {
        final payload = {
          'userId': userId,
          'parkingLotId': lotId,
          'viewCount': int.parse(count.text),
        };
        if (item == null) {
          await api.post('/ParkingLotViewHistories', payload);
        } else {
          await api.put('/ParkingLotViewHistories', item['id'] as int, {...payload, 'id': item['id']});
        }
        await reload();
      },
    );
  }
}

class FavoriteParkingLotsPage extends StatelessWidget {
  const FavoriteParkingLotsPage({super.key});

  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Omiljeni parkinzi',
        subtitle: 'Korisnički omiljeni parkinzi',
        endpoint: '/FavoriteParkingLots',
        searchHint: 'Pretraži po parkingu ili korisniku...',
        totalItemLabel: 'Omiljeni',
        columnHeaders: const ['Korisnik', 'Parking', 'Dodano'],
        filter: (item, q) {
          final lot = item['parkingLotName']?.toString().toLowerCase() ?? '';
          final user = item['userFullName']?.toString().toLowerCase() ??
              item['username']?.toString().toLowerCase() ??
              '';
          return lot.contains(q) || user.contains(q);
        },
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['userFullName']?.toString() ?? item['username']?.toString() ?? '—'),
            Text(item['parkingLotName']?.toString() ?? ''),
            Text(formatDate(item['createdAt'])),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _favoriteForm,
      );

  static String formatDate(dynamic v) {
    if (v == null) return '-';
    final s = v.toString();
    return s.length >= 10 ? s.substring(0, 10) : s;
  }

  static Future<void> _favoriteForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final users = await _loadUsers();
    final lots = await _loadParkingLots();
    if (item == null &&
        !guardInsertPrerequisites(ctx, {'Korisnik': users, 'Parking': lots})) {
      return;
    }
    int? userId = item?['userId'] as int? ?? (users.isNotEmpty ? users.first['id'] as int : null);
    int? lotId = item?['parkingLotId'] as int? ?? (lots.isNotEmpty ? lots.first['id'] as int : null);

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Dodaj omiljeni' : 'Uredi omiljeni',
      successMessage: item == null
          ? 'Omiljeni parking je uspješno dodan.'
          : 'Omiljeni parking je uspješno ažuriran.',
      fields: [
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Korisnik',
            value: userId,
            items: users
                .map((u) => DropdownMenuItem(
                      value: u['id'] as int,
                      child: Text(userDropdownLabel(u)),
                    ))
                .toList(),
            onChanged: (v) => s(() => userId = v),
          ),
        ),
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Parking',
            value: lotId,
            items: lots
                .map((l) => DropdownMenuItem(
                      value: l['id'] as int,
                      child: Text(l['name']?.toString() ?? 'Parking'),
                    ))
                .toList(),
            onChanged: (v) => s(() => lotId = v),
          ),
        ),
      ],
      onSave: () async {
        final body = {'userId': userId, 'parkingLotId': lotId};
        if (item == null) {
          await api.post('/FavoriteParkingLots', body);
        } else {
          await api.put('/FavoriteParkingLots', item['id'] as int, {...body, 'id': item['id']});
        }
        await reload();
      },
    );
  }
}

class UserNotificationsPage extends StatelessWidget {
  const UserNotificationsPage({super.key});

  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Obavještenja',
        subtitle: 'Korisnička obavještenja',
        endpoint: '/UserNotifications',
        searchHint: 'Pretraži po naslovu ili tekstu...',
        totalItemLabel: 'Obavještenja',
        columnHeaders: const ['Korisnik', 'Naslov', 'Pročitano', 'Datum'],
        filter: (item, q) {
          final title = item['title']?.toString().toLowerCase() ?? '';
          final body = item['body']?.toString().toLowerCase() ?? '';
          return title.contains(q) || body.contains(q);
        },
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['userFullName']?.toString() ?? item['username']?.toString() ?? '—'),
            Text(item['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
            statusBadge(item['isRead'] == true ? 'Da' : 'Ne'),
            Text(FavoriteParkingLotsPage.formatDate(item['createdAt'])),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _notificationForm,
      );

  static Future<void> _notificationForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final users = await _loadUsers();
    final reservations = await _loadReservations();
    if (item == null && !guardInsertPrerequisites(ctx, {'Korisnik': users})) return;
    final title = TextEditingController(text: item?['title']?.toString() ?? '');
    final body = TextEditingController(text: item?['body']?.toString() ?? '');
    int? userId = item?['userId'] as int? ?? (users.isNotEmpty ? users.first['id'] as int : null);
    int? reservationId = item?['reservationId'] as int?;
    var isRead = item?['isRead'] as bool? ?? false;

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Dodaj obavještenje' : 'Uredi obavještenje',
      successMessage: item == null
          ? 'Obavještenje je uspješno dodano.'
          : 'Obavještenje je uspješno ažurirano.',
      fields: [
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Korisnik',
            value: userId,
            items: users
                .map((u) => DropdownMenuItem(
                      value: u['id'] as int,
                      child: Text(userDropdownLabel(u)),
                    ))
                .toList(),
            onChanged: (v) => s(() => userId = v),
          ),
        ),
        if (reservations.isNotEmpty)
          StatefulBuilder(
            builder: (c, s) => optionalIntDropdown(
              label: 'Rezervacija (opcionalno)',
              value: reservationId,
              items: reservations
                  .map(
                    (r) => DropdownMenuItem(
                      value: r['id'] as int,
                      child: Text(reservationDropdownLabel(r)),
                    ),
                  )
                  .toList(),
              onChanged: (v) => s(() => reservationId = v),
            ),
          ),
        textField(title, 'Naslov'),
        textField(body, 'Tekst', maxLines: 3),
        StatefulBuilder(
          builder: (c, s) => compactCheckboxListTile(
            title: 'Pročitano',
            value: isRead,
            onChanged: (v) => s(() => isRead = v ?? false),
          ),
        ),
      ],
      onSave: () async {
        final payload = {
          'userId': userId,
          'reservationId': reservationId,
          'title': title.text.trim(),
          'body': body.text.trim(),
          'isRead': isRead,
        };
        if (item == null) {
          await api.post('/UserNotifications', payload);
        } else {
          await api.put('/UserNotifications', item['id'] as int, {...payload, 'id': item['id']});
        }
        await reload();
      },
    );
  }
}

class NewsPage extends StatelessWidget {
  const NewsPage({super.key});

  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Obavijesti (News)',
        subtitle: 'Upravljanje obavijestima za mobilnu aplikaciju',
        endpoint: '/News',
        searchHint: 'Pretraži po naslovu ili tekstu...',
        totalItemLabel: 'Obavijesti',
        columnHeaders: const ['Naslov', 'Datum', 'Status'],
        filter: (item, q) {
          final title = item['title']?.toString().toLowerCase() ?? '';
          final body = item['body']?.toString().toLowerCase() ?? '';
          return title.contains(q) || body.contains(q);
        },
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['title']?.toString() ?? '', overflow: TextOverflow.ellipsis),
            Text(FavoriteParkingLotsPage.formatDate(item['createdAt'])),
            statusBadge(item['isActive'] == true ? 'Aktivno' : 'Neaktivno'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _newsForm,
      );

  static Future<void> _newsForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    Map<String, dynamic>? newsItem = item;
    if (item != null) {
      newsItem = await api.getById('/News', item['id'] as int);
    }
    final title = TextEditingController(text: newsItem?['title']?.toString() ?? '');
    final body = TextEditingController(text: newsItem?['body']?.toString() ?? '');
    var isActive = newsItem?['isActive'] as bool? ?? true;
    String? imageBase64 = newsItem?['image']?.toString();

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Nova obavijest' : 'Uredi obavijest',
      successMessage: item == null
          ? 'Obavijest je uspješno dodana.'
          : 'Obavijest je uspješno ažurirana.',
      fields: [
        textField(title, 'Naslov'),
        Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: TextField(
            controller: body,
            maxLines: 4,
            decoration: const InputDecoration(
              labelText: 'Tekst',
              border: OutlineInputBorder(),
            ),
          ),
        ),
        StatefulBuilder(
          builder: (context, setLocal) => formImagePreview(
            pictureBase64: imageBase64,
            onPick: () async {
              final picked = await pickImageBase64();
              if (picked != null) setLocal(() => imageBase64 = picked);
            },
            onClear: imageBase64 == null ? null : () => setLocal(() => imageBase64 = null),
          ),
        ),
        StatefulBuilder(
          builder: (c, s) => compactCheckboxListTile(
            title: 'Aktivno',
            value: isActive,
            onChanged: (v) => s(() => isActive = v ?? true),
          ),
        ),
      ],
      onSave: () async {
        final payload = {
          'title': title.text.trim(),
          'body': body.text.trim(),
          'isActive': isActive,
          if (imageBase64 != null && imageBase64!.isNotEmpty) 'image': imageBase64,
        };
        if (item == null) {
          if (imageBase64 == null || imageBase64!.isEmpty) {
            throw Exception('Slika obavijesti je obavezna.');
          }
          await api.post('/News', payload);
        } else {
          await api.put('/News', item['id'] as int, {...payload, 'id': item['id']});
        }
        await reload();
      },
    );
  }
}

class ReviewsPage extends StatelessWidget {
  const ReviewsPage({super.key});

  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Recenzije',
        subtitle: 'Recenzije parkirališta',
        endpoint: '/Reviews',
        searchHint: 'Pretraži po korisniku, parkingu ili komentaru...',
        totalItemLabel: 'Recenzije',
        columnHeaders: const ['Korisnik', 'Parking', 'Ocjena', 'Komentar'],
        filter: (item, q) {
          final user = item['userFullName']?.toString().toLowerCase() ?? '';
          final lot = item['parkingLotName']?.toString().toLowerCase() ?? '';
          final comment = item['comment']?.toString().toLowerCase() ?? '';
          return user.contains(q) || lot.contains(q) || comment.contains(q);
        },
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['userFullName']?.toString() ?? item['username']?.toString() ?? '—'),
            Text(item['parkingLotName']?.toString() ?? ''),
            Text('${item['rating']}/5'),
            Text(item['comment']?.toString() ?? '-', overflow: TextOverflow.ellipsis),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _reviewForm,
      );

  static Future<void> _reviewForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final users = await _loadUsers();
    final lots = await _loadParkingLots();
    if (item == null &&
        !guardInsertPrerequisites(ctx, {'Korisnik': users, 'Parking': lots})) {
      return;
    }
    final comment = TextEditingController(text: item?['comment']?.toString() ?? '');
    int? userId = item?['userId'] as int? ?? (users.isNotEmpty ? users.first['id'] as int : null);
    int? lotId = item?['parkingLotId'] as int? ?? (lots.isNotEmpty ? lots.first['id'] as int : null);
    int rating = item?['rating'] as int? ?? 5;

    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Dodaj recenziju' : 'Uredi recenziju',
      successMessage: item == null
          ? 'Recenzija je uspješno dodana.'
          : 'Recenzija je uspješno ažurirana.',
      fields: [
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Korisnik',
            value: userId,
            items: users
                .map((u) => DropdownMenuItem(
                      value: u['id'] as int,
                      child: Text(userDropdownLabel(u)),
                    ))
                .toList(),
            onChanged: (v) => s(() => userId = v),
          ),
        ),
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Parking',
            value: lotId,
            items: lots
                .map((l) => DropdownMenuItem(
                      value: l['id'] as int,
                      child: Text(l['name']?.toString() ?? 'Parking'),
                    ))
                .toList(),
            onChanged: (v) => s(() => lotId = v),
          ),
        ),
        StatefulBuilder(
          builder: (c, s) => requiredIntDropdown(
            label: 'Ocjena (1–5)',
            value: rating,
            items: List.generate(
              5,
              (i) => DropdownMenuItem(value: i + 1, child: Text('${i + 1}')),
            ),
            onChanged: (v) => s(() => rating = v ?? 5),
          ),
        ),
        textField(comment, 'Komentar', maxLines: 3),
      ],
      onSave: () async {
        final payload = {
          'userId': userId,
          'parkingLotId': lotId,
          'rating': rating,
          'comment': comment.text.trim().isEmpty ? null : comment.text.trim(),
        };
        if (item == null) {
          await api.post('/Reviews', payload);
        } else {
          await api.put('/Reviews', item['id'] as int, {...payload, 'id': item['id']});
        }
        await reload();
      },
    );
  }
}

class GendersPage extends StatelessWidget {
  const GendersPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Genders Management',
        subtitle: 'Manage genders',
        endpoint: '/Genders',
        searchHint: 'Search by gender name...',
        totalItemLabel: 'Genders',
        columnHeaders: const ['Name', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? ''),
            statusBadge(item['isActive'] == true ? 'Active' : 'Inactive'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _genderForm,
      );

  static Future<void> _genderForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    var isActive = item?['isActive'] as bool? ?? true;
    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Gender' : 'Edit Gender',
      successMessage: item == null
          ? 'Spol je uspješno dodan.'
          : 'Spol je uspješno ažuriran.',
      fields: [
        textField(n, 'Name'),
        StatefulBuilder(builder: (ctx2, s) => compactCheckboxListTile(
              title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true))),
      ],
      onSave: () async {
        final body = {'name': n.text.trim(), 'isActive': isActive};
        if (item == null) await api.post('/Genders', body);
        else await api.put('/Genders', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}

class CountriesPage extends StatelessWidget {
  const CountriesPage({super.key});
  @override
  Widget build(BuildContext context) => GenericCrudPage(
        title: 'Countries Management',
        subtitle: 'Manage countries',
        endpoint: '/Countries',
        searchHint: 'Search by country name...',
        totalItemLabel: 'Countries',
        columnHeaders: const ['Name', 'Status'],
        buildRow: (item, reload, {onEdit, onDelete}) => ManagementRow(
          cells: [
            Text(item['name']?.toString() ?? ''),
            statusBadge(item['isActive'] == true ? 'Active' : 'Inactive'),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        ),
        showForm: _countryForm,
      );

  static Future<void> _countryForm(BuildContext ctx, Map<String, dynamic>? item, ListReload reload) async {
    final api = ApiClient();
    final n = TextEditingController(text: item?['name']?.toString() ?? '');
    var isActive = item?['isActive'] as bool? ?? true;
    await showCrudDialog(
      context: ctx,
      title: item == null ? 'Add Country' : 'Edit Country',
      successMessage: item == null
          ? 'Država je uspješno dodana.'
          : 'Država je uspješno ažurirana.',
      fields: [
        textField(n, 'Name'),
        StatefulBuilder(builder: (ctx2, s) => compactCheckboxListTile(
              title: 'Active', value: isActive, onChanged: (v) => s(() => isActive = v ?? true))),
      ],
      onSave: () async {
        final body = {'name': n.text.trim(), 'isActive': isActive};
        if (item == null) await api.post('/Countries', body);
        else await api.put('/Countries', item['id'] as int, {...body, 'id': item['id']});
        await reload();
      },
    );
  }
}
