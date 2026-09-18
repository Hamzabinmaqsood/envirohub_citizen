class WorkerReportImage {
  const WorkerReportImage({
    required this.id,
    required this.url,
    required this.type,
    required this.createdAt,
  });

  final String id;
  final String url;
  final String type;
  final String createdAt;

  factory WorkerReportImage.fromJson(Map<String, dynamic> json) {
    return WorkerReportImage(
      id: json['id']?.toString() ?? '',
      url: json['image']?.toString() ?? '',
      type: json['image_type']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
    );
  }
}

class WorkerTimelineItem {
  const WorkerTimelineItem({
    required this.status,
    required this.note,
    required this.createdAt,
    this.changedBy,
  });

  final String status;
  final String note;
  final String createdAt;
  final String? changedBy;

  factory WorkerTimelineItem.fromJson(Map<String, dynamic> json) {
    return WorkerTimelineItem(
      status: json['status']?.toString() ?? '',
      note: json['note']?.toString() ?? '',
      createdAt: json['created_at']?.toString() ?? '',
      changedBy: json['changed_by_name']?.toString(),
    );
  }
}

class WorkerReport {
  const WorkerReport({
    required this.id,
    required this.categoryName,
    required this.categorySlug,
    required this.description,
    required this.status,
    required this.address,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.citizenName,
    required this.images,
    required this.timeline,
    this.thumbnail,
    this.assignedAt,
    this.startedAt,
    this.resolvedAt,
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
  final String citizenName;
  final String? thumbnail;
  final String? assignedAt;
  final String? startedAt;
  final String? resolvedAt;
  final List<WorkerReportImage> images;
  final List<WorkerTimelineItem> timeline;

  bool get isAssigned => status == 'ASSIGNED';
  bool get isInProgress => status == 'IN_PROGRESS';
  bool get isResolved => status == 'RESOLVED';

  List<WorkerReportImage> get beforeImages =>
      images.where((image) => image.type == 'BEFORE').toList();

  List<WorkerReportImage> get afterImages =>
      images.where((image) => image.type == 'AFTER').toList();

  factory WorkerReport.fromJson(Map<String, dynamic> json) {
    final category =
        (json['category'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};
    final citizen =
        (json['citizen'] as Map?)?.cast<String, dynamic>() ?? const <String, dynamic>{};

    return WorkerReport(
      id: json['id']?.toString() ?? '',
      categoryName: category['name']?.toString() ?? '',
      categorySlug: category['slug']?.toString() ?? '',
      description: json['description']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0,
      createdAt: json['created_at']?.toString() ?? '',
      citizenName: citizen['name']?.toString() ?? 'Citizen',
      thumbnail: json['thumbnail']?.toString(),
      assignedAt: json['assigned_at']?.toString(),
      startedAt: json['started_at']?.toString(),
      resolvedAt: json['resolved_at']?.toString(),
      images: ((json['images'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => WorkerReportImage.fromJson(item.cast<String, dynamic>()))
          .toList(),
      timeline: ((json['timeline'] as List?) ?? const [])
          .whereType<Map>()
          .map((item) => WorkerTimelineItem.fromJson(item.cast<String, dynamic>()))
          .toList(),
    );
  }
}
