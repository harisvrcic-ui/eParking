import '../core/api_client.dart';
import '../models/user_notification.dart';

class UserNotificationService {
  final ApiClient _api = ApiClient();

  Future<List<UserNotification>> getMy({bool? isRead}) async {
    final query = <String, String>{};
    if (isRead != null) {
      query['isRead'] = isRead.toString();
    }
    final data = await _api.getList('/UserNotifications/my', query: query);
    return data
        .map((e) => UserNotification.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<int> unreadCount() async {
    final unread = await getMy(isRead: false);
    return unread.length;
  }

  Future<void> markAsRead(int id) async {
    await _api.put('/UserNotifications/$id/read', {});
  }
}
