import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mediax/consts/strings.dart';
import 'package:mediax/enums/playback_state.dart';
import 'package:mediax/models/playback_error.dart';
import 'package:mediax/models/video_size.dart';
import 'package:uuid/uuid.dart';

import 'consts/consts.dart';
import 'models/data_source.dart';

/// The main entry point for the MediaX plugin.
class MediaX {
  /// The method channel used to communicate with the native code.
  late MethodChannel channel;

  /// Id of the player instance
  late String id;

  /// The current URI of the video being played.
  String? currentUri = "";

  /// Whether the player should start playing the video automatically when
  /// initialized.
  ///
  /// Defaults to `true`.
  bool autoplay = true;

  /// Whether to enable the media session.
  ///
  /// This is used to control media notifications and media controls on the lock screen.
  /// Defaults to `false`.
  bool enableMediaSession = false;

  /// The number of seconds to seek forward when the user taps on the
  /// forward button.
  ///
  /// Defaults to `10`.
  int forwardSeekSeconds = 10;

  /// The number of seconds to seek backward when the user taps on the
  /// backward button.
  ///
  /// Defaults to `10`.
  ///
  int backwardSeekSeconds = 10;

  /// Whether the player is currently in full screen mode.
  ///
  /// This is a read only property, use [setFullScreen] to change the value.
  ///
  RxBool isFullScreen = false.obs;

  /// Whether the player is currently initialized.
  ///
  /// This is a read only property, the value is set by the native code.
  ///
  /// This property is used to check if the player is ready to use.
  ///
  /// When the value is `true`, the player is ready to use.
  ///
  /// When the value is `false`, the player is not ready to use.
  ///
  RxBool isInitialized = false.obs;

  /// The current state of the media playback.
  ///
  /// This observable tracks the playback state, which can be one of the
  /// following:
  /// - `PlaybackState.idle`: The player is stopped or not playing anything.
  /// - `PlaybackState.loading`: A media item is currently being loaded.
  /// - `PlaybackState.ready`: The media item has loaded and is ready to play.
  /// - `PlaybackState.buffering`: The media item is buffering or loading initially.
  /// - `PlaybackState.ended`: The media item has completed playing after reaching the end.
  Rx<PlaybackState> playbackState = PlaybackState.idle.obs;

  ///
  /// The error that occurred during playback.
  ///
  /// This observable is notified when an error occurs during playback.
  ///
  /// The error can be one of the following:
  /// - `PlaybackError.networkError`: A network error occurred while playing
  ///   the media item.
  /// - `PlaybackError.codecError`: A codec error occurred while playing the
  ///   media item.
  /// - `PlaybackError.timeout`: A timeout occurred while playing the media
  ///   item.
  /// - `PlaybackError.drmError`: A DRM error occurred while playing the media
  ///   item.
  /// - `PlaybackError.internalError`: An internal error occurred while playing
  ///   the media item.
  /// - `null`: No error occurred.
  ///
  Rxn<PlaybackError> playbackError = Rxn<PlaybackError>();

  final Rx<VideoSize> _videoSize = VideoSize(1280, 720).obs;

  ///
  /// A stream of video sizes.
  ///
  /// This stream emits the video size whenever it changes.
  ///
  /// The video size is a [VideoSize] object, which contains the width and height
  /// of the video.
  ///
  Stream<VideoSize> get videoSize => _videoSize.stream;

  final RxDouble _aspectRatio = (16 / 9).obs;

  ///
  /// A stream of aspect ratios.
  ///
  /// This stream emits the aspect ratio of the video whenever it changes.
  ///
  /// The aspect ratio is the ratio of the video's width to its height.
  ///
  Stream<double> get aspectRatio => _aspectRatio.stream;

  final RxDouble _playbackSpeed = (1.0).obs;

  ///
  /// The current playback speed of the video.
  ///
  /// This property can be set to change the playback speed of the video.
  ///
  /// The default value is 1.0.
  ///
  /// A value of 1.0 indicates normal playback speed.
  ///
  /// A value of 2.0 indicates playback at twice the normal speed.
  ///
  /// A value of 0.5 indicates playback at half the normal speed.
  ///
  double get playbackSpeed => _playbackSpeed.value;

  /// A stream of boolean values indicating whether the video is playing or not.
  ///
  /// This stream emits a boolean value whenever the video starts or stops playing.
  ///
  /// The value emitted is `true` if the video is playing and `false` if it is not.
  ///
  /// The default value is `false`.
  ///
  final RxBool isPlaying = false.obs;

  /// Whether the audio is currently muted.
  ///
  /// This is a read-write property. Set this property to `true` to mute the
  /// audio and to `false` to unmute it.
  ///
  /// The default value is `false`.
  RxBool isMuted = false.obs;

  /// The duration of the media in milliseconds.
  ///
  /// This observable holds the total duration of the currently loaded media item.
  /// The value is updated whenever a new media item is loaded or the duration changes.
  ///
  /// The default value is `0`, indicating that no media item is currently loaded or the duration is unknown.
  ///
  RxInt duration = 0.obs;

  ///
  /// The current position of the media in milliseconds.
  ///
  /// This observable holds the current position of the currently loaded media item.
  /// The value is updated whenever the position changes.
  ///
  /// The default value is `0`, indicating that no media item is currently loaded.
  ///
  RxInt position = 0.obs;

  /// The buffered position of the media in milliseconds.
  ///
  /// This observable holds the buffered position of the currently loaded media item.
  /// The value is updated whenever the buffered position changes.
  ///
  /// The default value is `0`, indicating that no media item is currently loaded or the buffered position is unknown.
  ///
  RxInt bufferedPosition = 0.obs;

  MediaX._() {
    _videoSize.listen((videoSize) {
      final width = videoSize.width;
      final height = videoSize.height;
      _aspectRatio.value = width / height;
    });
  }

  /// Initialize the MediaX plugin.
  ///
  /// This method creates a new instance of the MediaX class and initializes the plugin.
  ///
  /// The [dataSource] parameter is optional. If it is provided, the plugin will load the media
  /// item and start playing it if [autoplay] is `true`.
  ///
  /// The [autoplay] parameter is optional. If it is `true`, the plugin will start playing the
  /// media item as soon as it is loaded. The default value is `false`.
  ///
  /// The [enableMediaSession] parameter is optional. If it is `true`, the plugin will be used
  /// to control the media playback. The default value is `false`.
  ///
  /// Returns a new instance of the MediaX class.
  ///
  static MediaX init(
      {DataSource? dataSource,
      bool autoplay = true,
      bool enableMediaSession = false}) {
    try {
      final mediaX = MediaX._();
      mediaX.id = const Uuid().v4();

      if (dataSource != null) {
        mediaX.currentUri = dataSource.uri;
        mediaX.autoplay = autoplay;
      }
      mediaX.enableMediaSession = enableMediaSession;
      mediaX.channel = Constants.getPlatformChannelController(mediaX.id);

      final Map<String, dynamic> params = {'controllerId': mediaX.id};
      if (dataSource != null) {
        params['dataSource'] = dataSource.toMap();
        params['autoplay'] = mediaX.autoplay;
      }
      params['enableMediaSession'] = mediaX.enableMediaSession;
      const MethodChannel("mediax").invokeMethod('initPlayer', params);

      mediaX.channel.setMethodCallHandler((MethodCall call) async {
        switch (call.method) {
          case 'isInitialized':
            mediaX.isInitialized.value = call.arguments;
            break;
          case 'isPlaying':
            mediaX.isPlaying.value = call.arguments;
            break;
          case 'onPlaybackStateChanged':
            mediaX.playbackState.value =
                PlaybackState.values[call.arguments as int];
            break;
          case 'onPlaybackError':
            final errorDetails = Map<String, dynamic>.from(call.arguments);
            mediaX.playbackError.value =
                PlaybackError.fromPlatform(errorDetails);
            break;
          case 'duration':
            mediaX.duration.value = call.arguments;
            break;
          case 'currentPosition':
            mediaX.position.value = call.arguments;
            break;
          case 'bufferedPosition':
            mediaX.bufferedPosition.value = call.arguments;
          case 'onVideoSizeChanged':
            final videoSize =
                VideoSize(call.arguments['width'], call.arguments['height']);
            mediaX._videoSize.value = videoSize;
          default:
            debugPrint("Unknown method called off MediaX: ${call.method}");
        }
      });
      return mediaX;
    } catch (e) {
      throw Exception(
          "${Strings.errors.playerControllerInitializationError}\n$e");
    }
  }

  /// Play or pause the video.
  ///
  /// This method will toggle the playback state of the video.
  ///
  /// If the video is currently playing, it will be paused. If the video is
  /// currently paused, it will be played.
  ///
  Future<void> playPause() async {
    try {
      await channel.invokeMethod(
        'playPause',
      );
    } on PlatformException catch (e) {
      debugPrint("Error while play/pause video: ${e.message}");
    }
  }

  /// Play the video.
  ///
  /// This method will play the video if it is not playing. If the video is
  /// currently playing, this method will do nothing.
  ///
  Future<void> play() async {
    try {
      await channel.invokeMethod('play');
    } on PlatformException catch (e) {
      debugPrint("Error while playing the video: ${e.message}");
    }
  }

  /// Pause the video.
  ///
  /// This method will pause the video if it is playing.
  ///
  Future<void> pause() async {
    try {
      await channel.invokeMethod('pause');
    } on PlatformException catch (e) {
      debugPrint("Error while pausing the video: ${e.message}");
    }
  }

  /// Sets the media item for playback.
  ///
  /// This method updates the current media item with the provided [dataSource].
  /// The [autoplay] parameter determines whether playback should start
  /// automatically after setting the media item. By default, [autoplay] is
  /// `true`.
  ///
  /// If there's an error during the process, it will be logged.
  ///
  /// - Parameters:
  ///   - [dataSource]: The data source containing media information.
  ///   - [autoplay]: Boolean flag to autoplay media after setting.
  ///
  /// Throws an [Exception] if setting the media item fails.
  Future<void> setMediaItem(
      {required DataSource dataSource, bool autoplay = true}) async {
    try {
      channel.invokeMethod('setMediaItem',
          {'dataSource': dataSource.toMap(), 'autoplay': autoplay});
    } catch (e) {
      debugPrint("Error while setting the media item: $e");
    }
  }

  /// Seeks to the specified time in the video.
  ///
  /// This method will seek the video to the specified [value] in milliseconds.
  /// If the video is not ready or has an error, this method will return `false`.
  /// If the seek is successful, this method will return `true`.
  ///
  /// - Parameters:
  ///   - [value]: The time in milliseconds to seek to.
  ///
  Future<bool> seekTo(double value) async {
    try {
      channel.invokeMethod('seekTo', value.toInt());
      return true;
    } on PlatformException catch (e) {
      debugPrint("Error while seeking the video: ${e.message}");
      return false;
    }
  }

  /// Seeks the video forward by the specified number of seconds.
  ///
  /// This method will seek the video forward by [forwardSeekSeconds] seconds.
  /// If the video is not ready or has an error, this method will do nothing.
  ///
  /// - Parameters:
  ///   - [forwardSeekSeconds]: The number of seconds to seek forward by.
  ///
  /// Throws an [Exception] if seeking the video fails.
  Future<void> seekForward() async {
    try {
      final seekMillis = position.value + (forwardSeekSeconds * 1000);
      await seekTo(seekMillis.toDouble());
    } catch (e) {
      debugPrint("Error while seeking forward: $e");
    }
  }

  /// Seeks the video backward by the specified number of seconds.
  ///
  /// This method will seek the video backward by [backwardSeekSeconds] seconds.
  /// If the video is not ready or has an error, this method will do nothing.
  ///
  /// - Parameters:
  ///   - [backwardSeekSeconds]: The number of seconds to seek backward by.
  ///
  /// Throws an [Exception] if seeking the video fails.
  Future<void> seekBackward() async {
    try {
      final seekMillis = position.value - (backwardSeekSeconds * 1000);
      await seekTo(seekMillis.toDouble());
    } catch (e) {
      debugPrint("Error while seeking backward: $e");
    }
  }

  /// Stops the video playback.
  ///
  /// This method will stop the video playback and reset the position to 0.
  ///
  Future<void> stop() async {
    try {
      await channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      debugPrint("Error while stopping the video: ${e.message}");
    }
  }

  /// Sets the video player's muted state.
  ///
  /// This method will set the video player's muted state to the specified [muted] value.
  ///
  /// - Parameters:
  ///   - [muted]: The value to set the muted state to.
  ///
  Future<void> setMuted(bool muted) async {
    try {
      isMuted.value = muted;
      await channel.invokeMethod('muted', muted);
    } on PlatformException catch (e) {
      debugPrint('Error while setting the muted state: ${e.message}');
    }
  }

  /// Toggles the video player's muted state.
  ///
  /// This method will toggle the video player's muted state.
  ///
  /// Throws an [Exception] if toggling the muted state fails.
  Future<void> toggleMute() async {
    try {
      isMuted.value = !isMuted.value;
      await channel.invokeMethod('muted', isMuted.value);
    } on PlatformException catch (e) {
      debugPrint('Error while toggling the muted state: ${e.message}');
    }
  }

  /// Sets the video player's playback speed.
  ///
  /// This method will set the video player's playback speed to the specified [speed] value.
  ///
  /// - Parameters:
  ///   - [speed]: The value to set the playback speed to.
  ///
  /// Throws an [Exception] if setting the playback speed fails.
  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed.value = speed;
      await channel.invokeMethod('playbackSpeed', speed);
    } on PlatformException catch (e) {
      debugPrint('Error while changing the playback speed: ${e.message}');
    }
  }

  /// Releases the resources used by the video player.
  ///
  /// This method will release the resources used by the video player.
  ///
  Future<void> dispose() async {
    try {
      await channel.invokeMethod('releasePlayer');
    } on PlatformException catch (e) {
      debugPrint('Error while disposing the player: ${e.message}');
    }
  }
}
