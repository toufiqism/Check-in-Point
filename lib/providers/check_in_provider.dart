import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:check_in_point/data/check_in_repository.dart';
import 'package:check_in_point/models/check_in_point.dart';
import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';
import 'package:check_in_point/models/check_in_attempt_result.dart';
import 'package:check_in_point/utils/location_helper.dart';

class CheckInProvider extends ChangeNotifier {
  CheckInProvider({required CheckInRepository repository})
      : _repository = repository {
    _authSubscription = _repository.authStateChanges().listen(_onAuthChanged);
  }

  final CheckInRepository _repository;

  late final StreamSubscription<User?> _authSubscription;
  StreamSubscription<CheckInPoint?>? _pointSubscription;
  StreamSubscription<String?>? _checkedInSubscription;
  StreamSubscription<Position>? _positionSubscription;

  String? _uid;
  bool _hasHandledAuthEvent = false;

  CheckInPoint? _activePoint;
  CheckInPoint? get activePoint => _activePoint;

  /// The point the signed-in user is checked into, which may be a point that
  /// has since been replaced or cleared.
  String? _checkedInPointId;

  /// True only while the user is checked into the point that is currently
  /// active. A check-in against a replaced point does not count.
  bool get isCheckedIn {
    final String? activePointId = _activePoint?.pointId;
    return activePointId != null && _checkedInPointId == activePointId;
  }

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  bool _isCheckingOut = false;

  String? _error;
  String? get error => _error;

  String? _monitoredPointId;

  String? _countPointId;
  Stream<int>? _countStream;

  /// A single stream per active point, so rebuilds do not resubscribe and
  /// momentarily drop the count back to zero.
  Stream<int> get checkedInCount {
    final CheckInPoint? point = _activePoint;
    if (point == null) return Stream<int>.value(0);
    if (_countStream == null || _countPointId != point.pointId) {
      _countPointId = point.pointId;
      _countStream = _repository.watchCheckedInCount(pointId: point.pointId);
    }
    return _countStream!;
  }

  void _onAuthChanged(User? user) {
    final String? uid = user?.uid;
    if (_hasHandledAuthEvent && uid == _uid) return;
    _hasHandledAuthEvent = true;
    _uid = uid;

    _pointSubscription?.cancel();
    _pointSubscription = null;
    _checkedInSubscription?.cancel();
    _checkedInSubscription = null;
    _stopMonitoring();

    _activePoint = null;
    _checkedInPointId = null;
    _countStream = null;
    _countPointId = null;
    _error = null;

    if (uid != null) {
      _pointSubscription = _repository.watchActivePoint().listen(
        (CheckInPoint? point) {
          _activePoint = point;
          _syncMonitoring();
          notifyListeners();
        },
        onError: (Object e, StackTrace s) {
          _activePoint = null;
          _syncMonitoring();
          notifyListeners();
        },
      );
      _checkedInSubscription = _repository.watchUserCheckedInPointId().listen(
        (String? pointId) {
          _checkedInPointId = pointId;
          _syncMonitoring();
          notifyListeners();
        },
        onError: (Object e, StackTrace s) {
          _checkedInPointId = null;
          _syncMonitoring();
          notifyListeners();
        },
      );
    }

    notifyListeners();
  }

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
      final Position position =
          await LocationHelper.getCurrentPositionWithPermission();
      final double distance = Geolocator.distanceBetween(
        active.latitude,
        active.longitude,
        position.latitude,
        position.longitude,
      );
      if (distance <= active.radiusMeters) {
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

  /// Clears the shared point, checking the current user out first so their
  /// presence document does not outlive the point it refers to.
  Future<bool> clearActive() async {
    _setError(null);
    try {
      if (isCheckedIn) {
        await _repository.setUserCheckedOut(reason: 'point-cleared');
      }
      await _repository.clearActivePoint();
      return true;
    } catch (e) {
      _setError('Failed to clear: ${e.toString()}');
      return false;
    }
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
    _authSubscription.cancel();
    _pointSubscription?.cancel();
    _checkedInSubscription?.cancel();
    _stopMonitoring();
    super.dispose();
  }

  /// Position tracking exists only to check the user out when they leave, so
  /// it runs only while they are actually checked into the active point.
  void _syncMonitoring() {
    final CheckInPoint? point = _activePoint;
    if (point == null || !isCheckedIn) {
      _stopMonitoring();
      return;
    }
    if (_positionSubscription != null && _monitoredPointId == point.pointId) {
      return;
    }
    _stopMonitoring();
    _monitoredPointId = point.pointId;
    _positionSubscription = Geolocator.getPositionStream(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.best,
        distanceFilter: 5,
      ),
    ).listen(_onPositionUpdate, onError: (Object e, StackTrace s) {
      // ignore continuous stream errors
    });
  }

  void _stopMonitoring() {
    _positionSubscription?.cancel();
    _positionSubscription = null;
    _monitoredPointId = null;
  }

  Future<void> _onPositionUpdate(Position position) async {
    final CheckInPoint? point = _activePoint;
    if (point == null || !isCheckedIn || _isCheckingOut) return;
    final double distance = Geolocator.distanceBetween(
      point.latitude,
      point.longitude,
      position.latitude,
      position.longitude,
    );
    if (distance <= point.radiusMeters) return;
    _isCheckingOut = true;
    try {
      // Only presence is updated; the point stays for everyone else. The
      // resulting document change stops monitoring via the check-in stream.
      await _repository.setUserCheckedOut(reason: 'auto');
    } catch (_) {
      // Leave the state alone so the next position update retries.
    } finally {
      _isCheckingOut = false;
    }
  }
}
