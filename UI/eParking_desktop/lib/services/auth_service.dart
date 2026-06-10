import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/api_client.dart';
import '../core/api_error_parser.dart';
import '../models/login_response.dart';

class AuthService {
  Future<LoginResponse> adminLogin({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.adminLoginPath}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final user = LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      ApiClient.authToken = user.token;
      return user;
    }

    throw Exception(
      ApiErrorParser.parseResponse(
        response,
        fallback: 'Prijava nije uspjela.',
      ),
    );
  }

  static Future<void> logout() async {
    try {
      final uri = Uri.parse('${ApiConfig.baseUrl}/Auth/logout');
      await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (ApiClient.authToken != null && ApiClient.authToken!.isNotEmpty)
            'Authorization': 'Bearer ${ApiClient.authToken}',
        },
      );
    } catch (_) {
      // Lokalna sesija se i dalje briše.
    } finally {
      ApiClient.authToken = null;
    }
  }
}
