import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../../core/services/push_notification_service.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(
    this._repository, {
    PushNotificationService? pushNotifications,
  }) : _pushNotifications = pushNotifications;

  final AuthRepository _repository;
  final PushNotificationService? _pushNotifications;

  AuthStatus status = AuthStatus.checking;
  AppUser? user;
  String? error;
  bool busy = false;

  void _syncPushInBackground() {
    final service = _pushNotifications;
    if (service != null) unawaited(service.syncCurrentInstallation());
  }

  Future<void> bootstrap() async {
    status = AuthStatus.checking;
    if (!await _repository.hasSession()) {
      status = AuthStatus.unauthenticated;
      return;
    }

    try {
      user = await _repository.me();
      status = AuthStatus.authenticated;
      _syncPushInBackground();
    } catch (_) {
      await _repository.clearSession();
      status = AuthStatus.unauthenticated;
      user = null;
    }
  }

  Future<bool> login({required String email, required String password}) async {
    return _run(() async {
      user = await _repository.login(email: email, password: password);
      status = AuthStatus.authenticated;
      _syncPushInBackground();
    });
  }

  Future<bool> register({
    required String name,
    required String email,
    required String phone,
    required String password,
  }) async {
    return _run(() async {
      user = await _repository.register(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );
      status = AuthStatus.authenticated;
      _syncPushInBackground();
    });
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();
    try {
      // Unregister while the access token is still available. Remote cleanup
      // must not prevent local logout if Firebase or the API is unavailable.
      try {
        await _pushNotifications?.unregisterCurrentInstallation();
      } catch (error) {
        debugPrint('EnviroHub: Push unregister skipped: $error');
      }
      await _repository.logout();
    } catch (error) {
      debugPrint('EnviroHub: Logout cleanup failed: $error');
      try {
        await _repository.clearSession();
      } catch (clearError) {
        debugPrint('EnviroHub: Local session cleanup failed: $clearError');
      }
    } finally {
      user = null;
      error = null;
      busy = false;
      status = AuthStatus.unauthenticated;
      notifyListeners();
    }
  }

  Future<bool> _run(Future<void> Function() action) async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await action();
      return true;
    } catch (e) {
      error = readableApiError(e);
      return false;
    } finally {
      busy = false;
      notifyListeners();
    }
  }
}
