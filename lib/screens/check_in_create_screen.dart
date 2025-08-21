import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:check_in_point/providers/check_in_provider.dart';

class CheckInCreateScreen extends StatefulWidget {
  const CheckInCreateScreen({super.key});

  @override
  State<CheckInCreateScreen> createState() => _CheckInCreateScreenState();
}

class _CheckInCreateScreenState extends State<CheckInCreateScreen> {
  final Completer<GoogleMapController> _mapController = Completer();
  LatLng? _selectedLatLng;
  double _radiusMeters = 100;
  bool _locating = true;
  CameraPosition? _initialCamera;

  @override
  void initState() {
    super.initState();
    _initLocation();
  }

  Future<void> _initLocation() async {
    try {
      final permission = await Geolocator.checkPermission();
      LocationPermission ensured = permission;
      if (permission == LocationPermission.denied || permission == LocationPermission.deniedForever) {
        ensured = await Geolocator.requestPermission();
      }
      if (ensured == LocationPermission.denied || ensured == LocationPermission.deniedForever) {
        // Default to a world view if permissions denied
        _initialCamera = const CameraPosition(target: LatLng(0, 0), zoom: 2);
      } else {
        final pos = await Geolocator.getCurrentPosition();
        _initialCamera = CameraPosition(target: LatLng(pos.latitude, pos.longitude), zoom: 15);
      }
    } catch (_) {
      _initialCamera = const CameraPosition(target: LatLng(0, 0), zoom: 2);
    }
    if (mounted) {
      setState(() {
        _locating = false;
      });
    }
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _selectedLatLng = latLng;
    });
  }

  Future<void> _save() async {
    final provider = context.read<CheckInProvider>();
    final selected = _selectedLatLng;
    if (selected == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Tap on the map to place a pin.')));
      return;
    }
    final ok = await provider.saveActivePoint(
      latitude: selected.latitude,
      longitude: selected.longitude,
      radiusMeters: _radiusMeters.round(),
    );
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(true);
    } else {
      final message = provider.error ?? 'Failed to save. Try again.';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Check-in'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline),
            tooltip: 'Clear active',
            onPressed: () => context.read<CheckInProvider>().clearActive(),
          )
        ],
      ),
      body: _locating
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: GoogleMap(
                    initialCameraPosition: _initialCamera!,
                    myLocationEnabled: true,
                    myLocationButtonEnabled: true,
                    onMapCreated: (c) => _mapController.complete(c),
                    onTap: _onMapTap,
                    markers: {
                      if (_selectedLatLng != null)
                        Marker(markerId: const MarkerId('selected'), position: _selectedLatLng!),
                    },
                    circles: {
                      if (_selectedLatLng != null)
                        Circle(
                          circleId: const CircleId('radius'),
                          center: _selectedLatLng!,
                          radius: _radiusMeters,
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
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Radius: ${_radiusMeters.round()} m'),
                          TextButton(
                            onPressed: () => setState(() => _radiusMeters = 100),
                            child: const Text('Reset'),
                          ),
                        ],
                      ),
                      Slider(
                        min: 25,
                        max: 2000,
                        divisions: 79,
                        value: _radiusMeters,
                        label: '${_radiusMeters.round()} m',
                        onChanged: (v) => setState(() => _radiusMeters = v),
                      ),
                      const SizedBox(height: 8),
                      Consumer<CheckInProvider>(
                        builder: (context, p, _) => SizedBox(
                          height: 48,
                          child: ElevatedButton.icon(
                            onPressed: p.isSaving ? null : _save,
                            icon: p.isSaving
                                ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_outlined),
                            label: Text(p.isSaving ? 'Saving...' : 'Save Check-in'),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
}


