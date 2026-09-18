import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../reports/data/report_repository.dart';
import '../../reports/presentation/report_detail_screen.dart';
import '../data/notification_repository.dart';
import '../models/app_notification.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({
    super.key,
    required this.repository,
    required this.reportRepository,
  });

  final NotificationRepository repository;
  final ReportRepository reportRepository;

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  late Future<List<AppNotification>> _future;

  @override
  void initState() {
    super.initState();
    _reload();
  }

  void _reload() => _future = widget.repository.getNotifications();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<AppNotification>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) return Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(readableApiError(snapshot.error!))));
        final items = snapshot.data ?? const [];
        if (items.isEmpty) return const Center(child: Text('No notifications yet.'));

        return Column(
          children: [
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () async {
                  await widget.repository.markAllRead();
                  if (mounted) setState(_reload);
                },
                child: const Text('Mark all read'),
              ),
            ),
            Expanded(
              child: RefreshIndicator(
                onRefresh: () async { setState(_reload); await _future; },
                child: ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final item = items[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          child: Icon(item.isRead ? Icons.notifications_none : Icons.notifications_active_outlined),
                        ),
                        title: Text(item.title, style: TextStyle(fontWeight: item.isRead ? FontWeight.w500 : FontWeight.w800)),
                        subtitle: Text('${item.message}\n${formatDateTime(item.createdAt)}'),
                        isThreeLine: true,
                        onTap: () async {
                          if (!item.isRead) await widget.repository.markRead(item.id);
                          if (item.reportId != null && context.mounted) {
                            await Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ReportDetailScreen(repository: widget.reportRepository, reportId: item.reportId!),
                              ),
                            );
                          }
                          if (mounted) setState(_reload);
                        },
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}
