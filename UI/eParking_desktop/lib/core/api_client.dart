import 'dart:convert';



import 'package:http/http.dart' as http;



import '../config/api_config.dart';



class ApiClient {

  static String? authToken;



  Map<String, String> get _headers => {

        'Content-Type': 'application/json',

        if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',

      };



  Future<List<dynamic>> getList(String path, {Map<String, String>? query}) async {
    const defaultPageSize = 100;
    var page = 1;
    final aggregated = <dynamic>[];

    while (true) {
      final params = {
        ...?query,
        'page': '$page',
        'pageSize': query?['pageSize'] ?? '$defaultPageSize',
      };

      final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: params);
      final response = await http.get(uri, headers: _headers);

      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw Exception(_errorMessage(response));
      }

      final decoded = jsonDecode(response.body);

      if (decoded is List) {
        return decoded;
      }

      if (decoded is Map && decoded['items'] is List) {
        final items = decoded['items'] as List<dynamic>;
        aggregated.addAll(items);

        final totalCount = (decoded['totalCount'] as num?)?.toInt() ?? aggregated.length;
        if (aggregated.length >= totalCount || items.isEmpty) {
          break;
        }
        page++;
        continue;
      }

      throw Exception('Unexpected list response');
    }

    return aggregated;
  }



  Future<Map<String, dynamic>> getById(String path, int id) async {

    final response = await http.get(Uri.parse('${ApiConfig.baseUrl}$path/$id'), headers: _headers);

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return jsonDecode(response.body) as Map<String, dynamic>;

    }

    throw Exception(_errorMessage(response));

  }



  Future<Map<String, dynamic>> post(String path, Map<String, dynamic> body) async {

    final response = await http.post(

      Uri.parse('${ApiConfig.baseUrl}$path'),

      headers: _headers,

      body: jsonEncode(body),

    );

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return jsonDecode(response.body) as Map<String, dynamic>;

    }

    throw Exception(_errorMessage(response));

  }



  Future<Map<String, dynamic>> put(String path, int id, Map<String, dynamic> body) async {

    final response = await http.put(

      Uri.parse('${ApiConfig.baseUrl}$path/$id'),

      headers: _headers,

      body: jsonEncode(body),

    );

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return jsonDecode(response.body) as Map<String, dynamic>;

    }

    throw Exception(_errorMessage(response));

  }



  Future<void> delete(String path, int id) async {

    final response = await http.delete(Uri.parse('${ApiConfig.baseUrl}$path/$id'), headers: _headers);

    if (response.statusCode < 200 || response.statusCode >= 300) {

      throw Exception(_errorMessage(response));

    }

  }



  String _errorMessage(http.Response response) {
    final raw = response.body.trim();
    if (raw.isEmpty) return _defaultErrorForStatus(response.statusCode);

    try {
      final body = jsonDecode(raw);
      if (body is Map) {
        final parsed = _messageFromJsonMap(body, response.statusCode);
        if (parsed != null) return parsed;
      }
    } catch (_) {
      final firstLine = raw.split('\n').first.trim();
      if (firstLine.length < 200 && !firstLine.startsWith('<')) {
        return firstLine;
      }
    }

    return _defaultErrorForStatus(response.statusCode);
  }

  String? _messageFromJsonMap(Map body, int statusCode) {
    final message = body['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;

    final detail = body['detail']?.toString().trim();
    if (detail != null && detail.isNotEmpty) return detail;

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

  bool _isGenericProblemTitle(String title, int statusCode) {
    final t = title.toLowerCase();
    return (statusCode == 400 && t == 'bad request') ||
        (statusCode == 401 && t == 'unauthorized') ||
        (statusCode == 403 && t == 'forbidden') ||
        (statusCode == 404 && t == 'not found');
  }

  String _defaultErrorForStatus(int statusCode) {
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

