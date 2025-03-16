import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mediax/consts/strings.dart';
import 'package:mediax/enums/playback_state.dart';
import 'package:mediax/models/playback_error.dart';
import 'package:mediax/models/video_size.dart';
import 'package:uuid/uuid.dart';

import 'consts/consts.dart';
import 'models/data_source.dart';

class MediaX {
  late MethodChannel channel;

  late String id;
  String? currentUri =
      "https://rr3---sn-h557sn66.googlevideo.com/videoplayback?expire=1736883761&ei=0WmGZ5CyD4D4sfIPi8HOkQk&ip=154.212.13.178&id=o-APSfjXeUtFaHBnnyS7j0nzeW6wg1MIEJct3HbYmD4b4v&itag=18&source=youtube&requiressl=yes&xpc=EgVo2aDSNQ%3D%3D&bui=AY2Et-Nk4asDTPoxymPypU9yiqkNPfXRyfVgF3DJqPhg2I-TDuZBTOqmBNnWFz--Tv1YgbZAh2yN0Zn6&spc=9kzgDbSUuR61_41cnFJaKxPfVk3lsM73H_tY3QiYeuoUv7lpIcs3EjcBZXWP_2kleg&vprv=1&svpuc=1&mime=video%2Fmp4&ns=Qbm3YG2TBJIadIo2aUHdHFEQ&rqh=1&gir=yes&clen=22238675&ratebypass=yes&dur=248.662&lmt=1736021787624264&fexp=24350590,24350737,24350827,24350860,24350974,51326932,51335594,51353498,51355912,51371294&c=WEB&sefc=1&txp=5438434&n=6QOb7mX2HgokUA&sparams=expire%2Cei%2Cip%2Cid%2Citag%2Csource%2Crequiressl%2Cxpc%2Cbui%2Cspc%2Cvprv%2Csvpuc%2Cmime%2Cns%2Crqh%2Cgir%2Cclen%2Cratebypass%2Cdur%2Clmt&sig=AJfQdSswRAIgEmAnST7wt8WarHpF2yg5fpwS0JFi34ps6PrRTotkHhgCIF8R2ZVqY7mqYczsNofr6RLr8jysvYQrtw30FH-nZO2T&pot=MnT2LgSGDOaPTPYWX657QVoa3l64yPrlZQ_iSqCERqy0951Qgb7zgXNGCPVQNFklntXoYTAgu4NJAm5MdyxHwBho43me7_T35nSM3yQHM5X6yty4zmzJEpWNt-BkOmxvwJYKCt7ZVAXdBkT-nAVvGimjO2XdPA%3D%3D&range=0-&rm=sn-ab5ees7z,sn-gwpa-pmhd7l&rrc=104,80,40&req_id=80f30e44e90aa6e9&ipbypass=yes&cm2rm=sn-gwpa-o5bes76&rms=rdu,au&redirect_counter=3&cms_redirect=yes&cmsv=e&met=1736862166,&mh=0I&mip=2409:40c2:4057:f712:7132:316b:505:8faf&mm=30&mn=sn-h557sn66&ms=nxu&mt=1736861545&mv=m&mvi=3&pl=47&tso=0&lsparams=ipbypass,met,mh,mip,mm,mn,ms,mv,mvi,pl,rms,tso&lsig=AGluJ3MwRQIgKT7Tgm4OtyVqHpPg7W6xPXhZtjXyKC08aoKcERW9dLkCIQCJaNCasikjKDNDue8D4XA3Cz3QjYyq8H2437VhIg1nTg%3D%3D";
  bool autoplay = true;
  bool enableMediaSession = false;

  int forwardSeekSeconds = 10;
  int backwardSeekSeconds = 10;

  RxBool isFullScreen = false.obs;

  RxBool isInitialized = false.obs;
  Rx<PlaybackState> playbackState = PlaybackState.idle.obs;
  Rxn<PlaybackError> playbackError = Rxn<PlaybackError>();

  final Rx<VideoSize> _videoSize = VideoSize(1280, 720).obs;
  Stream<VideoSize> get videoSize => _videoSize.stream;

  final RxDouble _aspectRatio = (16 / 9).obs;
  Stream<double> get aspectRatio => _aspectRatio.stream;

  final RxDouble _playbackSpeed = (1.0).obs;
  double get playbackSpeed => _playbackSpeed.value;

  final RxBool isPlaying = false.obs;
  RxBool isMuted = false.obs;

  RxInt duration = 0.obs;
  RxInt position = 0.obs;
  RxInt bufferedPosition = 0.obs;

  MediaX._() {
    _videoSize.listen((videoSize) {
      final width = videoSize.width;
      final height = videoSize.height;
      _aspectRatio.value = width / height;
    });
  }

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
            // print('onPlaybackError: ${call.arguments}');
            final errorDetails = Map<String, dynamic>.from(call.arguments);
            mediaX.playbackError.value =
                PlaybackError.fromPlatform(errorDetails);
            break;
          case 'duration':
            print("method: duration: ${call.arguments}");
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
            print("Unknown method called");
        }
      });
      return mediaX;
    } catch (e) {
      throw Exception(
          "${Strings.errors.playerControllerInitializationError}\n$e");
    }
  }

  Future<void> playPause() async {
    try {
      await channel.invokeMethod(
        'playPause',
      );
    } on PlatformException catch (e) {
      print("Error while play/pause video: ${e.message}");
    }
  }

  Future<void> play() async {
    try {
      await channel.invokeMethod('play');
    } on PlatformException catch (e) {
      print("Error while playing the video: ${e.message}");
    }
  }

  Future<void> pause() async {
    try {
      await channel.invokeMethod('pause');
    } on PlatformException catch (e) {
      print("Error while pausing the video: ${e.message}");
    }
  }

  Future<void> setMediaItem(
      {required DataSource dataSource, bool autoplay = true}) async {
    try {
      channel.invokeMethod('setMediaItem',
          {'dataSource': dataSource.toMap(), 'autoplay': autoplay});
    } catch (e) {
      print("Error while setting the media item: $e");
    }
  }

  Future<bool> seekTo(double value) async {
    try {
      channel.invokeMethod('seekTo', value.toInt());
      return true;
    } on PlatformException catch (e) {
      print("Error while seeking the video: ${e.message}");
      return false;
    }
  }

  Future<void> seekForward() async {
    try {
      final seekMillis = position.value + (forwardSeekSeconds * 1000);
      await seekTo(seekMillis.toDouble());
    } catch (e) {
      print("Error while seeking forward: $e");
    }
  }

  Future<void> seekBackward() async {
    try {
      final seekMillis = position.value - (backwardSeekSeconds * 1000);
      await seekTo(seekMillis.toDouble());
    } catch (e) {
      print("Error while seeking backward: $e");
    }
  }

  Future<void> stop() async {
    try {
      await channel.invokeMethod('stop');
    } on PlatformException catch (e) {
      print("Error while stopping the video: ${e.message}");
    }
  }

  Future<void> setMuted(bool muted) async {
    try {
      isMuted.value = muted;
      await channel.invokeMethod('muted', muted);
    } on PlatformException catch (e) {
      print('Error while setting the muted state: ${e.message}');
    }
  }

  Future<void> toggleMute() async {
    try {
      isMuted.value = !isMuted.value;
      await channel.invokeMethod('muted', isMuted.value);
    } on PlatformException catch (e) {
      print('Error while toggling the muted state: ${e.message}');
    }
  }

  Future<void> setPlaybackSpeed(double speed) async {
    try {
      _playbackSpeed.value = speed;
      await channel.invokeMethod('playbackSpeed', speed);
    } on PlatformException catch (e) {
      print('Error while changing the playback speed: ${e.message}');
    }
  }
}
