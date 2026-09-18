class ReportSummary {
  const ReportSummary({
    required this.id,
    required this.categoryName,
    required this.categorySlug,
    required this.description,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    this.thumbnail,
  });

  final String id;
  final String categoryName;
  final String categorySlug;
  final String description;
  final String status;
  final String address;
  final double latitude;
  final double longitude;
  final String createdAt;
  final String? thumbnail;

  factory ReportSummary.fromJson(Map<String, dynamic> json) {
    final category = (json['category'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    return ReportSummary(
      id: json['id']?.toString() ?? '',
      categoryName: category['name']?.toString() ?? '',
      categorySlug: category['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      thumbnail: json['thumbnail']?.toString(),
    );
  }
}

class ReportImageItem {
  const ReportImageItem({required this.id, required this.url, required this.type, required this.createdAt});
  final String id;
  final String url;
  final String type;
  final String createdAt;

  factory ReportImageItem.fromJson(Map<String, dynamic> json) => ReportImageItem(
        id: json['id']?.toString() ?? '',
        url: json['image']?.toString() ?? '',
        type: json['image_type']?.toString() ?? '',
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class ReportTimelineItem {
  const ReportTimelineItem({required this.status, required this.note, required this.changedBy, required this.createdAt});
  final String status;
  final String note;
  final String? changedBy;
  final String createdAt;

  factory ReportTimelineItem.fromJson(Map<String, dynamic> json) => ReportTimelineItem(
        status: json['status']?.toString() ?? '',
        note: json['note']?.toString() ?? '',
        changedBy: json['changed_by_name']?.toString(),
        createdAt: json['created_at']?.toString() ?? '',
      );
}

class ReportDetail extends ReportSummary {
  const ReportDetail({
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
    required this.timeline,
    this.resolvedAt,
  });

  final List<ReportImageItem> images;
  final List<ReportTimelineItem> timeline;
  final String? resolvedAt;

  factory ReportDetail.fromJson(Map<String, dynamic> json) {
    final summary = ReportSummary.fromJson(json);
    return ReportDetail(
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
          .map((e) => ReportImageItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      timeline: ((json['timeline'] as List?) ?? const [])
          .whereType<Map>()
          .map((e) => ReportTimelineItem.fromJson(e.cast<String, dynamic>()))
          .toList(),
      resolvedAt: json['resolved_at']?.toString(),
    );
  }
}
