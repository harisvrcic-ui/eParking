import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// Naslov dijaloga / donjeg lista s dugmetom X (RS2 UX).
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

/// Upozorenje prije nepovratne radnje (brisanje, otkazivanje, …).
Future<bool> showDestructiveConfirmDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? details,
  required String confirmLabel,
  String? cancelLabel,
  bool destructive = true,
}) async {
  final s = context.s;
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => AlertDialog(
      title: dialogTitleBar(ctx, title),
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
                  message,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            s.irreversibleActionWarning,
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
          child: Text(cancelLabel ?? s.no),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(ctx, true),
          style: destructive
              ? FilledButton.styleFrom(backgroundColor: Colors.red)
              : null,
          child: Text(confirmLabel),
        ),
      ],
    ),
  );
  return result == true;
}

/// Otkazivanje rezervacije s obaveznim razlogom (audit trag).
Future<String?> showCancelReservationDialog(
  BuildContext context, {
  required String title,
  required String message,
  String? details,
  required String confirmLabel,
}) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _CancelReservationDialog(
      title: title,
      message: message,
      details: details,
      confirmLabel: confirmLabel,
    ),
  );
}

class _CancelReservationDialog extends StatefulWidget {
  const _CancelReservationDialog({
    required this.title,
    required this.message,
    this.details,
    required this.confirmLabel,
  });

  final String title;
  final String message;
  final String? details;
  final String confirmLabel;

  @override
  State<_CancelReservationDialog> createState() =>
      _CancelReservationDialogState();
}

class _CancelReservationDialogState extends State<_CancelReservationDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _reasonController;

  @override
  void initState() {
    super.initState();
    _reasonController = TextEditingController();
  }

  @override
  void dispose() {
    _reasonController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = context.s;

    return AlertDialog(
      title: dialogTitleBar(context, widget.title),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.message,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 8),
            Text(
              s.irreversibleActionWarning,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
            ),
            if (widget.details != null && widget.details!.isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(
                widget.details!,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
            const SizedBox(height: 16),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(
                labelText: 'Razlog otkazivanja',
                helperText: 'Obavezno — razlog se čuva u historiji rezervacije',
              ),
              maxLines: 3,
              autofocus: true,
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return s.requiredField;
                }
                return null;
              },
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(s.no),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(context, _reasonController.text.trim());
          },
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          child: Text(widget.confirmLabel),
        ),
      ],
    );
  }
}
