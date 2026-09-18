import 'package:flutter/material.dart';

import '../../auth/presentation/auth_controller.dart';
import '../../notifications/data/notification_repository.dart';
import '../../notifications/presentation/notifications_screen.dart';
import '../../reports/data/report_repository.dart';
import '../../reports/presentation/my_reports_screen.dart';
import '../../reports/presentation/report_issue_screen.dart';

class HomeShell extends StatefulWidget {
  const HomeShell({
    super.key,
    required this.authController,
    required this.reportRepository,
    required this.notificationRepository,
  });

  final AuthController authController;
  final ReportRepository reportRepository;
  final NotificationRepository notificationRepository;

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  int _refreshVersion = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _HomeDashboard(
        authController: widget.authController,
        reportRepository: widget.reportRepository,
        onOpenReports: () => setState(() => _index = 1),
        onReportCreated: () => setState(() => _refreshVersion++),
      ),
      MyReportsScreen(key: ValueKey('reports-$_refreshVersion'), repository: widget.reportRepository),
      NotificationsScreen(key: ValueKey('notifications-$_refreshVersion'), repository: widget.notificationRepository, reportRepository: widget.reportRepository),
      _ProfileScreen(authController: widget.authController),
    ];
    const titles = ['Home', 'My reports', 'Notifications', 'Profile'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'Home'),
          NavigationDestination(icon: Icon(Icons.assignment_outlined), selectedIcon: Icon(Icons.assignment), label: 'Reports'),
          NavigationDestination(icon: Icon(Icons.notifications_none), selectedIcon: Icon(Icons.notifications), label: 'Alerts'),
          NavigationDestination(icon: Icon(Icons.person_outline), selectedIcon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}

class _HomeDashboard extends StatelessWidget {
  const _HomeDashboard({
    required this.authController,
    required this.reportRepository,
    required this.onOpenReports,
    required this.onReportCreated,
  });

  final AuthController authController;
  final ReportRepository reportRepository;
  final VoidCallback onOpenReports;
  final VoidCallback onReportCreated;

  @override
  Widget build(BuildContext context) {
    final firstName = authController.user?.name.split(' ').first ?? 'Citizen';
    return ListView(
      padding: const EdgeInsets.all(18),
      children: [
        Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.primaryContainer,
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, $firstName 👋', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 8),
              const Text('Spot an environmental problem? Report it with evidence and track its resolution.'),
              const SizedBox(height: 20),
              FilledButton.icon(
                onPressed: () async {
                  final created = await Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => ReportIssueScreen(repository: reportRepository)),
                  );
                  if (created != null) onReportCreated();
                },
                icon: const Icon(Icons.add_a_photo_outlined),
                label: const Text('Report an issue'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text('Quick actions', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _QuickCard(
                icon: Icons.assignment_outlined,
                title: 'My reports',
                subtitle: 'Track status',
                onTap: onOpenReports,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickCard(
                icon: Icons.recycling_outlined,
                title: 'Impact',
                subtitle: 'Coming next',
                onTap: () => ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Community impact will be added after the core reporting flow.'))),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                Icon(Icons.verified_user_outlined, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 12),
                const Expanded(child: Text('Reports are tied to GPS coordinates and photo evidence to improve accountability.')),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _QuickCard extends StatelessWidget {
  const _QuickCard({required this.icon, required this.title, required this.subtitle, required this.onTap});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 30),
              const SizedBox(height: 16),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProfileScreen extends StatelessWidget {
  const _ProfileScreen({required this.authController});
  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final user = authController.user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(radius: 42, child: Text((user?.name.isNotEmpty == true ? user!.name[0] : 'C').toUpperCase(), style: const TextStyle(fontSize: 28))),
        const SizedBox(height: 14),
        Text(user?.name ?? 'Citizen', textAlign: TextAlign.center, style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
        Text(user?.email ?? '', textAlign: TextAlign.center),
        if (user?.phone.isNotEmpty == true) Text(user!.phone, textAlign: TextAlign.center),
        const SizedBox(height: 28),
        OutlinedButton.icon(
          onPressed: authController.busy ? null : authController.logout,
          icon: const Icon(Icons.logout),
          label: const Text('Sign out'),
        ),
      ],
    );
  }
}
