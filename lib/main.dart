import 'package:flutter/material.dart';

import 'app.dart';
import 'core/network/api_client.dart';
import 'core/services/push_notification_service.dart';
import 'core/storage/token_storage.dart';
import 'features/auth/data/auth_repository.dart';
import 'features/auth/presentation/auth_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  const tokenStorage = TokenStorage();
  final apiClient = ApiClient(tokenStorage);
  final pushNotifications = PushNotificationService(apiClient);
  await pushNotifications.initialize();

  final authRepository = AuthRepository(apiClient, tokenStorage);
  final authController = AuthController(
    authRepository,
    pushNotifications: pushNotifications,
  );

  await authController.bootstrap();

  runApp(
    EnviroHubApp(
      apiClient: apiClient,
      authController: authController,
    ),
  );
}
