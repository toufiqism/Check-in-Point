import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:check_in_point/providers/check_in_provider.dart';
import 'package:check_in_point/utils/dialogs.dart';

class CheckInViewScreen extends StatefulWidget {
  const CheckInViewScreen({super.key});

  @override
  State<CheckInViewScreen> createState() => _CheckInViewScreenState();
}

class _CheckInViewScreenState extends State<CheckInViewScreen> {
  final Completer<GoogleMapController> _controller = Completer();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Active Check-in')),
      body: Consumer<CheckInProvider>(
        builder: (context, provider, _) {
          final active = provider.activePoint;
          if (active == null) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.location_off_outlined, size: 72),
                  const SizedBox(height: 8),
                  const Text('No active check-in'),
                  const SizedBox(height: 12),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                  ),
                ],
              ),
            );
          }
          final camera = CameraPosition(
            target: LatLng(active.latitude, active.longitude),
            zoom: 15,
          );
          return Column(
            children: [
              Expanded(
                child: GoogleMap(
                  initialCameraPosition: camera,
                  myLocationEnabled: true,
                  myLocationButtonEnabled: true,
                  onMapCreated: (c) => _controller.complete(c),
                  markers: {
                    Marker(
                      markerId: const MarkerId('active'),
                      position: LatLng(active.latitude, active.longitude),
                      infoWindow: const InfoWindow(title: 'Active check-in'),
                    ),
                  },
                  circles: {
                    Circle(
                      circleId: const CircleId('radius'),
                      center: LatLng(active.latitude, active.longitude),
                      radius: active.radiusMeters.toDouble(),
                      fillColor: theme.colorScheme.primary.withOpacity(0.15),
                      strokeColor: theme.colorScheme.primary,
                      strokeWidth: 2,
                    ),
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text('Details', style: theme.textTheme.titleMedium),
                    const SizedBox(height: 8),
                    Text('Latitude: ${active.latitude.toStringAsFixed(6)}'),
                    Text('Longitude: ${active.longitude.toStringAsFixed(6)}'),
                    Text('Radius: ${active.radiusMeters} m'),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(Icons.close),
                            label: const Text('Close'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              final result = await context.read<CheckInProvider>().attemptCheckIn();
                              if (!mounted) return;
                              await showMessageDialog(
                                context: context,
                                title: result.success ? 'Success' : 'Not in range',
                                message: result.distanceMeters == null
                                    ? result.message
                                    : '${result.message}\nDistance: ${result.distanceMeters!.toStringAsFixed(1)} m',
                              );
                            },
                            icon: const Icon(Icons.check_circle_outline),
                            label: const Text('Check in'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () async {
                              await provider.clearActive();
                              if (!mounted) return;
                              Navigator.of(context).maybePop();
                            },
                            icon: const Icon(Icons.delete_outline),
                            label: const Text('Clear'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}


