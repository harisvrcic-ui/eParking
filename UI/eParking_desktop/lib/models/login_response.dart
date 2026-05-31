class LoginResponse {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final bool isAdmin;
  final bool isUser;
  final String token;

  LoginResponse({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.isAdmin,
    required this.isUser,
    required this.token,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      id: json['id'] as int,
      username: json['username'] as String,
      firstName: json['firstName'] as String,
      lastName: json['lastName'] as String,
      email: json['email'] as String,
      isAdmin: json['isAdmin'] as bool,
      isUser: json['isUser'] as bool,
      token: json['token'] as String? ?? '',
    );
  }
}
