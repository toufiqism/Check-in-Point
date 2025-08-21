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
      final previous = _activePoint;
      _activePoint = event;
      _syncMonitoring(previous: previous, current: _activePoint);
      notifyListeners();
    });
  }

  final CheckInRepository _repository;
  late final StreamSubscription<CheckInPoint?> _subscription;
  StreamSubscription<Position>? _positionSubscription;

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
        // Mark user as checked in
        await _repository.setUserCheckedIn(point: active);
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
    _stopMonitoring();
    super.dispose();
  }

  // Presence count stream
  Stream<int> get checkedInCount => _repository.watchCheckedInCount();

  void _syncMonitoring({
    required CheckInPoint? previous,
    required CheckInPoint? current,
  }) {
    if (current == null) {
      _stopMonitoring();
      return;
    }
    if (previous == null) {
      _startMonitoring();
      return;
    }
    if (previous.latitude != current.latitude ||
        previous.longitude != current.longitude ||
        previous.radiusMeters != current.radiusMeters) {
      _restartMonitoring();
    }
  }

  void _startMonitoring() {
    if (_positionSubscription != null) return;
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate, onError: (Object e, StackTrace s) {
      // ignore continuous stream errors
    });
  }

  void _restartMonitoring() {
    _stopMonitoring();
    _startMonitoring();
  }

  void _stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
  }

  Future<void> _onPositionUpdate(Position position) async {
    final CheckInPoint? point = _activePoint;
    if (point == null) return;
    final double distance = Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      position.latitude,
      position.longitude,
    );
    if (distance > point.radiusMeters) {
      try {
        // Auto check-out only marks presence; active point remains for others
        await _repository.setUserCheckedOut(reason: 'auto');
      } catch (_) {}
    }
  }
}


