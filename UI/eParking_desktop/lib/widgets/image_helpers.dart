import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

/// Bira sliku vozila (max prikaz ~80px — ispod 50% forme).
Future<String?> pickImageBase64() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.image,
    withData: true,
  );
  if (result == null || result.files.isEmpty) return null;
  final bytes = result.files.single.bytes;
  if (bytes == null || bytes.isEmpty) return null;
  return base64Encode(bytes);
}

Widget carThumbnail(String? picture, {double size = 44}) {
  if (picture != null && picture.isNotEmpty) {
    try {
      final raw = picture.contains(',') ? picture.split(',').last : picture;
      final bytes = base64Decode(raw);
      return ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.memory(
          bytes,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(size),
        ),
      );
    } catch (_) {
      return _placeholder(size);
    }
  }
  return _placeholder(size);
}

Widget _placeholder(double size) {
  return Container(
    width: size,
    height: size,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(8),
    ),
    child: Icon(Icons.directions_car, size: size * 0.55, color: Colors.grey.shade600),
  );
}

/// Kompaktan preview slike na formi (≤80px visine).
Widget formImagePreview({
  required String? pictureBase64,
  required VoidCallback onPick,
  VoidCallback? onClear,
}) {
  return Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Row(
      children: [
        carThumbnail(pictureBase64, size: 64),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Slika vozila', style: TextStyle(fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: [
                  OutlinedButton.icon(
                    onPressed: onPick,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: const Text('Odaberi sliku'),
                  ),
                  if (pictureBase64 != null && onClear != null)
                    TextButton(onPressed: onClear, child: const Text('Ukloni')),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}
