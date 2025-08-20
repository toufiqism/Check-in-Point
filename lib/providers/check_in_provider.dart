import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:check_in_point/data/check_in_repository.dart';
import 'package:check_in_point/models/check_in_point.dart';

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


