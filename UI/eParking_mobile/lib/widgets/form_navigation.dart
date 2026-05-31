import 'package:flutter/material.dart';

import '../l10n/app_strings.dart';

/// AppBar za pod-ekrane s strelicom nazad ulijevo (RS2 navigacija).
PreferredSizeWidget formScreenAppBar(
  BuildContext context, {
  required String title,
  List<Widget>? actions,
}) {
  final s = context.s;
  final canPop = Navigator.canPop(context);

  return AppBar(
    title: Text(title),
    actions: actions,
    automaticallyImplyLeading: false,
    leading: canPop
        ? IconButton(
            icon: const Icon(Icons.arrow_back),
            tooltip: s.back,
            onPressed: () => Navigator.maybePop(context),
          )
        : null,
  );
}
