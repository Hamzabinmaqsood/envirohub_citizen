import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/report.dart';

class ReportRepository {
  ReportRepository(this._client);
  final ApiClient _client;

  Future<List<ReportCategory>> getCategories() async {
    final response = await _client.dio.get<List<dynamic>>('categories/');
    return (response.data ?? const [])
        .whereType<Map>()
        .map((e) => ReportCategory.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<List<ReportSummary>> getReports() async {
    final response = await _client.dio.get<dynamic>('reports/');
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
        .map((e) => ReportSummary.fromJson(e.cast<String, dynamic>()))
        .toList();
  }

  Future<ReportDetail> getReport(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>('reports/$id/');
    return ReportDetail.fromJson(response.data ?? const {});
  }

  Future<ReportDetail> createReport({
    required String categorySlug,
    required String description,
    required String address,
    required double latitude,
    required double longitude,
    required List<XFile> images,
  }) async {
    final form = FormData();
    form.fields
      ..add(MapEntry('category', categorySlug))
      ..add(MapEntry('description', description))
      ..add(MapEntry('address', address))
      ..add(MapEntry('latitude', latitude.toString()))
      ..add(MapEntry('longitude', longitude.toString()));

    for (final image in images) {
      form.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ),
      );
    }

    final response = await _client.dio.post<Map<String, dynamic>>(
      'reports/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return ReportDetail.fromJson(response.data ?? const {});
  }
}
