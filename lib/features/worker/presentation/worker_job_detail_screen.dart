import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/config/api_config.dart';
import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../data/worker_repository.dart';
import '../models/worker_report.dart';

class WorkerJobDetailScreen extends StatefulWidget {
  const WorkerJobDetailScreen({
    super.key,
    required this.repository,
    required this.reportId,
  });

  final WorkerRepository repository;
  final String reportId;

  @override
  State<WorkerJobDetailScreen> createState() => _WorkerJobDetailScreenState();
}

class _WorkerJobDetailScreenState extends State<WorkerJobDetailScreen> {
  WorkerReport? _report;
  String? _error;
  bool _loading = true;
  bool _actionBusy = false;
  bool _changed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final report = await widget.repository.getReport(widget.reportId);
      if (!mounted) return;
      setState(() => _report = report);
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = readableApiError(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _startJob() async {
    final noteController = TextEditingController(text: 'Reached the site and started work.');
    final note = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Start this job?'),
        content: TextField(
          controller: noteController,
          maxLength: 500,
          maxLines: 3,
          decoration: const InputDecoration(labelText: 'Progress note'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          FilledButton(
            onPressed: () => Navigator.pop(context, noteController.text.trim()),
            child: const Text('Start job'),
          ),
        ],
      ),
    );
    noteController.dispose();
    if (note == null) return;

    setState(() => _actionBusy = true);
    try {
      final updated = await widget.repository.startJob(widget.reportId, note: note);
      if (!mounted) return;
      setState(() {
        _report = updated;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job marked as in progress.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readableApiError(error))),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  Future<void> _resolveJob() async {
    final result = await showModalBottomSheet<_ResolvePayload>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => const _ResolveJobSheet(),
    );
    if (result == null) return;

    setState(() => _actionBusy = true);
    try {
      final updated = await widget.repository.resolveJob(
        id: widget.reportId,
        images: result.images,
        note: result.note,
      );
      if (!mounted) return;
      setState(() {
        _report = updated;
        _changed = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Job resolved successfully.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(readableApiError(error))),
      );
    } finally {
      if (mounted) setState(() => _actionBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        Navigator.of(context).pop(_changed);
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Job details'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: () => Navigator.of(context).pop(_changed),
          ),
        ),
        body: _buildBody(),
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) return const Center(child: CircularProgressIndicator());
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_error!, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: _load, child: const Text('Try again')),
            ],
          ),
        ),
      );
    }

    final report = _report!;
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(18),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  report.categoryName,
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                ),
              ),
              Chip(label: Text(friendlyStatus(report.status))),
            ],
          ),
          Text('Job ID: ${report.id}', style: Theme.of(context).textTheme.bodySmall),
          const SizedBox(height: 18),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _InfoRow(icon: Icons.person_outline, label: 'Citizen', value: report.citizenName),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.location_on_outlined,
                    label: 'Location',
                    value: report.address.isEmpty
                        ? '${report.latitude}, ${report.longitude}'
                        : report.address,
                  ),
                  const Divider(height: 24),
                  _InfoRow(
                    icon: Icons.schedule,
                    label: 'Submitted',
                    value: formatDateTime(report.createdAt),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 18),
          Text('Issue description', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 8),
          Text(report.description.isEmpty ? 'No description provided.' : report.description),
          const SizedBox(height: 22),
          _ImageStrip(title: 'Citizen evidence', images: report.beforeImages),
          if (report.afterImages.isNotEmpty) ...[
            const SizedBox(height: 22),
            _ImageStrip(title: 'Resolution proof', images: report.afterImages),
          ],
          const SizedBox(height: 24),
          if (report.isAssigned)
            FilledButton.icon(
              onPressed: _actionBusy ? null : _startJob,
              icon: const Icon(Icons.play_arrow_rounded),
              label: Text(_actionBusy ? 'Please wait…' : 'Start job'),
            ),
          if (report.isInProgress)
            FilledButton.icon(
              onPressed: _actionBusy ? null : _resolveJob,
              icon: const Icon(Icons.camera_alt_outlined),
              label: Text(_actionBusy ? 'Please wait…' : 'Upload proof & resolve'),
            ),
          if (report.isResolved)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.verified_rounded, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text('Resolved ${formatDateTime(report.resolvedAt)}'),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 26),
          Text('Job timeline', style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
          ...report.timeline.map((item) => _TimelineTile(item: item)),
        ],
      ),
    );
  }
}

class _ResolveJobSheet extends StatefulWidget {
  const _ResolveJobSheet();

  @override
  State<_ResolveJobSheet> createState() => _ResolveJobSheetState();
}

class _ResolveJobSheetState extends State<_ResolveJobSheet> {
  final _picker = ImagePicker();
  final _note = TextEditingController(text: 'Issue resolved and site cleaned.');
  final List<XFile> _images = [];

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _takePhoto() async {
    if (_images.length >= 5) return;
    final image = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 82,
      maxWidth: 1800,
    );
    if (image != null && mounted) setState(() => _images.add(image));
  }

  Future<void> _pickFromGallery() async {
    if (_images.length >= 5) return;
    final picked = await _picker.pickMultiImage(imageQuality: 82, maxWidth: 1800);
    if (!mounted) return;
    final available = 5 - _images.length;
    setState(() => _images.addAll(picked.take(available)));
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 18,
        bottom: MediaQuery.viewInsetsOf(context).bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Resolve job', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            const Text('Add at least one AFTER photo as proof of completion.'),
            const SizedBox(height: 18),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                OutlinedButton.icon(
                  onPressed: _images.length >= 5 ? null : _takePhoto,
                  icon: const Icon(Icons.camera_alt_outlined),
                  label: const Text('Camera'),
                ),
                OutlinedButton.icon(
                  onPressed: _images.length >= 5 ? null : _pickFromGallery,
                  icon: const Icon(Icons.photo_library_outlined),
                  label: const Text('Gallery'),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('${_images.length}/5 photos selected'),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: List.generate(
                  _images.length,
                  (index) => InputChip(
                    label: Text('Photo ${index + 1}'),
                    onDeleted: () => setState(() => _images.removeAt(index)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 18),
            TextField(
              controller: _note,
              maxLength: 500,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Resolution note'),
            ),
            const SizedBox(height: 14),
            FilledButton.icon(
              onPressed: _images.isEmpty
                  ? null
                  : () => Navigator.of(context).pop(
                        _ResolvePayload(images: List.unmodifiable(_images), note: _note.text.trim()),
                      ),
              icon: const Icon(Icons.check_circle_outline),
              label: const Text('Resolve job'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ResolvePayload {
  const _ResolvePayload({required this.images, required this.note});
  final List<XFile> images;
  final String note;
}

class _ImageStrip extends StatelessWidget {
  const _ImageStrip({required this.title, required this.images});
  final String title;
  final List<WorkerReportImage> images;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800)),
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
                    errorBuilder: (_, __, ___) => Container(
                      width: 220,
                      color: Theme.of(context).colorScheme.surfaceContainerHighest,
                      child: const Icon(Icons.broken_image_outlined),
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 21),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              Text(value, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ],
    );
  }
}

class _TimelineTile extends StatelessWidget {
  const _TimelineTile({required this.item});
  final WorkerTimelineItem item;

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
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
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
