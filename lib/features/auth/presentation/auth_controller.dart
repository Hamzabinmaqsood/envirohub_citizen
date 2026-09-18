import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../data/auth_repository.dart';
import '../models/app_user.dart';

enum AuthStatus { checking, authenticated, unauthenticated }

class AuthController extends ChangeNotifier {
  AuthController(this._repository);

  final AuthRepository _repository;

  AuthStatus status = AuthStatus.checking;
  AppUser? user;
  String? error;
  bool busy = false;

  Future<void> bootstrap() async {
    status = AuthStatus.checking;
    if (!await _repository.hasSession()) {
      status = AuthStatus.unauthenticated;
      return;
    }

    try {
      user = await _repository.me();
      status = AuthStatus.authenticated;
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
    });
  }

  Future<void> logout() async {
    busy = true;
    notifyListeners();
    try {
      await _repository.logout();
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
