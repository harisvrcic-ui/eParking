class ApiConfig {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://localhost:5126',
  );
  static const String adminLoginPath = '/Auth/admin-login';
}
