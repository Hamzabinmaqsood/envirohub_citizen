import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/location_map_card.dart';
import '../data/report_repository.dart';
import '../models/category.dart';
import '../models/nearby_report.dart';

class ReportIssueScreen extends StatefulWidget {
  const ReportIssueScreen({super.key, required this.repository});

  final ReportRepository repository;

  @override
  State<ReportIssueScreen> createState() => _ReportIssueScreenState();
}

class _ReportIssueScreenState extends State<ReportIssueScreen> {
  final _description = TextEditingController();
  final _address = TextEditingController();
  final _picker = ImagePicker();
  final _geocoding = Geocoding();

  List<ReportCategory> _categories = const [];
  ReportCategory? _category;
  final List<XFile> _images = [];
  List<NearbyReport> _nearbyReports = const [];
  Position? _position;
  bool _loading = true;
  bool _locating = false;
  bool _reverseGeocoding = false;
  bool _nearbyLoading = false;
  bool _submitting = false;
  String? _error;
  String? _lastAutoAddress;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _description.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final categories = await widget.repository.getCategories();
      if (!mounted) return;
      setState(() {
        _categories = categories;
        _category = categories.isNotEmpty ? categories.first : null;
        _loading = false;
      });
      await _captureLocation();
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = readableApiError(e);
          _loading = false;
        });
      }
    }
  }

  Future<void> _captureLocation() async {
    setState(() => _locating = true);
    try {
      final enabled = await Geolocator.isLocationServiceEnabled();
      if (!enabled) throw Exception('Please turn on Location/GPS and try again.');

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        throw Exception('Location permission is required to report an environmental issue.');
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );
      if (!mounted) return;
      // GPS acquisition is complete at this point. Do not keep the main
      // location spinner running while optional network-backed enrichment
      // (reverse geocoding / nearby lookup) finishes.
      setState(() {
        _position = position;
        _locating = false;
      });

      await Future.wait([
        _reverseGeocode(position),
        _loadNearby(position),
      ]);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
        );
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
  }

  Future<void> _reverseGeocode(Position position) async {
    if (mounted) setState(() => _reverseGeocoding = true);
    try {
      final placemarks = await _geocoding
          .placemarkFromCoordinates(
            position.latitude,
            position.longitude,
          )
          .timeout(const Duration(seconds: 8));
      if (placemarks.isEmpty || !mounted) return;
      final readable = _formatPlacemark(placemarks.first);
      if (readable.isEmpty) return;
      final current = _address.text.trim();
      if (current.isEmpty || current == _lastAutoAddress) {
        _address.text = readable;
        _lastAutoAddress = readable;
      }
    } catch (_) {
      // Reverse geocoding is a convenience only. GPS coordinates remain authoritative.
    } finally {
      if (mounted) setState(() => _reverseGeocoding = false);
    }
  }

  String _formatPlacemark(Placemark placemark) {
    final parts = <String?>[
      placemark.street,
      placemark.subLocality,
      placemark.locality,
      placemark.subAdministrativeArea,
      placemark.administrativeArea,
      placemark.postalCode,
      placemark.country,
    ].whereType<String>().map((value) => value.trim()).where((value) => value.isNotEmpty);

    final seen = <String>{};
    return parts.where((value) => seen.add(value.toLowerCase())).join(', ');
  }

  Future<void> _loadNearby(Position position) async {
    if (mounted) setState(() => _nearbyLoading = true);
    try {
      final reports = await widget.repository
          .getNearbyReports(
            latitude: position.latitude,
            longitude: position.longitude,
            radiusM: 200,
            categorySlug: _category?.slug,
          )
          .timeout(const Duration(seconds: 10));
      if (mounted) setState(() => _nearbyReports = reports);
    } catch (_) {
      if (mounted) setState(() => _nearbyReports = const []);
    } finally {
      if (mounted) setState(() => _nearbyLoading = false);
    }
  }

  void _changeCategory(ReportCategory? value) {
    setState(() {
      _category = value;
      _nearbyReports = const [];
    });
    final position = _position;
    if (position != null) _loadNearby(position);
  }

  Future<void> _pickFromGallery() async {
    final picked = await _picker.pickMultiImage(imageQuality: 82);
    if (picked.isEmpty) return;
    setState(() {
      final remaining = 5 - _images.length;
      _images.addAll(picked.take(remaining));
    });
  }

  Future<void> _takePhoto() async {
    if (_images.length >= 5) return;
    final photo = await _picker.pickImage(source: ImageSource.camera, imageQuality: 82);
    if (photo != null) setState(() => _images.add(photo));
  }

  Future<void> _submit() async {
    if (_category == null) return;
    if (_description.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Describe the environmental issue.')),
      );
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Add at least one photo.')),
      );
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('GPS location is required.')),
      );
      await _captureLocation();
      return;
    }

    setState(() => _submitting = true);
    try {
      final report = await widget.repository.createReport(
        categorySlug: _category!.slug,
        description: _description.text.trim(),
        address: _address.text.trim(),
        latitude: _position!.latitude,
        longitude: _position!.longitude,
        images: _images,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Report submitted successfully.')),
      );
      Navigator.of(context).pop(report);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(readableApiError(e))),
        );
      }
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Report environmental issue')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Text(_error!),
                  ),
                )
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text(
                      '1. Evidence',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, _) => const SizedBox(width: 10),
                          itemBuilder: (context, index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(
                                  File(_images[index].path),
                                  width: 110,
                                  height: 110,
                                  fit: BoxFit.cover,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: IconButton.filledTonal(
                                  visualDensity: VisualDensity.compact,
                                  onPressed: () => setState(() => _images.removeAt(index)),
                                  icon: const Icon(Icons.close, size: 18),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (_images.isNotEmpty) const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _images.length >= 5 ? null : _takePhoto,
                            icon: const Icon(Icons.camera_alt_outlined),
                            label: const Text('Camera'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: _images.length >= 5 ? null : _pickFromGallery,
                            icon: const Icon(Icons.photo_library_outlined),
                            label: const Text('Gallery'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${_images.length}/5 photos', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    Text(
                      '2. Issue',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ReportCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories
                          .map((category) => DropdownMenuItem(value: category, child: Text(category.name)))
                          .toList(),
                      onChanged: _changeCategory,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      maxLength: 1500,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(
                        labelText: 'Describe the problem',
                        alignLabelWithHint: true,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      '3. Location',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.my_location_rounded),
                        title: Text(_position == null ? 'GPS not captured' : 'GPS captured'),
                        subtitle: _position == null
                            ? null
                            : Text(
                                '${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}',
                              ),
                        trailing: _locating
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : TextButton(
                                onPressed: _captureLocation,
                                child: Text(_position == null ? 'Capture' : 'Refresh'),
                              ),
                      ),
                    ),
                    if (_position != null) ...[
                      const SizedBox(height: 12),
                      LocationMapCard(
                        latitude: _position!.latitude,
                        longitude: _position!.longitude,
                        title: 'Pin preview',
                        address: _address.text,
                      ),
                    ],
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      decoration: InputDecoration(
                        labelText: 'Readable address / landmark',
                        prefixIcon: const Icon(Icons.place_outlined),
                        helperText: _reverseGeocoding
                            ? 'Finding a readable address from GPS…'
                            : 'Auto-filled when available. You can edit it.',
                      ),
                    ),
                    const SizedBox(height: 14),
                    _NearbyReportsCard(
                      loading: _nearbyLoading,
                      reports: _nearbyReports,
                      categoryName: _category?.name ?? 'similar',
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Submitting...' : 'Submit report'),
                    ),
                  ],
                ),
    );
  }
}

class _NearbyReportsCard extends StatelessWidget {
  const _NearbyReportsCard({
    required this.loading,
    required this.reports,
    required this.categoryName,
  });

  final bool loading;
  final List<NearbyReport> reports;
  final String categoryName;

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(16),
          child: Row(
            children: [
              SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
              SizedBox(width: 12),
              Expanded(child: Text('Checking for nearby open reports…')),
            ],
          ),
        ),
      );
    }

    if (reports.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 12),
              Expanded(child: Text('No open $categoryName reports found within 200 m.')),
            ],
          ),
        ),
      );
    }

    return Card(
      color: Theme.of(context).colorScheme.tertiaryContainer.withValues(alpha: 0.55),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.content_copy_outlined),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Potential duplicate nearby',
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text('Similar open reports already exist close to this GPS point. You can still submit if this is a separate issue.'),
            const SizedBox(height: 10),
            ...reports.take(3).map(
                  (report) => Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Row(
                      children: [
                        const Icon(Icons.near_me_outlined, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            '${report.categoryName} • ${friendlyStatus(report.status)}',
                          ),
                        ),
                        Text('${report.distanceM} m'),
                      ],
                    ),
                  ),
                ),
          ],
        ),
      ),
    );
  }
}
