class CheckInAttemptResult {
  CheckInAttemptResult({
    required this.success,
    required this.message,
    this.distanceMeters,
  });

  final bool success;
  final String message;
  final double? distanceMeters;

  factory CheckInAttemptResult.success({
    required String message,
    double? distanceMeters,
  }) => CheckInAttemptResult(
        success: true,
        message: message,
        distanceMeters: distanceMeters,
      );

  factory CheckInAttemptResult.failure({
    required String message,
    double? distanceMeters,
  }) => CheckInAttemptResult(
        success: false,
        message: message,
        distanceMeters: distanceMeters,
      );
}


