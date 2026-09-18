import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:url_launcher/url_launcher.dart';

class LocationMapCard extends StatelessWidget {
  const LocationMapCard({
    super.key,
    required this.latitude,
    required this.longitude,
    this.title = 'Reported location',
    this.address = '',
    this.height = 220,
    this.showDirections = false,
    this.interactive = false,
  });

  final double latitude;
  final double longitude;
  final String title;
  final String address;
  final double height;
  final bool showDirections;

  /// Keep embedded maps non-interactive by default so drag gestures are
  /// handled by the surrounding scrollable screen instead of panning the map.
  /// Users can still open the location in their map app using the action button.
  final bool interactive;

  Future<void> _launchMap(BuildContext context, {required bool directions}) async {
    final query = '$latitude,$longitude';
    final uri = directions
        ? Uri.https('www.google.com', '/maps/dir/', {
            'api': '1',
            'destination': query,
          })
        : Uri.https('www.google.com', '/maps/search/', {
            'api': '1',
            'query': query,
          });

    final launched = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!launched && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open the map application.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final center = LatLng(latitude, longitude);
    final map = FlutterMap(
      options: MapOptions(
        initialCenter: center,
        initialZoom: 16,
      ),
      children: [
        TileLayer(
          urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
          userAgentPackageName: 'com.example.envirohub_citizen',
        ),
        MarkerLayer(
          markers: [
            Marker(
              point: center,
              width: 48,
              height: 48,
              child: Icon(
                Icons.location_pin,
                size: 46,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );

    return Card(
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            height: height,
            child: Stack(
              children: [
                Positioned.fill(
                  child: interactive ? map : IgnorePointer(child: map),
                ),
                Positioned(
                  right: 6,
                  bottom: 4,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.9),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      child: Text('© OpenStreetMap contributors', style: TextStyle(fontSize: 9)),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.location_on_outlined, size: 21),
                const SizedBox(width: 9),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: const TextStyle(fontWeight: FontWeight.w700)),
                      const SizedBox(height: 2),
                      Text(
                        address.trim().isEmpty
                            ? '${latitude.toStringAsFixed(6)}, ${longitude.toStringAsFixed(6)}'
                            : address.trim(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                if (showDirections)
                  IconButton(
                    tooltip: 'Directions',
                    onPressed: () => _launchMap(context, directions: true),
                    icon: const Icon(Icons.directions_outlined),
                  )
                else
                  IconButton(
                    tooltip: 'Open map',
                    onPressed: () => _launchMap(context, directions: false),
                    icon: const Icon(Icons.open_in_new_rounded),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
