import 'package:flutter/services.dart';

class Constants {
  static MethodChannel getPlatformChannelController(String controllerId) {
    return MethodChannel("mediax_$controllerId");
  }

  static MethodChannel getPlatformChannelView(String controllerId) {
    return MethodChannel("mediax:view_$controllerId");
  }
}
