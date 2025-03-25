import 'package:flutter/services.dart';

/// Constants
class Constants {
  /// Get Platform Channel Controller by Controller ID
  static MethodChannel getPlatformChannelController(String controllerId) {
    return MethodChannel("mediax_$controllerId");
  }

  /// Get Platform Channel View by Controller ID
  static MethodChannel getPlatformChannelView(String controllerId) {
    return MethodChannel("mediax:view_$controllerId");
  }
}
