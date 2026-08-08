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

  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

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
    // Every save is a new placement, so it gets a new id. Check-ins recorded
    // against the old id stop counting towards this one.
    final String pointId = _firestore.collection('checkin_point').doc().id;
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      final now = FieldValue.serverTimestamp();
      final data = <String, dynamic>{
        'pointId': pointId,
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

  /// Callers are responsible for subscribing only while a user is signed in;
  /// [authStateChanges] is the intended trigger for starting and stopping.
  Stream<CheckInPoint?> watchActivePoint() {
    return _activePointDoc.snapshots().map((doc) => CheckInPoint.fromDoc(doc));
  }

  /// Emits the id of the point the signed-in user is currently checked into,
  /// or null when they are checked out. Signed-out callers get a stream that
  /// reports "not checked in" rather than an error, since the provider
  /// resubscribes on the next auth change anyway.
  Stream<String?> watchUserCheckedInPointId() {
    final User? user = _firebaseAuth.currentUser;
    if (user == null) return Stream<String?>.value(null);
    return _firestore.collection('checkins').doc(user.uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || data['checkedIn'] != true) return null;
      return data['pointId'] as String?;
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
      'pointId': point.pointId,
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

  /// Counts only the users checked into [pointId], so check-ins left over
  /// from a previous placement of the point are not included.
  Stream<int> watchCheckedInCount({required String pointId}) {
    return _firestore
        .collection('checkins')
        .where('checkedIn', isEqualTo: true)
        .where('pointId', isEqualTo: pointId)
        .snapshots()
        .map((snap) => snap.docs.length);
  }
}


