import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../auth/presentation/auth_controller.dart';
import '../data/worker_repository.dart';
import '../models/worker_report.dart';
import 'worker_job_detail_screen.dart';

class WorkerShell extends StatefulWidget {
  const WorkerShell({
    super.key,
    required this.authController,
    required this.repository,
  });

  final AuthController authController;
  final WorkerRepository repository;

  @override
  State<WorkerShell> createState() => _WorkerShellState();
}

class _WorkerShellState extends State<WorkerShell> {
  int _index = 0;
  int _refreshVersion = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      _WorkerJobsPage(
        key: ValueKey('active-$_refreshVersion'),
        repository: widget.repository,
        completed: false,
        onChanged: () => setState(() => _refreshVersion++),
      ),
      _WorkerJobsPage(
        key: ValueKey('completed-$_refreshVersion'),
        repository: widget.repository,
        completed: true,
        onChanged: () => setState(() => _refreshVersion++),
      ),
      _WorkerProfile(authController: widget.authController),
    ];

    const titles = ['Assigned jobs', 'Completed jobs', 'Worker profile'];

    return Scaffold(
      appBar: AppBar(title: Text(titles[_index])),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.work_outline),
            selectedIcon: Icon(Icons.work),
            label: 'Jobs',
          ),
          NavigationDestination(
            icon: Icon(Icons.task_alt_outlined),
            selectedIcon: Icon(Icons.task_alt),
            label: 'Completed',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}

class _WorkerJobsPage extends StatefulWidget {
  const _WorkerJobsPage({
    super.key,
    required this.repository,
    required this.completed,
    required this.onChanged,
  });

  final WorkerRepository repository;
  final bool completed;
  final VoidCallback onChanged;

  @override
  State<_WorkerJobsPage> createState() => _WorkerJobsPageState();
}

class _WorkerJobsPageState extends State<_WorkerJobsPage> {
  List<WorkerReport> _jobs = const [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final all = await widget.repository.getReports(
        status: widget.completed ? 'RESOLVED' : null,
      );
      final jobs = widget.completed
          ? all
          : all.where((job) => !job.isResolved).toList();
      if (!mounted) return;
      setState(() => _jobs = jobs);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = readableApiError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openJob(WorkerReport job) async {
    final changed = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => WorkerJobDetailScreen(
          repository: widget.repository,
          reportId: job.id,
        ),
      ),
    );
    if (changed == true) {
      widget.onChanged();
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) return const Center(child: CircularProgressIndicator());

    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_outlined, size: 44),
              const SizedBox(height: 12),
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 14),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    if (_jobs.isEmpty) {
      return RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(height: MediaQuery.sizeOf(context).height * 0.22),
            Icon(
              widget.completed ? Icons.task_alt_rounded : Icons.inbox_outlined,
              size: 68,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(height: 14),
            Text(
              widget.completed ? 'No completed jobs yet' : 'No assigned jobs right now',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 8),
            Text(
              widget.completed
                  ? 'Resolved jobs will appear here.'
                  : 'Pull down to check for new assignments.',
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _jobs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) => _WorkerJobCard(
          report: _jobs[index],
          onTap: () => _openJob(_jobs[index]),
        ),
      ),
    );
  }
}

class _WorkerJobCard extends StatelessWidget {
  const _WorkerJobCard({required this.report, required this.onTap});

  final WorkerReport report;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final thumbnail = ApiConfig.resolveMediaUrl(report.thumbnail);

    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(14),
                child: thumbnail.isEmpty
                    ? Container(
                        width: 84,
                        height: 84,
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_outlined),
                      )
                    : Image.network(
                        thumbnail,
                        width: 84,
                        height: 84,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          width: 84,
                          height: 84,
                          color: Theme.of(context).colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            report.categoryName,
                            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16),
                          ),
                        ),
                        _StatusBadge(status: report.status),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      report.description.isEmpty ? 'No description' : report.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Icon(Icons.person_outline, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            report.citizenName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined, size: 16),
                        const SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            report.address.isEmpty
                                ? '${report.latitude.toStringAsFixed(5)}, ${report.longitude.toStringAsFixed(5)}'
                                : report.address,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final inProgress = status == 'IN_PROGRESS';
    final resolved = status == 'RESOLVED';
    final background = resolved
        ? scheme.primaryContainer
        : inProgress
            ? scheme.tertiaryContainer
            : scheme.secondaryContainer;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(999)),
      child: Text(
        friendlyStatus(status),
        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _WorkerProfile extends StatelessWidget {
  const _WorkerProfile({required this.authController});

  final AuthController authController;

  @override
  Widget build(BuildContext context) {
    final user = authController.user;
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        CircleAvatar(
          radius: 42,
          child: Text(
            (user?.name.isNotEmpty == true ? user!.name[0] : 'W').toUpperCase(),
            style: const TextStyle(fontSize: 28),
          ),
        ),
        const SizedBox(height: 14),
        Text(
          user?.name ?? 'Worker',
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
        ),
        Text(user?.email ?? '', textAlign: TextAlign.center),
        if (user?.phone.isNotEmpty == true) Text(user!.phone, textAlign: TextAlign.center),
        const SizedBox(height: 10),
        const Center(child: Chip(label: Text('FIELD WORKER'))),
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
