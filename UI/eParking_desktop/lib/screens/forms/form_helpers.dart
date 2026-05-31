import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../core/api_client.dart';

/// Eksplicitne poruke validacije (RS2 RB 5/6).
class ValidationMsgs {
  static String required(String label) =>
      'Polje "$label" je obavezno — unesite vrijednost.';

  static String requiredSelect(String label) =>
      'Polje "$label" je obavezno — odaberite stavku iz padajuće liste.';

  static String minLength(String label, int min) =>
      'Polje "$label" mora imati najmanje $min znaka.';

  static String maxLength(String label, int max) =>
      'Polje "$label" smije imati najviše $max znakova.';

  static String positiveInteger(String label) =>
      'Polje "$label" mora biti cijeli pozitivan broj (npr. 1, 2, 15) — bez slova i decimala.';

  static String decimalInRange(String label, double min, double max) =>
      'Polje "$label" mora biti broj od $min do $max (dozvoljena decimalna tačka, npr. 1.25).';

  static const email =
      'Unesite ispravnu e-mail adresu u formatu korisnik@domena.com.';

  static const phone =
      'Telefon mora imati 8–15 cifara; dozvoljeni +, razmaci i crtice (npr. +387 61 123 456). Ostavite prazno ako nije potreban.';

  static String password({int minLen = 6}) =>
      'Lozinka je obavezna — najmanje $minLen znakova (slova i/ili brojevi).';

  static const passwordMismatch =
      'Lozinke se ne podudaraju — unesite istu lozinku u oba polja.';

  static const username =
      'Korisničko ime je obavezno — najmanje 3 znaka, bez razmaka (npr. admin ili korisnik1).';

  static const hexOptional =
      'Hex boja mora biti u formatu #RRGGBB (6 hex znamenki, npr. #FF5733) ili ostavite prazno.';

  static const endAfterStart =
      'Datum i vrijeme završetka moraju biti poslije početka rezervacije.';

  static String noLookupData(String label) =>
      'Nema zapisa za "$label". Prvo dodajte podatke u šifarnik, pa pokušajte ponovo.';
}

const double kFormDialogWidth = 420;
const double kFormDialogMaxHeight = 520;

/// Ograničenja da forma ne zauzima cijeli ekran i ne preklapa kontrole.
BoxConstraints formDialogConstraints(BuildContext context) {
  final maxH = MediaQuery.sizeOf(context).height * 0.72;
  return BoxConstraints(
    maxWidth: kFormDialogWidth,
    maxHeight: maxH < kFormDialogMaxHeight ? maxH : kFormDialogMaxHeight,
  );
}

Widget formDialogScrollableContent({
  required BuildContext context,
  required Widget child,
  double width = kFormDialogWidth,
}) {
  return SizedBox(
    width: width,
    child: ConstrainedBox(
      constraints: formDialogConstraints(context),
      child: SingleChildScrollView(child: child),
    ),
  );
}

/// Naslov dijaloga s dugmetom X (RS2 UX — zatvaranje forme).
Widget dialogTitleBar(BuildContext dialogContext, String title) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(
        child: Text(
          title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      IconButton(
        visualDensity: VisualDensity.compact,
        icon: const Icon(Icons.close),
        tooltip: 'Zatvori',
        onPressed: () => Navigator.of(dialogContext).pop(),
      ),
    ],
  );
}

/// Kompaktniji checkbox na formama (manje vertikalnog prostora).
/// Datum/vrijeme na formi — kompaktno, bez preklapanja s trailing ikonom.
Widget formDateTimeField({
  required String label,
  required DateTime value,
  required VoidCallback onTap,
  String? helperText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          helperText: helperText,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today, size: 20),
          isDense: true,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
        child: Text(
          value.toString().substring(0, 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    ),
  );
}

/// Upozorenje prije brisanja (RS2 — izbjegavanje slučajnog brisanja).
Future<bool> showDeleteConfirmDialog(
  BuildContext context, {
  required String itemLabel,
  String? details,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: dialogTitleBar(ctx, 'Potvrda brisanja'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: Colors.orange.shade800,
                size: 36,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Jeste li sigurni da želite obrisati $itemLabel?',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Ova radnja je nepovratna i ne može se poništiti. Provjerite podatke prije nastavka.',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
          ),
          if (details != null && details.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(details, style: const TextStyle(fontWeight: FontWeight.w500)),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(ctx, false),
          child: const Text('Odustani'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: const Text('Obriši'),
        ),
      ],
    ),
  );
  return result == true;
}

Widget compactCheckboxListTile({
  required String title,
  required bool value,
  required ValueChanged<bool?> onChanged,
}) {
  return CheckboxListTile(
    title: Text(title),
    value: value,
    onChanged: onChanged,
    visualDensity: VisualDensity.compact,
    contentPadding: EdgeInsets.zero,
    controlAffinity: ListTileControlAffinity.leading,
  );
}

Future<void> showCrudDialog({
  required BuildContext context,
  required String title,
  required List<Widget> fields,
  required Future<void> Function() onSave,
  String successMessage = 'Zapis je uspješno sačuvan.',
}) async {
  final formKey = GlobalKey<FormState>();
  await showDialog(
    context: context,
    barrierDismissible: true,
    builder: (ctx) => AlertDialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      title: dialogTitleBar(ctx, title),
      content: Form(
        key: formKey,
        autovalidateMode: AutovalidateMode.disabled,
        child: formDialogScrollableContent(
          context: ctx,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: fields,
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Odustani')),
        FilledButton(
          onPressed: () async {
            if (!formKey.currentState!.validate()) return;
            try {
              await onSave();
              formKey.currentState?.reset();
              if (ctx.mounted) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text(successMessage)),
                );
              }
            } catch (e) {
              if (ctx.mounted) {
                ScaffoldMessenger.of(ctx).showSnackBar(
                  SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                );
              }
            }
          },
          child: const Text('Sačuvaj'),
        ),
      ],
    ),
  );
}

InputDecoration _decoration(String label, {String? helperText}) {
  return InputDecoration(
    labelText: label,
    helperText: helperText,
    helperMaxLines: 3,
    border: const OutlineInputBorder(),
  );
}

Widget textField(
  TextEditingController c,
  String label, {
  bool required = true,
  int maxLines = 1,
  int? maxLength,
  int minLength = 1,
  String? helperText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      maxLines: maxLines,
      maxLength: maxLength,
      decoration: _decoration(label, helperText: helperText),
      validator: required
          ? (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return ValidationMsgs.required(label);
              if (t.length < minLength) return ValidationMsgs.minLength(label, minLength);
              if (maxLength != null && t.length > maxLength) {
                return ValidationMsgs.maxLength(label, maxLength);
              }
              return null;
            }
          : (v) {
              final t = v?.trim() ?? '';
              if (t.isEmpty) return null;
              if (maxLength != null && t.length > maxLength) {
                return ValidationMsgs.maxLength(label, maxLength);
              }
              return null;
            },
    ),
  );
}

Widget usernameField(TextEditingController c, String label) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      decoration: _decoration(
        label,
        helperText: 'Najmanje 3 znaka, bez razmaka.',
      ),
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return ValidationMsgs.username;
        if (t.length < 3) return ValidationMsgs.minLength(label, 3);
        if (t.contains(' ')) {
          return 'Korisničko ime ne smije sadržavati razmake — koristite npr. korisnik1.';
        }
        return null;
      },
    ),
  );
}

Widget phoneField(TextEditingController c, String label, {bool required = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.phone,
      decoration: _decoration(
        label,
        helperText: 'Opcionalno: +387 61 123 456',
      ),
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return required ? ValidationMsgs.required(label) : null;
        if (!RegExp(r'^[\d\s\+\-\(\)]+$').hasMatch(t)) return ValidationMsgs.phone;
        final digits = t.replaceAll(RegExp(r'\D'), '');
        if (digits.length < 8 || digits.length > 15) return ValidationMsgs.phone;
        return null;
      },
    ),
  );
}

Widget emailField(TextEditingController c, String label, {bool required = true}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.emailAddress,
      decoration: _decoration(
        label,
        helperText: 'Format: ime@domena.com',
      ),
      validator: (v) {
        if (!required && (v == null || v.trim().isEmpty)) return null;
        if (v == null || v.trim().isEmpty) return ValidationMsgs.required(label);
        final email = RegExp(r'^[\w\.\-]+@[\w\-]+\.[A-Za-z]{2,}$');
        if (!email.hasMatch(v.trim())) return ValidationMsgs.email;
        return null;
      },
    ),
  );
}

Widget passwordField(TextEditingController c, String label, {bool required = false, int minLen = 6}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      obscureText: true,
      decoration: _decoration(
        label,
        helperText: required ? 'Najmanje $minLen znakova.' : 'Ostavite prazno ako ne mijenjate lozinku.',
      ),
      validator: (v) {
        if (!required && (v == null || v.isEmpty)) return null;
        if (v == null || v.length < minLen) return ValidationMsgs.password(minLen: minLen);
        return null;
      },
    ),
  );
}

Widget passwordConfirmField(
  TextEditingController password,
  TextEditingController confirm,
  String label, {
  bool required = false,
  int minLen = 6,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: confirm,
      obscureText: true,
      decoration: _decoration(
        label,
        helperText: 'Ponovite novu lozinku radi potvrde.',
      ),
      validator: (v) {
        final pass = password.text;
        if (!required && pass.isEmpty && (v == null || v.isEmpty)) return null;
        if (pass.isNotEmpty && (v == null || v.isEmpty)) {
          return ValidationMsgs.password(minLen: minLen);
        }
        if (pass.isNotEmpty && v != pass) return ValidationMsgs.passwordMismatch;
        return null;
      },
    ),
  );
}

Widget integerField(
  TextEditingController c,
  String label, {
  bool required = true,
  int min = 1,
  int? max,
  String? helperText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      decoration: _decoration(
        label,
        helperText: helperText ?? 'Samo cijeli broj${max != null ? ' od $min do $max' : ' ≥ $min'}.',
      ),
      validator: (v) {
        if (!required && (v == null || v.trim().isEmpty)) return null;
        if (v == null || v.trim().isEmpty) return ValidationMsgs.required(label);
        final n = int.tryParse(v.trim());
        if (n == null) return ValidationMsgs.positiveInteger(label);
        if (n < min) {
          return 'Polje "$label" mora biti najmanje $min.';
        }
        if (max != null && n > max) {
          return 'Polje "$label" mora biti najviše $max.';
        }
        return null;
      },
    ),
  );
}

Widget numberField(
  TextEditingController c,
  String label, {
  bool required = true,
  double min = 0,
  double max = 999999,
  String? helperText,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: _decoration(label, helperText: helperText),
      validator: (v) {
        if (!required && (v == null || v.trim().isEmpty)) return null;
        if (v == null || v.trim().isEmpty) return ValidationMsgs.required(label);
        final n = double.tryParse(v.trim().replaceAll(',', '.'));
        if (n == null) return ValidationMsgs.decimalInRange(label, min, max);
        if (n < min || n > max) return ValidationMsgs.decimalInRange(label, min, max);
        return null;
      },
    ),
  );
}

Widget hexColorField(TextEditingController c, String label, {bool required = false}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: TextFormField(
      controller: c,
      decoration: _decoration(
        label,
        helperText: 'Opcionalno: #RRGGBB (npr. #1A2B3C).',
      ),
      validator: (v) {
        final t = v?.trim() ?? '';
        if (t.isEmpty) return required ? ValidationMsgs.required(label) : null;
        if (!RegExp(r'^#?[0-9A-Fa-f]{6}$').hasMatch(t)) return ValidationMsgs.hexOptional;
        return null;
      },
    ),
  );
}

Widget optionalIntDropdown({
  required String label,
  required int? value,
  required List<DropdownMenuItem<int>> items,
  required ValueChanged<int?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: _decoration(label, helperText: 'Opcionalno — odaberite iz liste.'),
      items: [
        const DropdownMenuItem(value: null, child: Text('—')),
        ...items,
      ],
      onChanged: onChanged,
    ),
  );
}

Widget requiredIntDropdown({
  required String label,
  required int? value,
  required List<DropdownMenuItem<int>> items,
  required ValueChanged<int?> onChanged,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: DropdownButtonFormField<int>(
      value: value,
      isExpanded: true,
      decoration: _decoration(label, helperText: 'Obavezno polje — odaberite iz liste.'),
      items: items,
      onChanged: onChanged,
      validator: (v) {
        if (items.isEmpty) return ValidationMsgs.noLookupData(label);
        if (v == null) return ValidationMsgs.requiredSelect(label);
        return null;
      },
    ),
  );
}

Future<List<Map<String, dynamic>>> loadLookup(String path) async {
  final api = ApiClient();
  final data = await api.getList(path);
  return data.cast<Map<String, dynamic>>();
}

/// Blokira otvaranje insert forme ako šifarnik nije popunjen (RS2 6).
bool guardInsertPrerequisites(
  BuildContext context,
  Map<String, List<Map<String, dynamic>>> requiredLookups,
) {
  for (final entry in requiredLookups.entries) {
    if (entry.value.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ValidationMsgs.noLookupData(entry.key))),
      );
      return false;
    }
  }
  return true;
}

String userDropdownLabel(Map<String, dynamic> user) {
  final username = user['username']?.toString() ?? '';
  final fullName = '${user['firstName'] ?? ''} ${user['lastName'] ?? ''}'.trim();
  if (fullName.isNotEmpty) return '$username — $fullName';
  return username;
}

String reservationDropdownLabel(Map<String, dynamic> reservation) {
  final plate = reservation['licensePlate']?.toString() ?? '';
  final spot = reservation['parkingSpotDisplayName']?.toString() ?? '';
  final start = reservation['startDate']?.toString() ?? '';
  final datePart = start.length >= 10 ? start.substring(0, 10) : start;
  return '$plate · $spot · $datePart';
}

/// Dvokolonski red: ikona + labela lijevo, vrijednost desno (RS2 6).
Widget detailInfoRow({
  required IconData icon,
  required String label,
  required String value,
  Color? iconColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 6),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: iconColor ?? Colors.grey.shade700),
        const SizedBox(width: 10),
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w500),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
        ),
      ],
    ),
  );
}

/// Dropdown s dugmetom za brzo dodavanje FK zapisa bez napuštanja forme.
Widget lookupDropdownWithQuickAdd({
  required String label,
  required int? value,
  required List<Map<String, dynamic>> items,
  required String Function(Map<String, dynamic>) labelBuilder,
  required ValueChanged<int?> onChanged,
  required Future<void> Function() onAdd,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: requiredIntDropdown(
            label: label,
            value: value,
            items: items
                .map((item) => DropdownMenuItem(
                      value: item['id'] as int,
                      child: Text(labelBuilder(item)),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
        const SizedBox(width: 4),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Tooltip(
            message: 'Dodaj novi zapis',
            child: IconButton(
              onPressed: onAdd,
              icon: const Icon(Icons.add_circle_outline),
            ),
          ),
        ),
      ],
    ),
  );
}

Widget colorSwatch(String? hex, {double size = 22}) {
  Color? color;
  if (hex != null && hex.isNotEmpty) {
    var h = hex.trim();
    if (!h.startsWith('#')) h = '#$h';
    if (RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(h)) {
      color = Color(int.parse(h.substring(1), radix: 16) + 0xFF000000);
    }
  }
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: color ?? Colors.grey.shade300,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: Colors.grey.shade400),
    ),
  );
}

Future<void> pickDateAndTime(
  BuildContext context, {
  required DateTime initial,
  required ValueChanged<DateTime> onChanged,
}) async {
  final date = await showDatePicker(
    context: context,
    initialDate: initial,
    firstDate: DateTime(2020),
    lastDate: DateTime(2035),
  );
  if (date == null || !context.mounted) return;

  final time = await showTimePicker(
    context: context,
    initialTime: TimeOfDay.fromDateTime(initial),
  );
  if (time == null) return;

  onChanged(DateTime(date.year, date.month, date.day, time.hour, time.minute));
}
