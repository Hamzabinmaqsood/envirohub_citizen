import 'package:dio/dio.dart';

import '../config/api_config.dart';
import '../storage/token_storage.dart';

class ApiClient {
  ApiClient(this._tokenStorage) {
    dio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 30),
        sendTimeout: const Duration(seconds: 60),
        headers: {'Accept': 'application/json'},
      ),
    );

    _refreshDio = Dio(
      BaseOptions(
        baseUrl: ApiConfig.baseUrl,
        connectTimeout: const Duration(seconds: 20),
        receiveTimeout: const Duration(seconds: 20),
        headers: {'Accept': 'application/json'},
      ),
    );

    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          final access = await _tokenStorage.readAccessToken();
          if (access != null && access.isNotEmpty) {
            options.headers['Authorization'] = 'Bearer $access';
          }
          handler.next(options);
        },
        onError: (error, handler) async {
          final options = error.requestOptions;
          final isUnauthorized = error.response?.statusCode == 401;
          final alreadyRetried = options.extra['retried'] == true;
          final isAuthEndpoint = options.path.contains('auth/login') ||
              options.path.contains('auth/register') ||
              options.path.contains('auth/refresh');

          if (!isUnauthorized || alreadyRetried || isAuthEndpoint) {
            handler.next(error);
            return;
          }

          final refresh = await _tokenStorage.readRefreshToken();
          if (refresh == null || refresh.isEmpty) {
            handler.next(error);
            return;
          }

          try {
            final refreshResponse = await _refreshDio.post<Map<String, dynamic>>(
              'auth/refresh/',
              data: {'refresh': refresh},
            );
            final newAccess = refreshResponse.data?['access'] as String?;
            if (newAccess == null || newAccess.isEmpty) {
              await _tokenStorage.clear();
              handler.next(error);
              return;
            }

            await _tokenStorage.saveAccessToken(newAccess);
            options.headers['Authorization'] = 'Bearer $newAccess';
            options.extra['retried'] = true;

            final response = await dio.fetch<dynamic>(options);
            handler.resolve(response);
          } catch (_) {
            await _tokenStorage.clear();
            handler.next(error);
          }
        },
      ),
    );
  }

  final TokenStorage _tokenStorage;
  late final Dio dio;
  late final Dio _refreshDio;
}

String readableApiError(Object error) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map<String, dynamic>) {
      if (data['detail'] != null) return data['detail'].toString();
      final messages = <String>[];
      for (final entry in data.entries) {
        final value = entry.value;
        if (value is List) {
          messages.add('${entry.key}: ${value.join(', ')}');
        } else {
          messages.add('${entry.key}: $value');
        }
      }
      if (messages.isNotEmpty) return messages.join('\n');
    }
    if (data is String && data.isNotEmpty) return data;
    if (error.type == DioExceptionType.connectionError ||
        error.type == DioExceptionType.connectionTimeout) {
      return 'Cannot connect to the EnviroHub server.';
    }
    return 'Request failed (${error.response?.statusCode ?? 'network error'}).';
  }
  return error.toString();
}
