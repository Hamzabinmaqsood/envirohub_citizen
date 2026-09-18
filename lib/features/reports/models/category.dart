class ReportCategory {
  const ReportCategory({required this.id, required this.name, required this.slug, required this.description});

  final int id;
  final String name;
  final String slug;
  final String description;

  factory ReportCategory.fromJson(Map<String, dynamic> json) => ReportCategory(
        id: (json['id'] as num).toInt(),
        name: json['name']?.toString() ?? '',
        slug: json['slug']?.toString() ?? '',
        description: json['description']?.toString() ?? '',
      );
}
