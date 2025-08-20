class AuthActionResult {
  AuthActionResult({required this.success, required this.message});

  final bool success;
  final String message;

  factory AuthActionResult.success(String message) =>
      AuthActionResult(success: true, message: message);

  factory AuthActionResult.failure(String message) =>
      AuthActionResult(success: false, message: message);
}


