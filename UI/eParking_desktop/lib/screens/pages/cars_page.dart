import 'package:flutter/material.dart';

import '../../core/api_client.dart';
import '../../widgets/generic_crud_page.dart';
import '../../widgets/image_helpers.dart';
import '../../widgets/management_page_layout.dart';
import '../forms/form_helpers.dart';

class CarsPage extends StatelessWidget {
  const CarsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return GenericCrudPage(
      title: 'Vozila',
      subtitle: 'Upravljanje vozilima korisnika',
      endpoint: '/Cars',
      searchHint: 'Pretraži po tablici, modelu ili korisniku...',
      totalItemLabel: 'Vozila',
      columnHeaders: const ['Slika', 'Tablice', 'Model', 'Brend', 'Boja', 'Korisnik'],
      filter: (item, q) {
        final plate = (item['licensePlate'] ?? '').toString().toLowerCase();
        final model = (item['model'] ?? '').toString().toLowerCase();
        final user = (item['userFullName'] ?? '').toString().toLowerCase();
        return plate.contains(q) || model.contains(q) || user.contains(q);
      },
      buildRow: (item, reload, {onEdit, onDelete}) {
        return ManagementRow(
          cells: [
            carThumbnail(item['picture']?.toString()),
            Text(item['licensePlate']?.toString() ?? '', style: const TextStyle(fontWeight: FontWeight.w600)),
            Text(item['model']?.toString() ?? ''),
            Text(item['brandName']?.toString() ?? ''),
            Text(item['colorName']?.toString() ?? ''),
            Text(item['userFullName']?.toString() ?? ''),
          ],
          onEdit: onEdit,
          onDelete: onDelete,
        );
      },
      showForm: _showForm,
    );
  }

  static Future<void> _showForm(
    BuildContext context,
    Map<String, dynamic>? item,
    Future<void> Function() reload,
  ) async {
    final api = ApiClient();
    Map<String, dynamic>? carItem = item;
    if (item != null) {
      carItem = await api.getById('/Cars', item['id'] as int);
    }
    final users = await loadLookup('/MyAppUsers');
    final brands = await loadLookup('/Brands');
    final colors = await loadLookup('/Colors');

    if (item == null &&
        !guardInsertPrerequisites(context, {
          'Korisnik': users,
          'Brend': brands,
          'Boja': colors,
        })) {
      return;
    }

    final modelC = TextEditingController(text: carItem?['model']?.toString() ?? '');
    final plateC = TextEditingController(text: carItem?['licensePlate']?.toString() ?? '');
    int? userId = carItem?['userId'] as int? ?? (users.isNotEmpty ? users.first['id'] as int : null);
    int? brandId = carItem?['brandId'] as int? ?? (brands.isNotEmpty ? brands.first['id'] as int : null);
    int? colorId = carItem?['colorId'] as int? ?? (colors.isNotEmpty ? colors.first['id'] as int : null);
    var isActive = carItem?['isActive'] as bool? ?? true;
    String? picture = carItem?['picture']?.toString();

    await showCrudDialog(
      context: context,
      title: item == null ? 'Dodaj vozilo' : 'Uredi vozilo',
      successMessage: item == null ? 'Vozilo je uspješno dodano.' : 'Vozilo je uspješno ažurirano.',
      fields: [
        StatefulBuilder(
          builder: (ctx, setS) => formImagePreview(
            pictureBase64: picture,
            onPick: () async {
              final picked = await pickImageBase64();
              if (picked != null) setS(() => picture = picked);
            },
            onClear: () => setS(() => picture = null),
          ),
        ),
        textField(modelC, 'Model'),
        textField(plateC, 'Registarske tablice'),
        StatefulBuilder(
          builder: (ctx, setS) => lookupDropdownWithQuickAdd(
            label: 'Brend',
            value: brandId,
            items: brands,
            labelBuilder: (b) => b['name'].toString(),
            onChanged: (v) => setS(() => brandId = v),
            onAdd: () async {
              final created = await _quickAddBrand(ctx);
              if (created != null) {
                brands.add(created);
                setS(() => brandId = created['id'] as int);
              }
            },
          ),
        ),
        StatefulBuilder(
          builder: (ctx, setS) => lookupDropdownWithQuickAdd(
            label: 'Boja',
            value: colorId,
            items: colors,
            labelBuilder: (c) => c['name'].toString(),
            onChanged: (v) => setS(() => colorId = v),
            onAdd: () async {
              final created = await _quickAddColor(ctx);
              if (created != null) {
                colors.add(created);
                setS(() => colorId = created['id'] as int);
              }
            },
          ),
        ),
        StatefulBuilder(
          builder: (ctx, setS) => requiredIntDropdown(
            label: 'Korisnik',
            value: userId,
            items: users
                .map((u) => DropdownMenuItem(
                      value: u['id'] as int,
                      child: Text(userDropdownLabel(u)),
                    ))
                .toList(),
            onChanged: (v) => setS(() => userId = v),
          ),
        ),
        StatefulBuilder(
          builder: (ctx, setS) => compactCheckboxListTile(
            title: 'Aktivno',
            value: isActive,
            onChanged: (v) => setS(() => isActive = v ?? true),
          ),
        ),
      ],
      onSave: () async {
        final body = {
          'brandId': brandId,
          'colorId': colorId,
          'userId': userId,
          'model': modelC.text.trim(),
          'licensePlate': plateC.text.trim(),
          'picture': picture,
          'isActive': isActive,
          'yearOfManufacture': DateTime.now().year,
        };
        if (item == null) {
          await api.post('/Cars', body);
        } else {
          body['id'] = item['id'];
          await api.put('/Cars', item['id'] as int, body);
        }
        await reload();
      },
    );
  }

  static Future<Map<String, dynamic>?> _quickAddBrand(BuildContext ctx) async {
    final api = ApiClient();
    final nameC = TextEditingController();
    Map<String, dynamic>? result;

    await showCrudDialog(
      context: ctx,
      title: 'Novi brend',
      successMessage: 'Brend je dodan.',
      fields: [textField(nameC, 'Naziv brenda')],
      onSave: () async {
        result = await api.post('/Brands', {'name': nameC.text.trim(), 'isActive': true});
      },
    );
    return result;
  }

  static Future<Map<String, dynamic>?> _quickAddColor(BuildContext ctx) async {
    final api = ApiClient();
    final nameC = TextEditingController();
    final hexC = TextEditingController(text: '#000000');
    Map<String, dynamic>? result;

    await showCrudDialog(
      context: ctx,
      title: 'Nova boja',
      successMessage: 'Boja je dodana.',
      fields: [
        textField(nameC, 'Naziv boje'),
        hexColorField(hexC, 'Hex kod'),
      ],
      onSave: () async {
        result = await api.post('/Colors', {
          'name': nameC.text.trim(),
          'hexCode': hexC.text.trim().isEmpty ? null : hexC.text.trim(),
        });
      },
    );
    return result;
  }
}
