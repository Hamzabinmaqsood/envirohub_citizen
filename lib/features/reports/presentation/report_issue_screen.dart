import 'dart:io';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../core/network/api_client.dart';
import '../data/report_repository.dart';
import '../models/category.dart';

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

  List<ReportCategory> _categories = const [];
  ReportCategory? _category;
  final List<XFile> _images = [];
  Position? _position;
  bool _loading = true;
  bool _locating = false;
  bool _submitting = false;
  String? _error;

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
      if (mounted) setState(() { _error = readableApiError(e); _loading = false; });
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
      if (mounted) setState(() => _position = position);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
    } finally {
      if (mounted) setState(() => _locating = false);
    }
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Describe the environmental issue.')));
      return;
    }
    if (_images.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Add at least one photo.')));
      return;
    }
    if (_position == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('GPS location is required.')));
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
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Report submitted successfully.')));
      Navigator.of(context).pop(report);
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(readableApiError(e))));
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
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!)))
              : ListView(
                  padding: const EdgeInsets.all(18),
                  children: [
                    Text('1. Evidence', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    if (_images.isNotEmpty)
                      SizedBox(
                        height: 110,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: _images.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) => Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.file(File(_images[index].path), width: 110, height: 110, fit: BoxFit.cover),
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
                        Expanded(child: OutlinedButton.icon(onPressed: _images.length >= 5 ? null : _takePhoto, icon: const Icon(Icons.camera_alt_outlined), label: const Text('Camera'))),
                        const SizedBox(width: 10),
                        Expanded(child: OutlinedButton.icon(onPressed: _images.length >= 5 ? null : _pickFromGallery, icon: const Icon(Icons.photo_library_outlined), label: const Text('Gallery'))),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text('${_images.length}/5 photos', style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 24),
                    Text('2. Issue', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    DropdownButtonFormField<ReportCategory>(
                      initialValue: _category,
                      decoration: const InputDecoration(labelText: 'Category'),
                      items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c.name))).toList(),
                      onChanged: (value) => setState(() => _category = value),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _description,
                      maxLength: 1500,
                      minLines: 4,
                      maxLines: 7,
                      decoration: const InputDecoration(labelText: 'Describe the problem', alignLabelWithHint: true),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Landmark / address (optional)', prefixIcon: Icon(Icons.place_outlined)),
                    ),
                    const SizedBox(height: 24),
                    Text('3. Location', style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 10),
                    Card(
                      child: ListTile(
                        leading: const Icon(Icons.my_location_rounded),
                        title: Text(_position == null ? 'GPS not captured' : 'GPS captured'),
                        subtitle: _position == null ? null : Text('${_position!.latitude.toStringAsFixed(6)}, ${_position!.longitude.toStringAsFixed(6)}'),
                        trailing: _locating
                            ? const SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2))
                            : TextButton(onPressed: _captureLocation, child: Text(_position == null ? 'Capture' : 'Refresh')),
                      ),
                    ),
                    const SizedBox(height: 26),
                    FilledButton.icon(
                      onPressed: _submitting ? null : _submit,
                      icon: _submitting
                          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                          : const Icon(Icons.send_rounded),
                      label: Text(_submitting ? 'Submitting...' : 'Submit report'),
                    ),
                  ],
                ),
    );
  }
}
