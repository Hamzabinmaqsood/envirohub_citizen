import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/storage/token_storage.dart';
import '../models/app_user.dart';

class AuthRepository {
  AuthRepository(this._client, this._storage);

  final ApiClient _client;
  final TokenStorage _storage;

  Future<AppUser> login({required String email, required String password}) async {
    final response = await _client.dio.post<Map<String, dynamic>>(
      'auth/login/',
      data: {'email': email.trim().toLowerCase(), 'password': password},
    );

    final data = response.data ?? const {};
    final access = data['access'] as String?;
    final refresh = data['refresh'] as String?;
    if (access == null || refresh == null) {
      throw StateError('The server did not return authentication tokens.');
    }

    await _storage.saveTokens(access: access, refresh: refresh);
    return me();
  }

  Future<AppUser> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    await _client.dio.post<dynamic>(
      'auth/register/',
      data: {
        'name': name.trim(),
        'email': email.trim().toLowerCase(),
        'phone': phone.trim(),
        'password': password,
      },
    );

    return login(email: email, password: password);
  }

  Future<AppUser> me() async {
    final response = await _client.dio.get<Map<String, dynamic>>('auth/me/');
    return AppUser.fromJson(response.data ?? const {});
  }

  Future<void> logout() async {
    try {
      final refresh = await _storage.readRefreshToken();
      if (refresh != null && refresh.isNotEmpty) {
        await _client.dio.post<dynamic>('auth/logout/', data: {'refresh': refresh});
      }
    } on DioException catch (error) {
      // A 401 (or an offline server) must not trap the user in a local session.
      // If this request fails, server-side refresh-token revocation is NOT guaranteed.
      debugPrint(
        'EnviroHub: Remote logout unavailable '
        '(HTTP ${error.response?.statusCode ?? 'no response'}); clearing local session.',
      );
    } finally {
      await _storage.clear();
    }
  }

  Future<bool> hasSession() async {
    final refresh = await _storage.readRefreshToken();
    return refresh != null && refresh.isNotEmpty;
  }

  Future<void> clearSession() => _storage.clear();
}
