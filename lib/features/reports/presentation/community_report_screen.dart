import 'package:flutter/material.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/location_map_card.dart';
import '../data/report_repository.dart';
import '../models/community_report.dart';
import '../models/report.dart';

/// This screen uses /community/, never the owner's private /reports/{id}/ view.
class CommunityReportScreen extends StatefulWidget {
  const CommunityReportScreen({
    super.key,
    required this.repository,
    required this.reportId,
  });

  final ReportRepository repository;
  final String reportId;

  @override
  State<CommunityReportScreen> createState() => _CommunityReportScreenState();
}

class _CommunityReportScreenState extends State<CommunityReportScreen> {
  late Future<CommunityReport> _future;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() {
    _future = widget.repository.getCommunityReport(widget.reportId);
  }

  Future<void> _refresh() async {
    setState(_reload);
    try {
      await _future;
    } catch (_) {
      // FutureBuilder presents the API error and Retry action.
    }
  }

  Future<void> _change({
    required bool confirmation,
    required bool newValue,
  }) async {
    if (_saving) return;
    setState(() => _saving = true);
    try {
      final updated = confirmation
          ? await widget.repository.setConfirmation(widget.reportId, confirmed: newValue)
          : await widget.repository.setFollowing(widget.reportId, following: newValue);
      if (!mounted) return;
      setState(() {
        _future = Future.value(updated);
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(confirmation
              ? (newValue ? 'You confirmed this issue.' : 'Confirmation withdrawn.')
              : (newValue ? 'Report added to Following.' : 'Report removed from Following.')),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readableApiError(error))),
      );
      // A failed request must not optimistically change the counts or flags.
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Community report')),
      body: FutureBuilder<CommunityReport>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError || !snapshot.hasData) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      snapshot.hasError
                          ? readableApiError(snapshot.error!)
                          : 'Report unavailable.',
                      textAlign: TextAlign.center,
                    ),
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

          final report = snapshot.data!;
          final before = report.images.where((image) => image.type == 'BEFORE').toList();
          final after = report.images.where((image) => image.type == 'AFTER').toList();
          final canConfirm = !report.isClosed || report.isConfirmed;
          final canFollow = !report.isClosed || report.isFollowing;

          return RefreshIndicator(
            onRefresh: _refresh,
            child: ListView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(18),
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        report.categoryName,
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                    ),
                    Chip(label: Text(friendlyStatus(report.status))),
                  ],
                ),
                Text('ID: ${report.id}', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 16),
                Text(report.description, style: Theme.of(context).textTheme.bodyLarge),
                const SizedBox(height: 14),
                Text('Reported ${formatDateTime(report.createdAt)}'),
                const SizedBox(height: 8),
                Text(report.address.isNotEmpty
                    ? report.address
                    : '${report.latitude}, ${report.longitude}'),
                const SizedBox(height: 14),
                LocationMapCard(
                  latitude: report.latitude,
                  longitude: report.longitude,
                  address: report.address,
                ),
                const SizedBox(height: 18),
                if (before.isNotEmpty) ...[
                  Text('Reported photos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _CommunityImages(images: before),
                  const SizedBox(height: 18),
                ],
                if (after.isNotEmpty) ...[
                  Text('Resolution photos', style: Theme.of(context).textTheme.titleMedium),
                  const SizedBox(height: 8),
                  _CommunityImages(images: after),
                  const SizedBox(height: 18),
                ],
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text('Community engagement',
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w800,
                                )),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 18,
                          runSpacing: 8,
                          children: [
                            Text('${report.confirmationCount} confirmations'),
                            Text('${report.followerCount} followers'),
                          ],
                        ),
                        const SizedBox(height: 14),
                        FilledButton.icon(
                          onPressed: _saving || !canConfirm
                              ? null
                              : () => _change(
                                    confirmation: true,
                                    newValue: !report.isConfirmed,
                                  ),
                          icon: Icon(report.isConfirmed
                              ? Icons.check_circle
                              : Icons.check_circle_outline),
                          label: Text(report.isConfirmed
                              ? 'Withdraw confirmation'
                              : 'Confirm this issue'),
                        ),
                        const SizedBox(height: 8),
                        OutlinedButton.icon(
                          onPressed: _saving || !canFollow
                              ? null
                              : () => _change(
                                    confirmation: false,
                                    newValue: !report.isFollowing,
                                  ),
                          icon: Icon(report.isFollowing
                              ? Icons.notifications_active_outlined
                              : Icons.bookmark_add_outlined),
                          label: Text(report.isFollowing
                              ? 'Unfollow report'
                              : 'Follow report'),
                        ),
                        if (_saving) const LinearProgressIndicator(),
                        const SizedBox(height: 8),
                        Text(
                          report.isClosed
                              ? 'This report is closed to new confirmations and followers. Existing participation can be withdrawn.'
                              : 'Confirm only issues you have observed. Following saves a report; follower status alerts are planned for Phase 8.3.',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _CommunityImages extends StatelessWidget {
  const _CommunityImages({required this.images});

  final List<ReportImageItem> images;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 180,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, index) => ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            ApiConfig.resolveMediaUrl(images[index].url),
            width: 220,
            height: 180,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => const SizedBox(
              width: 220,
              child: Icon(Icons.broken_image_outlined),
            ),
          ),
        ),
      ),
    );
  }
}
