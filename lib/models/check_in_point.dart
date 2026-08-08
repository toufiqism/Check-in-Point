import 'package:cloud_firestore/cloud_firestore.dart';

class CheckInPoint {
  const CheckInPoint({
    required this.pointId,
    required this.latitude,
    required this.longitude,
    required this.radiusMeters,
    this.createdAt,
    this.updatedAt,
    this.active = true,
  });

  /// Identifies this particular placement of the point. Saving the point
  /// again mints a new id, which is what makes check-ins recorded against
  /// the previous placement countable as stale.
  final String pointId;
  final double latitude;
  final double longitude;
  final int radiusMeters;
  final Timestamp? createdAt;
  final Timestamp? updatedAt;
  final bool active;

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'pointId': pointId,
      'latitude': latitude,
      'longitude': longitude,
      'radiusMeters': radiusMeters,
      'active': active,
    };
  }

  static CheckInPoint? fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    if (!doc.exists) return null;
    final data = doc.data();
    if (data == null) return null;
    return CheckInPoint(
      // Points written before `pointId` existed fall back to the document id,
      // which keeps them readable instead of failing to parse.
      pointId: (data['pointId'] as String?) ?? doc.id,
      latitude: (data['latitude'] as num).toDouble(),
      longitude: (data['longitude'] as num).toDouble(),
      radiusMeters: (data['radiusMeters'] as num).toInt(),
      createdAt: data['createdAt'] as Timestamp?,
      updatedAt: data['updatedAt'] as Timestamp?,
      active: (data['active'] as bool?) ?? true,
    );
  }
}


