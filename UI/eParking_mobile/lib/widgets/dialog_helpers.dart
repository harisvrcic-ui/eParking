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
