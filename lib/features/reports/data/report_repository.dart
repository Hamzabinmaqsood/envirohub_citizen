import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/category.dart';
import '../models/community_report.dart';
import '../models/nearby_report.dart';
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

  Future<List<NearbyReport>> getNearbyReports({
    required double latitude,
    required double longitude,
    int radiusM = 200,
    String? categorySlug,
  }) async {
    final response = await _client.dio.get<List<dynamic>>(
      'reports/nearby/',
      queryParameters: {
        'latitude': latitude,
        'longitude': longitude,
        'radius_m': radiusM,
        if (categorySlug != null && categorySlug.isNotEmpty) 'category': categorySlug,
      },
    );
    return (response.data ?? const [])
        .whereType<Map>()
        .map((item) => NearbyReport.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<CommunityReport> getCommunityReport(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>(
      'reports/$id/community/',
    );
    return CommunityReport.fromJson(response.data ?? const {});
  }

  Future<List<CommunityReport>> getFollowingReports() async {
    // The Django list endpoint is paginated. Load all pages so a citizen's
    // older follows aren't hidden after the first page.
    final reports = <CommunityReport>[];
    final visited = <String>{};
    String? next = 'reports/following/';
    while (next != null && visited.add(next)) {
      final response = await _client.dio.get<dynamic>(next);
      final data = response.data;
      final List<dynamic> rows;
      if (data is Map<String, dynamic>) {
        rows = (data['results'] as List?) ?? const [];
        final nextPage = data['next']?.toString();
        next = nextPage == null || nextPage.isEmpty ? null : nextPage;
      } else if (data is List) {
        rows = data;
        next = null;
      } else {
        rows = const [];
        next = null;
      }
      reports.addAll(rows
          .whereType<Map>()
          .map((item) => CommunityReport.fromJson(item.cast<String, dynamic>())));
    }
    return reports;
  }

  Future<CommunityReport> setConfirmation(String id, {required bool confirmed}) async {
    final path = 'reports/$id/confirm/';
    final response = confirmed
        ? await _client.dio.post<Map<String, dynamic>>(path)
        : await _client.dio.delete<Map<String, dynamic>>(path);
    return CommunityReport.fromJson(response.data ?? const {});
  }

  Future<CommunityReport> setFollowing(String id, {required bool following}) async {
    final path = 'reports/$id/follow/';
    final response = following
        ? await _client.dio.post<Map<String, dynamic>>(path)
        : await _client.dio.delete<Map<String, dynamic>>(path);
    return CommunityReport.fromJson(response.data ?? const {});
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
