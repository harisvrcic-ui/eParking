import 'dart:convert';

import 'package:http/http.dart' as http;

/// Zajednički parser za ProblemDetails i legacy `{ message }` odgovore API-ja.
class ApiErrorParser {
  static String parseResponse(
    http.Response response, {
    String? fallback,
  }) {
    final raw = response.body.trim();
    if (raw.isEmpty) {
      return fallback ?? _defaultErrorForStatus(response.statusCode);
    }

    try {
      final body = jsonDecode(raw);
      if (body is Map) {
        final parsed = _messageFromJsonMap(body, response.statusCode);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      if (raw.length < 300 && !raw.startsWith('<')) return raw;
    }

    return fallback ?? _defaultErrorForStatus(response.statusCode);
  }

  static String? _messageFromJsonMap(Map body, int statusCode) {
    final detail = body['detail']?.toString().trim();
    if (detail != null && detail.isNotEmpty) return detail;

    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final errors = body['errors'];
    if (errors is Map) {
      final lines = <String>[];
      for (final entry in errors.entries) {
        final value = entry.value;
        if (value is List && value.isNotEmpty) {
          lines.add(value.first.toString());
        } else if (value != null) {
          lines.add(value.toString());
        }
      }
      if (lines.isNotEmpty) return lines.join('\n');
    }

    final title = body['title']?.toString().trim() ?? '';
    if (title.isNotEmpty && !_isGenericProblemTitle(title, statusCode)) {
      return title;
    }

    return null;
  }

  static bool _isGenericProblemTitle(String title, int statusCode) {
    final t = title.toLowerCase();
    return (statusCode == 400 && t == 'bad request') ||
        (statusCode == 401 && t == 'unauthorized') ||
        (statusCode == 403 && t == 'forbidden') ||
        (statusCode == 404 && t == 'not found');
  }

  static String _defaultErrorForStatus(int statusCode) {
    return switch (statusCode) {
      400 => 'Podaci nisu ispravni. Provjerite unos i pokušajte ponovo.',
      401 => 'Niste prijavljeni. Prijavite se ponovo.',
      403 => 'Nemate dozvolu za ovu radnju.',
      404 => 'Traženi zapis nije pronađen.',
      409 => 'Zapis već postoji ili je u konfliktu s drugim podacima.',
      _ => 'Operacija nije uspjela ($statusCode).',
    };
  }
}
