import '../../../core/network/api_client.dart';
import '../models/app_notification.dart';

class NotificationRepository {
  NotificationRepository(this._client);
  final ApiClient _client;

  Future<List<AppNotification>> getNotifications() async {
    final response = await _client.dio.get<dynamic>('notifications/');
    final data = response.data;
    final List<dynamic> rows;
    if (data is Map<String, dynamic>) {
      rows = (data['results'] as List?) ?? const [];
    } else if (data is List) {
      rows = data;
    } else {
      rows = const [];
    }
    return rows
        .whereType<Map>()
        .map((e) => AppNotification.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<void> markRead(String id) => _client.dio.patch<dynamic>('notifications/$id/read/');
  Future<void> markAllRead() => _client.dio.patch<dynamic>('notifications/read-all/');
}
