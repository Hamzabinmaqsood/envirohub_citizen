import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../data/report_repository.dart';
import '../models/community_report.dart';
import 'community_report_screen.dart';

class FollowingReportsScreen extends StatefulWidget {
  const FollowingReportsScreen({super.key, required this.repository});

  final ReportRepository repository;

  @override
  State<FollowingReportsScreen> createState() => _FollowingReportsScreenState();
}

class _FollowingReportsScreenState extends State<FollowingReportsScreen> {
  late Future<List<CommunityReport>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getFollowingReports();
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _future;
    } catch (_) {
      // FutureBuilder exposes retry on errors.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Following')),
      body: FutureBuilder<List<CommunityReport>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(readableApiError(snapshot.error!)),
                    const SizedBox(height: 12),
                    FilledButton.tonal(
                      onPressed: () => setState(_reload),
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              ),
            );
          }
          final reports = snapshot.data ?? const <CommunityReport>[];
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView.separated(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              itemCount: reports.isEmpty ? 1 : reports.length,
              separatorBuilder: (_, _) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                if (reports.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 100),
                    child: Center(child: Text('Not following any reports yet.\nExplore nearby issues while reporting.', textAlign: TextAlign.center)),
                  );
                }
                final report = reports[index];
                final imageUrl = ApiConfig.resolveMediaUrl(report.thumbnail);
                return Card(
                  child: ListTile(
                    contentPadding: const EdgeInsets.all(12),
                    leading: imageUrl.isEmpty
                        ? const Icon(Icons.image_outlined, size: 44)
                        : ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.network(
                              imageUrl,
                              width: 64,
                              height: 64,
                              fit: BoxFit.cover,
                              errorBuilder: (_, _, _) => const Icon(Icons.broken_image_outlined),
                            ),
                          ),
                    title: Text(report.categoryName),
                    subtitle: Text(
                      '${friendlyStatus(report.status)} • ${report.confirmationCount} confirmations\n${report.description}',
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                    ),
                    isThreeLine: true,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () async {
                      await Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => CommunityReportScreen(
                            repository: widget.repository,
                            reportId: report.id,
                          ),
                        ),
                      );
                      if (mounted) setState(_reload);
                    },
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
