import 'package:dio/dio.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../models/worker_report.dart';

class WorkerRepository {
  WorkerRepository(this._client);

  final ApiClient _client;

  Future<List<WorkerReport>> getReports({String? status}) async {
    final response = await _client.dio.get<dynamic>(
      'worker/reports/',
      queryParameters: status == null ? null : {'status': status},
    );

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
        .map((item) => WorkerReport.fromJson(item.cast<String, dynamic>()))
        .toList();
  }

  Future<WorkerReport> getReport(String id) async {
    final response = await _client.dio.get<Map<String, dynamic>>('worker/reports/$id/');
    return WorkerReport.fromJson(response.data ?? const {});
  }

  Future<WorkerReport> startJob(String id, {String note = ''}) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'worker/reports/$id/start/',
      data: {'note': note},
    );
    return WorkerReport.fromJson(response.data ?? const {});
  }

  Future<WorkerReport> resolveJob({
    required String id,
    required List<XFile> images,
    String note = '',
  }) async {
    final form = FormData();
    form.fields.add(MapEntry('note', note));

    for (final image in images) {
      form.files.add(
        MapEntry(
          'images',
          await MultipartFile.fromFile(image.path, filename: image.name),
        ),
      );
    }

    final response = await _client.dio.post<Map<String, dynamic>>(
      'worker/reports/$id/resolve/',
      data: form,
      options: Options(contentType: 'multipart/form-data'),
    );
    return WorkerReport.fromJson(response.data ?? const {});
  }
}
