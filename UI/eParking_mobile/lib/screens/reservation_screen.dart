import 'package:flutter/material.dart';

import '../core/parking_data_refresh.dart';
import '../l10n/app_strings.dart';
import '../l10n/locale_controller.dart';
import '../models/car.dart';
import '../models/lookup_item.dart';
import '../services/car_service.dart';
import '../services/reservation_service.dart';
import '../utils/input_validators.dart';
import '../utils/money.dart';
import '../widgets/dialog_helpers.dart';
import '../widgets/form_field_controls.dart';
import '../widgets/form_navigation.dart';

class ReservationScreen extends StatefulWidget {
  const ReservationScreen({
    super.key,
    required this.userId,
    required this.parkingSpotId,
    required this.locationName,
    required this.spotLabel,
  });

  final int userId;
  final int parkingSpotId;
  final String locationName;
  final String spotLabel;

  @override
  State<ReservationScreen> createState() => _ReservationScreenState();
}

class _ReservationScreenState extends State<ReservationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _carService = CarService();
  final _reservationService = ReservationService();

  List<Car> _cars = [];
  List<LookupItem> _reservationTypes = [];
  int? _reservationTypeId;
  int? _selectedCarId;

  DateTime _date = DateTime.now();
  TimeOfDay _startTime = const TimeOfDay(hour: 10, minute: 0);
  TimeOfDay _endTime = const TimeOfDay(hour: 12, minute: 30);

  bool _loading = true;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final cars = await _carService.getMyCars();
      final types = await _reservationService.getReservationTypes();

      if (cars.isEmpty) {
        throw Exception(AppStrings.current.noVehicles);
      }

      setState(() {
        _cars = cars;
        _reservationTypes = types;
        _selectedCarId = cars.first.id;
        _reservationTypeId = types.isNotEmpty ? types.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceFirst('Exception: ', '');
        _loading = false;
      });
    }
  }

  DateTime _combine(DateTime date, TimeOfDay time) {
    return DateTime(date.year, date.month, date.day, time.hour, time.minute);
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool isStart}) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStart ? _startTime : _endTime,
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  Future<void> _confirm() async {
    final s = context.s;
    if (!(_formKey.currentState?.validate() ?? false)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: dialogTitleBar(ctx, s.confirmReservation),
        content: Text(s.confirmReservationQuestion),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(s.no),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(s.confirmReservation),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    final start = _combine(_date, _startTime);
    final end = _combine(_date, _endTime);

    setState(() => _submitting = true);

    try {
      final result = await _reservationService.createReservation(
        carId: _selectedCarId!,
        parkingSpotId: widget.parkingSpotId,
        reservationTypeId: _reservationTypeId!,
        startDate: start,
        endDate: end,
      );

      if (!mounted) return;

      final status = result['status'] as String? ?? 'Pending';
      final isPending = status == 'Pending';
      final price = result['finalPrice'];

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: dialogTitleBar(
            ctx,
            isPending ? s.reservationSubmitted : s.reservationConfirmed,
          ),
          content: Text(
            isPending
                ? '${s.reservationSubmittedMessage}\n\n'
                    '${widget.locationName} · ${widget.spotLabel}\n'
                    '${s.priceLabel}: ${price != null ? formatMoneyKmFromJson(price) : '—'}'
                : '${widget.locationName} · ${widget.spotLabel}\n'
                    '${s.priceLabel}: ${price != null ? formatMoneyKmFromJson(price) : '—'}',
          ),
          actions: [
            FilledButton(
              onPressed: () {
                ParkingDataRefresh.notify();
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text(s.ok),
            ),
          ],
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  String _formatTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    final period = t.period == DayPeriod.am ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: LocaleController.instance,
      builder: (context, _) {
        final s = context.s;

        return Scaffold(
          appBar: formScreenAppBar(context, title: s.reservationTitle),
          body: _loading
              ? const Center(child: CircularProgressIndicator())
              : _error != null
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(_error!, textAlign: TextAlign.center),
                            const SizedBox(height: 12),
                            FilledButton(
                              onPressed: _load,
                              child: Text(s.retry),
                            ),
                          ],
                        ),
                      ),
                    )
                  : Form(
                      key: _formKey,
                      autovalidateMode: AutovalidateMode.disabled,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
                        children: [
                          Text(
                            widget.locationName,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            widget.spotLabel,
                            style: TextStyle(color: Colors.grey.shade700),
                          ),
                          const SizedBox(height: 20),
                          DropdownButtonFormField<int>(
                            initialValue: _selectedCarId,
                            decoration: InputDecoration(
                              labelText: s.vehicle,
                              filled: true,
                            ),
                            items: _cars
                                .map(
                                  (c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.label),
                                  ),
                                )
                                .toList(),
                            onChanged: (v) =>
                                setState(() => _selectedCarId = v),
                            validator: (v) => InputValidators.dropdownInt(
                              v,
                              s.vehicle,
                              s,
                            ),
                          ),
                          if (_reservationTypes.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            DropdownButtonFormField<int>(
                              initialValue: _reservationTypeId,
                              decoration: InputDecoration(
                                labelText: s.reservationType,
                                filled: true,
                              ),
                              items: _reservationTypes
                                  .map(
                                    (t) => DropdownMenuItem(
                                      value: t.id,
                                      child: Text(t.name),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (v) =>
                                  setState(() => _reservationTypeId = v),
                              validator: (v) => InputValidators.dropdownInt(
                                v,
                                s.reservationType,
                                s,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          FormTapControl(
                            label: s.date,
                            value: '${_date.day}.${_date.month}.${_date.year}',
                            onTap: _pickDate,
                          ),
                          const SizedBox(height: 12),
                          FormTapControl(
                            label: s.startTime,
                            value: _formatTime(_startTime),
                            onTap: () => _pickTime(isStart: true),
                          ),
                          const SizedBox(height: 12),
                          FormTapControl(
                            label: s.endTime,
                            value: _formatTime(_endTime),
                            onTap: () => _pickTime(isStart: false),
                            validator: (_) {
                              final start = _combine(_date, _startTime);
                              final end = _combine(_date, _endTime);
                              if (!end.isAfter(start)) {
                                return s.validationEndAfterStartDetailed;
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 28),
                          FilledButton(
                            onPressed: _submitting ? null : _confirm,
                            style: FilledButton.styleFrom(
                              minimumSize: const Size.fromHeight(48),
                            ),
                            child: _submitting
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(s.confirmReservation),
                          ),
                        ],
                      ),
                    ),
        );
      },
    );
  }
}
