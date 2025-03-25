/// Represents an error that occurred during playback.
///
/// A `PlaybackError` is thrown by the [MediaX] plugin when a playback error
/// occurs. The error may be due to various reasons such as network errors,
/// codec errors, DRM errors, internal errors, audio session errors, or invalid
/// player states.
///
/// The [PlaybackError] class provides the following properties:
///
/// * `message`: A message describing the error.
/// * `errorCode`: A unique error code that can be used to identify the error.
/// * `stackTrace`: The stack trace of the error.
///
/// The [PlaybackError] class provides a set of standard error codes that can be
/// used to identify the type of error that occurred. These error codes are
/// defined in the [PlaybackError] class as static constants.
///
/// The [PlaybackError] class is used by the [MediaX] plugin to indicate that a
/// playback error has occurred. It is used to provide information about the
/// error to the developer and to help them debug the issue.
class PlaybackError {
  // Standard error codes
  /// Unknown error occurred.
  ///
  /// This error code is used when the error code is unknown or not specified.
  static const int unknown = 1000;

  /// Media source not found.
  ///
  /// This error code is used when the media source is invalid or not found.
  static const int sourceNotFound = 1001;

  /// Codec initialization failed.
  ///
  /// This error code is used when the codec initialization fails.
  static const int codecError = 1002;

  /// Network error occurred.
  ///
  /// This error code is used when a network error occurs during playback.
  static const int networkError = 1003;

  /// Playback timed out.
  ///
  /// This error code is used when the playback times out.
  static const int timeout = 1004;

  /// DRM decryption failed.
  ///
  /// This error code is used when the DRM decryption fails.
  static const int drmError = 1005;

  /// Playback failed due to an internal error.
  ///
  /// This error code is used when the playback fails due to an internal error.
  static const int internalError = 1006;

  /// Audio session error occurred.
  ///
  /// This error code is used when an audio session error occurs during playback.
  static const int audioSessionError = 1007;

  /// Media format is not supported.
  ///
  /// This error code is used when the media format is not supported.
  static const int unsupportedFormat = 1008;

  /// Invalid player state.
  ///
  /// This error code is used when the player is in an invalid state.
  static const int invalidState = 1009;

  /// Failed to allocate resources.
  ///
  /// This error code is used when the resources cannot be allocated.
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

  /// The error message describing the playback error.
  ///
  /// The message is a human-readable description of the error that occurred.
  /// It can be used to provide a user-friendly error message to the user.
  final String message;

  ///
  /// The error code identifying the type of error that occurred.
  ///
  /// The error code is one of the constants provided by the
  /// [PlaybackError] class, such as [unknown], [sourceNotFound], [codecError], etc.
  ///
  /// The error code can be used to identify the type of error that occurred
  /// and to provide a user-friendly error message to the user.
  ///
  final int errorCode;

  /// The stack trace of the error.
  ///
  /// The stack trace provides detailed information about where the error
  /// occurred in the code. It is helpful for debugging purposes and can be
  /// logged for further analysis.
  final String stackTrace;

  PlaybackError._(
      {required this.message,
      required this.errorCode,
      required this.stackTrace});

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

  /// Converts the [PlaybackError] object to a map.
  ///
  /// The returned map contains the following keys:
  ///
  /// * `errorCode`: The error code identifying the type of error that occurred.
  /// * `message`: The error message describing the playback error.
  /// * `stackTrace`: The stack trace of the error.
  ///
  /// The returned map is typically used to serialize the error to JSON or to
  /// pass the error to a platform channel.
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
