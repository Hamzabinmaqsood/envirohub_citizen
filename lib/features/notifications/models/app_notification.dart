class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.isRead,
    required this.createdAt,
    required this.isCommunityReport,
    this.reportId,
  });

  final String id;
  final String title;
  final String message;
  final String type;
  final bool isRead;
  final String createdAt;
  final bool isCommunityReport;
  final String? reportId;

  factory AppNotification.fromJson(Map<String, dynamic> json) => AppNotification(
        id: json['id']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        message: json['message']?.toString() ?? '',
        type: json['notification_type']?.toString() ?? '',
        isRead: json['is_read'] == true,
        createdAt: json['created_at']?.toString() ?? '',
        isCommunityReport: json['is_community_report'] == true,
        reportId: json['report_id']?.toString(),
      );
}
