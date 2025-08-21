import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:check_in_point/data/check_in_repository.dart';
import 'package:check_in_point/models/check_in_point.dart';
import 'package:geolocator/geolocator.dart';
import 'package:check_in_point/models/check_in_attempt_result.dart';
import 'package:check_in_point/utils/location_helper.dart';

class CheckInProvider extends ChangeNotifier {
  CheckInProvider({required CheckInRepository repository})
      : _repository = repository {
    _subscription = _repository.watchActivePoint().listen((event) {
      _activePoint = event;
      notifyListeners();
    });
  }

  final CheckInRepository _repository;
  late final StreamSubscription<CheckInPoint?> _subscription;

  CheckInPoint? _activePoint;
  CheckInPoint? get activePoint => _activePoint;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  Future<bool> saveActivePoint({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    if (_isSaving) return false;
    _setSaving(true);
    _setError(null);
    try {
      await _repository.upsertActivePoint(
        latitude: latitude,
        longitude: longitude,
        radiusMeters: radiusMeters,
      );
      return true;
    } catch (e) {
      _setError('Failed to save: ${e.toString()}');
      return false;
    } finally {
      _setSaving(false);
    }
  }

  Future<CheckInAttemptResult> attemptCheckIn() async {
    final CheckInPoint? active = _activePoint;
    if (active == null) {
      return CheckInAttemptResult.failure(message: 'No active check-in point.');
    }
    try {
      final Position position = await LocationHelper.getCurrentPositionWithPermission();
      final double distance = Geolocator.distanceBetween(
        active.latitude,
        active.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance <= active.radiusMeters) {
        return CheckInAttemptResult.success(
          message: 'Checked in successfully.',
          distanceMeters: distance,
        );
      } else {
        return CheckInAttemptResult.failure(
          message: 'You are not within the check-in range.',
          distanceMeters: distance,
        );
      }
    } catch (e) {
      return CheckInAttemptResult.failure(message: e.toString());
    }
  }

  Future<void> clearActive() async {
    try {
      await _repository.clearActivePoint();
    } catch (_) {}
  }

  void _setSaving(bool value) {
    _isSaving = value;
    notifyListeners();
  }

  void _setError(String? value) {
    _error = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }
}


