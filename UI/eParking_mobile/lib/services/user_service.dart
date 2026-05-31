import '../core/api_client.dart';
import '../models/user_profile.dart';

class UserService {
  final ApiClient _api = ApiClient();

  Future<UserProfile> getMyProfile() async {
    final data = await _api.get('/Account/me');
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<UserProfile> updateMyProfile({
    required String username,
    required String firstName,
    required String lastName,
    required String email,
    String? phoneNumber,
    int? genderId,
    int? cityId,
  }) async {
    final data = await _api.put('/Account/me', {
      'username': username,
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'phoneNumber': phoneNumber,
      'genderId': genderId,
      'cityId': cityId,
    });
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }

  Future<void> changeMyPassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    await _api.put('/Account/me/password', {
      'currentPassword': currentPassword,
      'newPassword': newPassword,
    });
  }

  Future<UserProfile> updateProfilePicture(String? pictureBase64) async {
    final data = await _api.put('/Account/me/picture', {
      'picture': pictureBase64,
    });
    return UserProfile.fromJson(data as Map<String, dynamic>);
  }
}
