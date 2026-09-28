class NearbyReport {
  const NearbyReport({
    required this.id,
    required this.categoryName,
    required this.categorySlug,
    required this.status,
    required this.distanceM,
    required this.createdAt,
    this.confirmationCount = 0,
    this.followerCount = 0,
    this.isConfirmed = false,
    this.isFollowing = false,
  });

  final String id;
  final String categoryName;
  final String categorySlug;
  final String status;
  final int distanceM;
  final String createdAt;
  final int confirmationCount;
  final int followerCount;
  final bool isConfirmed;
  final bool isFollowing;

  factory NearbyReport.fromJson(Map<String, dynamic> json) {
    final category =
        (json['category'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return NearbyReport(
      id: json['id']?.toString() ?? '',
      categoryName: category['name']?.toString() ?? '',
      categorySlug: category['slug']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      distanceM: (json['distance_m'] as num?)?.round() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      confirmationCount: (json['confirmation_count'] as num?)?.toInt() ?? 0,
      followerCount: (json['follower_count'] as num?)?.toInt() ?? 0,
      isConfirmed: json['is_confirmed'] == true,
      isFollowing: json['is_following'] == true,
    );
  }
}
