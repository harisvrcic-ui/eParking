class UserProfile {
  final int id;
  final String username;
  final String firstName;
  final String lastName;
  final String email;
  final String? phoneNumber;
  final int? genderId;
  final String? genderName;
  final int? cityId;
  final String? cityName;
  final bool isActive;
  final bool isAdmin;
  final bool isUser;
  final String? picture;

  UserProfile({
    required this.id,
    required this.username,
    required this.firstName,
    required this.lastName,
    required this.email,
    this.phoneNumber,
    this.genderId,
    this.genderName,
    this.cityId,
    this.cityName,
    required this.isActive,
    required this.isAdmin,
    required this.isUser,
    this.picture,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      username: json['username'] as String? ?? '',
      firstName: json['firstName'] as String? ?? '',
      lastName: json['lastName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      phoneNumber: json['phoneNumber'] as String?,
      genderId: json['genderId'] as int?,
      genderName: json['genderName'] as String?,
      cityId: json['cityId'] as int?,
      cityName: json['cityName'] as String?,
      isActive: json['isActive'] as bool? ?? true,
      isAdmin: json['isAdmin'] as bool? ?? false,
      isUser: json['isUser'] as bool? ?? true,
      picture: json['picture'] as String?,
    );
  }

  String get fullName => '$firstName $lastName'.trim();
}
