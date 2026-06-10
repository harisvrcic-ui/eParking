import 'dart:convert';



import 'package:http/http.dart' as http;



import '../config/api_config.dart';
import 'api_error_parser.dart';



class ApiClient {

  static String? authToken;



  Map<String, String> get _headers => {

        'Content-Type': 'application/json',

        if (authToken != null && authToken!.isNotEmpty) 'Authorization': 'Bearer $authToken',

      };



  Future<dynamic> get(String path, {Map<String, String>? query}) async {

    final uri = Uri.parse('${ApiConfig.baseUrl}$path').replace(queryParameters: query);

    final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return jsonDecode(response.body);

    }

    throw Exception(_errorMessage(response));

  }



  Future<dynamic> post(String path, Map<String, dynamic> body) async {

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http

        .post(uri, headers: _headers, body: jsonEncode(body))

        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {

      if (response.body.isEmpty) return null;

      return jsonDecode(response.body);

    }

    throw Exception(_errorMessage(response));

  }



  Future<dynamic> put(String path, Map<String, dynamic> body) async {

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http

        .put(uri, headers: _headers, body: jsonEncode(body))

        .timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {

      if (response.body.isEmpty) return null;

      return jsonDecode(response.body);

    }

    throw Exception(_errorMessage(response));

  }



  Future<void> delete(String path) async {

    final uri = Uri.parse('${ApiConfig.baseUrl}$path');

    final response = await http.delete(uri, headers: _headers).timeout(const Duration(seconds: 30));

    if (response.statusCode >= 200 && response.statusCode < 300) {

      return;

    }

    throw Exception(_errorMessage(response));

  }



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
      final response = await http.get(uri, headers: _headers).timeout(const Duration(seconds: 30));

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

      if (decoded is Map && decoded['value'] is List) {
        return decoded['value'] as List<dynamic>;
      }

      throw Exception('Unexpected list response');
    }

    return aggregated;
  }



  String _errorMessage(http.Response response) =>
      ApiErrorParser.parseResponse(response);

}

