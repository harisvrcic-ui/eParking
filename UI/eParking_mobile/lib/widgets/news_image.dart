import 'dart:convert';

import 'package:flutter/material.dart';

Widget newsImage(String? picture, {double height = 120}) {
  if (picture != null && picture.isNotEmpty) {
    try {
      final raw = picture.contains(',') ? picture.split(',').last : picture;
      final bytes = base64Decode(raw);
      return ClipRRect(
        borderRadius: BorderRadius.circular(10),
        child: Image.memory(
          bytes,
          height: height,
          width: double.infinity,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => _placeholder(height),
        ),
      );
    } catch (_) {
      return _placeholder(height);
    }
  }
  return _placeholder(height);
}

Widget _placeholder(double height) {
  return Container(
    height: height,
    width: double.infinity,
    decoration: BoxDecoration(
      color: Colors.grey.shade200,
      borderRadius: BorderRadius.circular(10),
    ),
    child: Icon(Icons.image_outlined, size: height * 0.35, color: Colors.grey.shade500),
  );
}
