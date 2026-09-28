import 'package:envirohub_citizen/features/notifications/models/app_notification.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppNotification', () {
    test('maps follower report alerts to the community report route', () {
      final notification = AppNotification.fromJson({
        'id': 'notification-1',
        'title': 'Report verified',
        'message': 'A report you follow has been verified.',
        'notification_type': 'REPORT_STATUS',
        'report_id': 'report-1',
        'is_community_report': true,
        'is_read': false,
        'created_at': '2026-09-28T10:00:00Z',
      });

      expect(notification.reportId, 'report-1');
      expect(notification.isCommunityReport, isTrue);
    });

    test('defaults existing owner/general notifications to the private route', () {
      final notification = AppNotification.fromJson({
        'id': 'notification-2',
        'title': 'Report verified',
        'message': 'Your report has been verified.',
        'notification_type': 'REPORT_STATUS',
        'report_id': 'report-2',
        'is_read': true,
        'created_at': '2026-09-28T10:00:00Z',
      });

      expect(notification.isCommunityReport, isFalse);
      expect(notification.isRead, isTrue);
    });
  });
}
