import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../data/report_repository.dart';
import '../models/report.dart';
import 'report_detail_screen.dart';

class MyReportsScreen extends StatefulWidget {
  const MyReportsScreen({super.key, required this.repository});
  final ReportRepository repository;

  @override
  State<MyReportsScreen> createState() => _MyReportsScreenState();
}

class _MyReportsScreenState extends State<MyReportsScreen> {
  late Future<List<ReportSummary>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getReports();

  Future<void> _refresh() async {
    setState(_reload);
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<ReportSummary>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(readableApiError(snapshot.error!)),
                const SizedBox(height: 12),
                FilledButton.tonal(onPressed: () => setState(_reload), child: const Text('Retry')),
              ]),
            ),
          );
        }
        final reports = snapshot.data ?? const [];
        if (reports.isEmpty) {
          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(children: const [SizedBox(height: 180), Center(child: Text('No reports yet.'))]),
          );
        }

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: reports.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final report = reports[index];
              final imageUrl = ApiConfig.resolveMediaUrl(report.thumbnail);
              return Card(
                child: InkWell(
                  borderRadius: BorderRadius.circular(18),
                  onTap: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ReportDetailScreen(repository: widget.repository, reportId: report.id)),
                    );
                    if (mounted) setState(_reload);
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: imageUrl.isEmpty
                              ? Container(width: 82, height: 82, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.image_outlined))
                              : Image.network(imageUrl, width: 82, height: 82, fit: BoxFit.cover, errorBuilder: (_, __, ___) => const SizedBox(width: 82, height: 82, child: Icon(Icons.broken_image_outlined))),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(child: Text(report.categoryName, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16))),
                                _StatusChip(status: report.status),
                              ]),
                              const SizedBox(height: 5),
                              Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text(formatDateTime(report.createdAt), style: Theme.of(context).textTheme.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer,
        borderRadius: BorderRadius.circular(30),
      ),
      child: Text(friendlyStatus(status), style: Theme.of(context).textTheme.labelSmall),
    );
  }
}
