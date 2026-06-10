import 'package:flutter/material.dart';

import '../models/car.dart';
import '../models/lookup_item.dart';
import '../l10n/app_strings.dart';
import '../services/car_service.dart';
import '../utils/input_validators.dart';
import '../widgets/dialog_helpers.dart';
import '../widgets/form_field_controls.dart';
import '../widgets/form_navigation.dart';
import '../services/lookup_service.dart';

class VehicleEditScreen extends StatefulWidget {
  const VehicleEditScreen({
    super.key,
    required this.userId,
    this.carId,
  });

  final int userId;
  final int? carId;

  bool get isEdit => carId != null;

  @override
  State<VehicleEditScreen> createState() => _VehicleEditScreenState();
}

class _VehicleEditScreenState extends State<VehicleEditScreen> {
  final _carService = CarService();
  final _lookupService = LookupService();
  final _formKey = GlobalKey<FormState>();

  final _modelController = TextEditingController();
  final _plateController = TextEditingController();

  List<LookupItem> _brands = [];
  List<LookupItem> _colors = [];
  int? _brandId;
  int? _colorId;
  Car? _existing;

  bool _loading = true;
  bool _saving = false;
  String? _error;

  @override
  void dispose() {
    _modelController.dispose();
    _plateController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final brands = await _lookupService.getBrands();
      final colors = await _lookupService.getColors();

      if (widget.isEdit) {
        _existing = await _carService.getCar(widget.carId!);
        _modelController.text = _existing!.model;
        _plateController.text = _existing!.licensePlate;
        _brandId = _existing!.brandId;
        _colorId = _existing!.colorId;
      } else {
        if (brands.isNotEmpty) _brandId = brands.first.id;
        if (colors.isNotEmpty) _colorId = colors.first.id;
      }

      setState(() {
        _brands = brands;
        _colors = colors;
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      if (widget.isEdit) {
        await _carService.updateCar(
          id: widget.carId!,
          userId: widget.userId,
          brandId: _brandId!,
          colorId: _colorId!,
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim(),
          isActive: _existing?.isActive ?? true,
        );
      } else {
        await _carService.createCar(
          userId: widget.userId,
          brandId: _brandId!,
          colorId: _colorId!,
          model: _modelController.text.trim(),
          licensePlate: _plateController.text.trim(),
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _delete() async {
    final s = context.s;
    final plate = _plateController.text.trim();
    final confirm = await showDestructiveConfirmDialog(
      context,
      title: s.deleteVehicleQuestion,
      message: s.deleteConfirmQuestion(plate.isEmpty ? s.editVehicle : plate),
      details: s.deleteVehicleBody,
      confirmLabel: s.delete,
    );
    if (!confirm) return;

    try {
      await _carService.deleteCar(widget.carId!);
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;
    return Scaffold(
      appBar: formScreenAppBar(
        context,
        title: widget.isEdit ? s.editVehicle : s.newVehicle,
        actions: [
          if (widget.isEdit)
            IconButton(
              onPressed: _delete,
              icon: const Icon(Icons.delete_outline),
              color: Colors.red,
            ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!))
              : Form(
                  key: _formKey,
                  autovalidateMode: AutovalidateMode.disabled,
                  child: ListView(
                    padding: const EdgeInsets.all(20),
                    children: [
                      FormLookupDropdown(
                        label: 'Marka',
                        value: _brandId,
                        items: _brands,
                        allowNull: false,
                        onChanged: (id) => setState(() => _brandId = id),
                        validator: (v) =>
                            InputValidators.dropdownInt(v, 'Marka', s),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _modelController,
                        decoration: const InputDecoration(
                          labelText: 'Model',
                          helperText: 'Naziv modela (npr. Golf, 320d).',
                          filled: true,
                        ),
                        validator: (v) =>
                            InputValidators.text(v, 'Model', s, minLength: 1),
                      ),
                      const SizedBox(height: 12),
                      FormLookupDropdown(
                        label: 'Boja',
                        value: _colorId,
                        items: _colors,
                        allowNull: false,
                        onChanged: (id) => setState(() => _colorId = id),
                        validator: (v) =>
                            InputValidators.dropdownInt(v, 'Boja', s),
                      ),
                      const SizedBox(height: 12),
                      TextFormField(
                        controller: _plateController,
                        decoration: InputDecoration(
                          labelText: 'Registarske tablice',
                          helperText: s.validationLicensePlateFormat,
                          filled: true,
                        ),
                        validator: (v) => InputValidators.licensePlate(v, s),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                          minimumSize: const Size.fromHeight(48),
                        ),
                        child: _saving
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Text(
                                widget.isEdit ? s.saveChanges : s.addVehicle,
                              ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
