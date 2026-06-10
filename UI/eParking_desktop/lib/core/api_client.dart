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



  String _errorMessage(http.Response response) =>
      ApiErrorParser.parseResponse(response);

}

