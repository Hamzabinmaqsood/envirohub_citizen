import 'package:flutter/material.dart';

import 'core/network/api_client.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/presentation/auth_controller.dart';
import 'features/auth/presentation/login_screen.dart';
import 'features/home/presentation/home_shell.dart';
import 'features/notifications/data/notification_repository.dart';
import 'features/reports/data/report_repository.dart';
import 'features/worker/data/worker_repository.dart';
import 'features/worker/presentation/worker_shell.dart';

class EnviroHubApp extends StatelessWidget {
  const EnviroHubApp({
    super.key,
    required this.apiClient,
    required this.authController,
  });

  final ApiClient apiClient;
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final reportRepository = ReportRepository(apiClient);
    final notificationRepository = NotificationRepository(apiClient);
    final workerRepository = WorkerRepository(apiClient);

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'EnviroHub',
      theme: AppTheme.light,
      home: AnimatedBuilder(
        animation: authController,
        builder: (context, _) {
          switch (authController.status) {
            case AuthStatus.checking:
              return const _SplashScreen();
            case AuthStatus.authenticated:
              final user = authController.user;
              if (user?.isWorker == true) {
                return WorkerShell(
                  authController: authController,
                  repository: workerRepository,
                );
              }
              if (user?.isAuthority == true) {
                return _AuthorityMobileNotice(authController: authController);
              }
              return HomeShell(
                authController: authController,
                reportRepository: reportRepository,
                notificationRepository: notificationRepository,
              );
            case AuthStatus.unauthenticated:
              return LoginScreen(authController: authController);
          }
        },
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.eco_rounded, size: 72),
            SizedBox(height: 16),
            Text('EnviroHub', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            SizedBox(height: 24),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}

class _AuthorityMobileNotice extends StatelessWidget {
  const _AuthorityMobileNotice({required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Authority account')),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 460),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.admin_panel_settings_outlined, size: 72, color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 18),
                Text(
                  'Authority dashboard is web-first for now',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Use the web authority tools for verification and assignment. The mobile authority dashboard will be added later.',
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: authController.busy ? null : authController.logout,
                  icon: const Icon(Icons.logout),
                  label: const Text('Sign out'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
