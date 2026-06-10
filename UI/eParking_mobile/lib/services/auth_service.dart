import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config/api_config.dart';
import '../core/api_client.dart';
import '../core/api_error_parser.dart';
import '../models/login_response.dart';

class ForgotPasswordResult {
  ForgotPasswordResult({required this.message, this.devResetCode});

  final String message;
  final String? devResetCode;
}

class AuthService {
  static LoginResponse? currentUser;

  Future<LoginResponse> login({
    required String username,
    required String password,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}${ApiConfig.loginPath}');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final user = LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      currentUser = user;
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

  Future<LoginResponse> register({
    required String username,
    required String password,
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    int? genderId,
    int? cityId,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Auth/register');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username.trim(),
        'password': password,
        'firstName': firstName.trim(),
        'lastName': lastName.trim(),
        'email': email.trim(),
        if (phoneNumber != null && phoneNumber.trim().isNotEmpty)
          'phoneNumber': phoneNumber.trim(),
        if (genderId != null) 'genderId': genderId,
        if (cityId != null) 'cityId': cityId,
      }),
    );

    if (response.statusCode == 200) {
      final user = LoginResponse.fromJson(
        jsonDecode(response.body) as Map<String, dynamic>,
      );
      currentUser = user;
      ApiClient.authToken = user.token;
      return user;
    }

    throw Exception(
      ApiErrorParser.parseResponse(
        response,
        fallback: 'Registracija nije uspjela.',
      ),
    );
  }

  Future<ForgotPasswordResult> forgotPassword({required String email}) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Auth/forgot-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email.trim()}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return ForgotPasswordResult(
        message: body['message'] as String? ?? 'Provjerite e-mail.',
        devResetCode: body['devResetCode'] as String?,
      );
    }

    throw Exception(ApiErrorParser.parseResponse(response));
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/Auth/reset-password');
    final response = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email.trim(),
        'code': code.trim(),
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode == 204) return;
    throw Exception(ApiErrorParser.parseResponse(response));
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
      currentUser = null;
      ApiClient.authToken = null;
    }
  }
}
