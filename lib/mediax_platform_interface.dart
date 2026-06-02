import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'mediax_method_channel.dart';

abstract class MediaxPlatform extends PlatformInterface {
  /// Constructs a MediaxPlatform.
  MediaxPlatform() : super(token: _token);

  static final Object _token = Object();

  static MediaxPlatform _instance = MethodChannelMediax();

  /// The default instance of [MediaxPlatform] to use.
  ///
  /// Defaults to [MethodChannelMediax].
  static MediaxPlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [MediaxPlatform] when
  /// they register themselves.
  static set instance(MediaxPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
