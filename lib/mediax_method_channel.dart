import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'mediax_platform_interface.dart';

/// An implementation of [MediaxPlatform] that uses method channels.
class MethodChannelMediax extends MediaxPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('mediax');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>('getPlatformVersion');
    return version;
  }
}
