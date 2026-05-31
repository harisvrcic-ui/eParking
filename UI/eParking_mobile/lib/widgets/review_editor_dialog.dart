import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';
import '../models/review.dart';
import '../services/review_service.dart';
import '../utils/input_validators.dart';

Future<bool?> showReviewEditorDialog({
  required BuildContext context,
  required int parkingLotId,
  required AppStrings strings,
  Review? existing,
}) {
  return showDialog<bool>(
    context: context,
    builder: (ctx) => _ReviewEditorDialog(
      parkingLotId: parkingLotId,
      strings: strings,
      existing: existing,
    ),
  );
}

class _ReviewEditorDialog extends StatefulWidget {
  const _ReviewEditorDialog({
    required this.parkingLotId,
    required this.strings,
    this.existing,
  });

  final int parkingLotId;
  final AppStrings strings;
  final Review? existing;

  @override
  State<_ReviewEditorDialog> createState() => _ReviewEditorDialogState();
}

class _ReviewEditorDialogState extends State<_ReviewEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  final _service = ReviewService();
  final _commentController = TextEditingController();

  late int _rating;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _rating = widget.existing?.rating ?? 5;
    _commentController.text = widget.existing?.comment ?? '';
  }

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;

    setState(() => _saving = true);

    try {
      if (widget.existing == null) {
        await _service.create(
          parkingLotId: widget.parkingLotId,
          rating: _rating,
          comment: _commentController.text,
        );
      } else {
        await _service.update(
          id: widget.existing!.id,
          parkingLotId: widget.parkingLotId,
          rating: _rating,
          comment: _commentController.text,
        );
      }
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceFirst('Exception: ', '')),
          ),
        );
      }
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final s = widget.strings;
    final isEdit = widget.existing != null;
    final errorColor = Theme.of(context).colorScheme.error;

    return AlertDialog(
      title: Text(isEdit ? s.editMyReview : s.addReview),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.disabled,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              FormField<int>(
                initialValue: _rating,
                validator: (v) => InputValidators.reviewRating(v, s),
                builder: (state) {
                  final rating = state.value ?? _rating;
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        s.ratingLabel,
                        style: Theme.of(context).textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(5, (index) {
                          final star = index + 1;
                          return IconButton(
                            onPressed: _saving
                                ? null
                                : () {
                                    setState(() => _rating = star);
                                    state.didChange(star);
                                  },
                            icon: Icon(
                              star <= rating ? Icons.star : Icons.star_border,
                              color: Colors.amber.shade700,
                              size: 32,
                            ),
                          );
                        }),
                      ),
                      if (state.hasError)
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            state.errorText!,
                            style: TextStyle(color: errorColor, fontSize: 12),
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _commentController,
                maxLines: 4,
                maxLength: 1000,
                enabled: !_saving,
                decoration: InputDecoration(
                  labelText: s.reviewComment,
                  helperText: s.reviewCommentHint,
                  helperMaxLines: 2,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) => InputValidators.reviewComment(v, s),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context, false),
          child: Text(s.no),
        ),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(s.save),
        ),
      ],
    );
  }
}
