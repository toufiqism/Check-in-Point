import 'package:geolocator/geolocator.dart';

class LocationHelper {
  static Future<Position> getCurrentPositionWithPermission() async {
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw StateError('Location services are disabled.');
    }
    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied) {
      throw StateError('Location permission denied.');
    }
    if (permission == LocationPermission.deniedForever) {
      throw StateError('Location permission permanently denied.');
    }
    return Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.best);
  }
}


