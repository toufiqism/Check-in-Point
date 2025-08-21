import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:check_in_point/models/check_in_point.dart';

class CheckInRepository {
  CheckInRepository({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _firebaseAuth;

  DocumentReference<Map<String, dynamic>> get _activePointDoc =>
      _firestore.collection('checkin_point').doc('active');

  Future<void> upsertActivePoint({
    required double latitude,
    required double longitude,
    required int radiusMeters,
  }) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final docRef = _activePointDoc;
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final now = FieldValue.serverTimestamp();
      final data = <String, dynamic>{
        'latitude': latitude,
        'longitude': longitude,
        'radiusMeters': radiusMeters,
        'active': true,
        'updatedAt': now,
      };
      if (snapshot.exists) {
        transaction.update(docRef, data);
      } else {
        transaction.set(docRef, {
          ...data,
          'createdAt': now,
        });
      }
    });
  }

  Future<void> clearActivePoint() async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final docRef = _activePointDoc;
    await docRef.delete();
  }

  Stream<CheckInPoint?> watchActivePoint() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      return const Stream<CheckInPoint?>.empty();
    }
    return _activePointDoc.snapshots().map((doc) => CheckInPoint.fromDoc(doc));
  }

  Future<void> recordCheckoutAndClear({
    required CheckInPoint point,
    String reason = 'auto',
  }) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final CollectionReference<Map<String, dynamic>> logs =
        _firestore.collection('checkin_logs');
    final now = FieldValue.serverTimestamp();
    await _firestore.runTransaction((transaction) async {
      transaction.set(logs.doc(), {
        'uid': user.uid,
        'latitude': point.latitude,
        'longitude': point.longitude,
        'radiusMeters': point.radiusMeters,
        'checkedOutAt': now,
        'reason': reason,
      });
      transaction.delete(_activePointDoc);
    });
  }

  DocumentReference<Map<String, dynamic>> get _userCheckInDoc {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    return _firestore.collection('checkins').doc(user.uid);
  }

  Future<void> setUserCheckedIn({required CheckInPoint point}) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final now = FieldValue.serverTimestamp();
    await _userCheckInDoc.set({
      'uid': user.uid,
      'checkedIn': true,
      'lastCheckInAt': now,
      'updatedAt': now,
      'point': {
        'latitude': point.latitude,
        'longitude': point.longitude,
        'radiusMeters': point.radiusMeters,
      },
    }, SetOptions(merge: true));
  }

  Future<void> setUserCheckedOut({String reason = 'manual'}) async {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) {
      throw StateError('Not authenticated');
    }
    final now = FieldValue.serverTimestamp();
    await _userCheckInDoc.set({
      'uid': user.uid,
      'checkedIn': false,
      'lastCheckOutAt': now,
      'updatedAt': now,
      'reason': reason,
    }, SetOptions(merge: true));
  }

  Stream<int> watchCheckedInCount() {
    return _firestore
        .collection('checkins')
        .where('checkedIn', isEqualTo: true)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}


