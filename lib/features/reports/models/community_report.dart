import 'report.dart';

/// A public, identity-safe view of a report. The backend intentionally omits
/// the citizen's identity and private authority timeline/assignment fields.
class CommunityReport extends ReportSummary {
  const CommunityReport({
    required super.id,
    required super.categoryName,
    required super.categorySlug,
    required super.description,
    required super.status,
    required super.address,
    required super.latitude,
    required super.longitude,
    required super.createdAt,
    super.thumbnail,
    required this.images,
    required this.confirmationCount,
    required this.followerCount,
    required this.isConfirmed,
    required this.isFollowing,
  });

  final List<ReportImageItem> images;
  final int confirmationCount;
  final int followerCount;
  final bool isConfirmed;
  final bool isFollowing;

  bool get isClosed => status == 'RESOLVED' || status == 'REJECTED';

  factory CommunityReport.fromJson(Map<String, dynamic> json) {
    final summary = ReportSummary.fromJson(json);
    return CommunityReport(
      id: summary.id,
      categoryName: summary.categoryName,
      categorySlug: summary.categorySlug,
      description: summary.description,
      status: summary.status,
      address: summary.address,
      latitude: summary.latitude,
      longitude: summary.longitude,
      createdAt: summary.createdAt,
      thumbnail: summary.thumbnail,
      images: ((json['images'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => ReportImageItem.fromJson(item.cast<String, dynamic>()))
          .toList(),
      confirmationCount: (json['confirmation_count'] as num?)?.toInt() ?? 0,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      isConfirmed: json['is_confirmed'] == true,
      isFollowing: json['is_following'] == true,
    );
  }
}
