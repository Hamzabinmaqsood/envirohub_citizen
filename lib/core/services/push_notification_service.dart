import 'dart:async';

import 'package:firebase_app_installations/firebase_app_installations.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../../firebase_options.dart';
import '../network/api_client.dart';

class PushNotificationService {
  PushNotificationService(this._apiClient);

  final ApiClient _apiClient;
  StreamSubscription<String>? _tokenRefreshSubscription;
  bool _firebaseReady = false;

  bool get isFirebaseReady => _firebaseReady;

  Future<void> initialize() async {
    try {
      debugPrint('EnviroHub: Initializing Firebase...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 30));
      _firebaseReady = true;
      debugPrint('EnviroHub: Firebase initialized successfully');
      _tokenRefreshSubscription = FirebaseMessaging.instance.onTokenRefresh.listen(
        (_) => syncCurrentInstallation(),
      );
    } catch (error, stackTrace) {
      // Firebase stays optional; the rest of EnviroHub must keep working.
      debugPrint('EnviroHub: Firebase initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);
      _firebaseReady = false;
    }
  }

  Future<void> syncCurrentInstallation() async {
    if (!_firebaseReady) return;
    try {
      await FirebaseMessaging.instance
          .requestPermission(alert: true, badge: true, sound: true)
          .timeout(const Duration(seconds: 8));

      // A Firebase Installation ID alone is not a usable FCM token target in
      // this FlutterFire flow. Do not register an installation without a token.
      final fcmToken = await FirebaseMessaging.instance
          .getToken()
          .timeout(const Duration(seconds: 20));
      if (fcmToken == null || fcmToken.isEmpty) {
        debugPrint('EnviroHub: FCM token unavailable; device not registered');
        return;
      }

      final fid = await FirebaseInstallations.instance
          .getId()
          .timeout(const Duration(seconds: 10));
      if (fid.isEmpty) return;

      await _apiClient.dio.post<Map<String, dynamic>>(
        'notification-devices/',
        data: {
          'firebase_installation_id': fid,
          'fcm_registration_token': fcmToken,
          'platform': _platformName(),
        },
      );
      // Never print FCM registration tokens in application logs.
      debugPrint('EnviroHub: Push device registered with Django');
    } catch (error) {
      debugPrint('Could not register push installation: $error');
    }
  }

  Future<void> unregisterCurrentInstallation() async {
    if (!_firebaseReady) return;
    try {
      final fid = await FirebaseInstallations.instance
          .getId()
          .timeout(const Duration(seconds: 5));
      if (fid.isEmpty) return;
      await _apiClient.dio.post<Map<String, dynamic>>(
        'notification-devices/unregister/',
        data: {'firebase_installation_id': fid},
      );
    } catch (error) {
      debugPrint('Could not unregister push installation: $error');
    }
  }

  String _platformName() {
    if (kIsWeb) return 'WEB';
    return switch (defaultTargetPlatform) {
      TargetPlatform.android => 'ANDROID',
      TargetPlatform.iOS => 'IOS',
      _ => 'OTHER',
    };
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
  }
}
