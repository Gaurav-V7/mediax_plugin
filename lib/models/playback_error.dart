class PlaybackError {
  // Standard error codes
  static const int unknown = 1000;
  static const int sourceNotFound = 1001;
  static const int codecError = 1002;
  static const int networkError = 1003;
  static const int timeout = 1004;
  static const int drmError = 1005;
  static const int internalError = 1006;
  static const int audioSessionError = 1007;
  static const int unsupportedFormat = 1008;
  static const int invalidState = 1009;
  static const int resourceError = 1010;

  // Error messages corresponding to error codes
  static const Map<int, String> _errors = {
    unknown: "Unknown error occurred.",
    sourceNotFound: "Media source not found.",
    codecError: "Codec initialization failed.",
    networkError: "Network error occurred.",
    timeout: "Playback timed out.",
    drmError: "DRM decryption failed.",
    internalError: "Playback failed due to an internal error.",
    audioSessionError: "Audio session error occurred.",
    unsupportedFormat: "Media format is not supported.",
    invalidState: "Invalid player state.",
    resourceError: "Failed to allocate resources.",
  };

  final String message;
  final int errorCode;
  final String stackTrace;

  PlaybackError._({required this.message, required this.errorCode, required this.stackTrace});

  /// Create a PlaybackError from platform error details
  factory PlaybackError.fromPlatform(Map<String, dynamic> errorDetails) {
    final errorCode = errorDetails['errorCode'] as int;
    final stackTrace = errorDetails['stackTrace'] as String;
    
    return PlaybackError._(
      errorCode: errorCode,
      message: _errors[errorCode] ?? "Unknown error occurred.",
      stackTrace: stackTrace,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      "errorCode": errorCode,
      "message": message,
      "stackTrace": stackTrace,
    };
  }

  @override
  String toString() {
    return """\nPLAYBACK ERROR OCCURRED\nMessage: $message\nCode: $errorCode\nStack Trace:\n$stackTrace""";
  }
}
