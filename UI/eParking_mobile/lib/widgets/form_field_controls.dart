import 'package:flutter/material.dart';

import '../models/lookup_item.dart';

/// Padajuća lista iz šifarnika (RS2 — grad, spol, brend…).
class FormLookupDropdown extends StatelessWidget {
  const FormLookupDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
    this.validator,
    this.allowNull = true,
    this.helperText,
  });

  final String label;
  final int? value;
  final List<LookupItem> items;
  final ValueChanged<int?> onChanged;
  final String? Function(int?)? validator;
  final bool allowNull;
  final String? helperText;

  @override
  Widget build(BuildContext context) {
    final selectedValue =
        value != null && items.any((item) => item.id == value) ? value : null;

    return DropdownButtonFormField<int>(
      key: ValueKey('$label-$selectedValue'),
      initialValue: selectedValue,
      isExpanded: true,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        filled: true,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
      ),
      items: [
        if (allowNull)
          const DropdownMenuItem<int>(value: null, child: Text('—')),
        ...items.map(
          (item) => DropdownMenuItem<int>(
            value: item.id,
            child: Text(item.name),
          ),
        ),
      ],
      onChanged: onChanged,
      validator: validator,
    );
  }
}

/// Picker kontrola s porukom greške ispod (RS2 — ne SnackBar).
class FormPickerControl extends StatelessWidget {
  const FormPickerControl({
    super.key,
    required this.label,
    required this.value,
    required this.displayValue,
    required this.onTap,
    required this.validator,
  });

  final String label;
  final int? value;
  final String? displayValue;
  final Future<void> Function() onTap;
  final String? Function(int?) validator;

  @override
  Widget build(BuildContext context) {
    return FormField<int>(
      key: ValueKey('$label-$value'),
      initialValue: value,
      validator: validator,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (state) {
        final theme = Theme.of(context);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            InkWell(
              onTap: () async {
                await onTap();
                state.didChange(value);
              },
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: label,
                  filled: true,
                  errorText: state.errorText,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                      color: state.hasError
                          ? theme.colorScheme.error
                          : Colors.grey.shade300,
                    ),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: theme.colorScheme.error),
                  ),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        displayValue ?? 'Odaberi',
                        style: TextStyle(
                          fontSize: 16,
                          color: displayValue == null ? Colors.grey : null,
                        ),
                      ),
                    ),
                    const Icon(Icons.chevron_right),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

/// Tap kontrola (datum/vrijeme) s porukom greške ispod polja.
class FormTapControl extends StatelessWidget {
  const FormTapControl({
    super.key,
    required this.label,
    required this.value,
    required this.onTap,
    this.validator,
  });

  final String label;
  final String value;
  final VoidCallback? onTap;
  final String? Function(void)? validator;

  @override
  Widget build(BuildContext context) {
    return FormField<void>(
      validator: validator,
      autovalidateMode: AutovalidateMode.disabled,
      builder: (state) {
        final theme = Theme.of(context);
        final borderColor = state.hasError
            ? theme.colorScheme.error
            : Colors.grey.shade300;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Material(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: onTap == null
                    ? null
                    : () {
                        onTap!();
                        state.didChange(null);
                      },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: state.hasError ? 1.5 : 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              label,
                              style: TextStyle(
                                fontSize: 12,
                                color: state.hasError
                                    ? theme.colorScheme.error
                                    : Colors.grey.shade600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              value,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (onTap != null)
                        Icon(
                          Icons.chevron_right,
                          color: state.hasError
                              ? theme.colorScheme.error
                              : Colors.grey.shade600,
                        ),
                    ],
                  ),
                ),
              ),
            ),
            if (state.hasError) ...[
              const SizedBox(height: 6),
              Padding(
                padding: const EdgeInsets.only(left: 12),
                child: Text(
                  state.errorText!,
                  style: TextStyle(
                    color: theme.colorScheme.error,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ],
        );
      },
    );
  }
}
