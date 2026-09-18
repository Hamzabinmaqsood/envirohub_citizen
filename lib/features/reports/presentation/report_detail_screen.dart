import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../data/report_repository.dart';
import '../models/report.dart';

class ReportDetailScreen extends StatelessWidget {
  const ReportDetailScreen({super.key, required this.repository, required this.reportId});

  final ReportRepository repository;
  final String reportId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report details')),
      body: FutureBuilder<ReportDetail>(
        future: repository.getReport(reportId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(readableApiError(snapshot.error!))));
          final report = snapshot.data!;
          final before = report.images.where((e) => e.type == 'BEFORE').toList();
          final after = report.images.where((e) => e.type == 'AFTER').toList();

          return ListView(
            padding: const EdgeInsets.all(18),
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: Text(report.categoryName, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800))),
                  Chip(label: Text(friendlyStatus(report.status))),
                ],
              ),
              Text('ID: ${report.id}', style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 18),
              Text(report.description, style: Theme.of(context).textTheme.bodyLarge),
              const SizedBox(height: 16),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    children: [
                      _InfoRow(icon: Icons.schedule, text: 'Submitted ${formatDateTime(report.createdAt)}'),
                      const SizedBox(height: 8),
                      _InfoRow(icon: Icons.location_on_outlined, text: report.address.isEmpty ? '${report.latitude}, ${report.longitude}' : report.address),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 22),
              _ImageSection(title: 'Before', images: before),
              if (after.isNotEmpty) ...[
                const SizedBox(height: 22),
                _ImageSection(title: 'After / resolution proof', images: after),
              ],
              const SizedBox(height: 24),
              Text('Status timeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
              const SizedBox(height: 12),
              ...report.timeline.map(
                (item) => _TimelineTile(item: item),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ImageSection extends StatelessWidget {
  const _ImageSection({required this.title, required this.images});
  final String title;
  final List<ReportImageItem> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 10),
        if (images.isEmpty)
          const Text('No images available.')
        else
          SizedBox(
            height: 180,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: images.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, index) {
                final url = ApiConfig.resolveMediaUrl(images[index].url);
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.network(
                    url,
                    width: 220,
                    height: 180,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => Container(width: 220, color: Theme.of(context).colorScheme.surfaceContainerHighest, child: const Icon(Icons.broken_image_outlined)),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});
  final ReportTimelineItem item;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(color: Theme.of(context).colorScheme.primaryContainer, shape: BoxShape.circle),
            child: const Icon(Icons.check_rounded, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(friendlyStatus(item.status), style: const TextStyle(fontWeight: FontWeight.w700)),
                if (item.note.isNotEmpty) Text(item.note),
                Text(
                  '${formatDateTime(item.createdAt)}${item.changedBy == null ? '' : ' • ${item.changedBy}'}',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Row(children: [Icon(icon, size: 20), const SizedBox(width: 8), Expanded(child: Text(text))]);
  }
}
