import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Bira sliku (sistemski picker) i vraća base64 — bez posebnih dozvola za galeriju.
Future<String?> pickProfileImageBase64() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
    allowMultiple: false,
  );
  if (result == null || result.files.isEmpty) return null;

  final picked = result.files.single;
  var bytes = picked.bytes;
  if (bytes == null || bytes.isEmpty) {
    final path = picked.path;
    if (path == null) return null;
    bytes = await File(path).readAsBytes();
  }
  if (bytes.isEmpty) return null;
  return base64Encode(bytes);
}

class ProfileAvatar extends StatelessWidget {
  const ProfileAvatar({
    super.key,
    this.picture,
    required this.initial,
    this.radius = 48,
    this.backgroundColor,
    this.foregroundColor,
  });

  final String? picture;
  final String initial;
  final double radius;
  final Color? backgroundColor;
  final Color? foregroundColor;

  @override
  Widget build(BuildContext context) {
    final primary = Theme.of(context).colorScheme.primary;
    final bg = backgroundColor ?? primary.withValues(alpha: 0.15);
    final fg = foregroundColor ?? primary;

    final raw = picture;
    if (raw != null && raw.isNotEmpty) {
      try {
        final encoded = raw.contains(',') ? raw.split(',').last : raw;
        final bytes = base64Decode(encoded);
        return CircleAvatar(
          radius: radius,
          backgroundColor: bg,
          backgroundImage: MemoryImage(bytes),
        );
      } catch (_) {
        // fallback to initial
      }
    }

    return CircleAvatar(
      radius: radius,
      backgroundColor: bg,
      child: Text(
        initial,
        style: TextStyle(
          fontSize: radius * 0.75,
          fontWeight: FontWeight.bold,
          color: fg,
        ),
      ),
    );
  }
}
