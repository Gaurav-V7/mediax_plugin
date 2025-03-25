import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:mediax/consts/consts.dart';
import 'package:mediax/consts/sizes.dart';
import 'package:mediax/enums/resize_mode.dart';
import 'package:mediax/mediax.dart';
import 'package:mediax/views/player_controller_view.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

/// A widget that displays a video player and its associated controller.
///
/// This widget is used to display a video player and its associated controller.
/// It is used by the [MediaX] widget to display the video player and its
/// associated controller.
///
/// The [PlayerView] widget takes a [MediaX] object as a parameter, which is
/// used to control the video player.
///
/// The [awakeScreenWhilePlaying] parameter is used to determine whether to
/// keep the screen on while the video is playing. If this parameter is set to
/// [true], the screen will be kept on while the video is playing.
///
/// The [PlayerView] widget is responsible for displaying the video player and
/// its associated controller. It also handles the logic for keeping the screen
/// on while the video is playing.
///
/// The [PlayerView] widget is used by the [MediaX] widget to display the video
/// player and its associated controller. It is not intended to be used
/// directly. Instead, use the [MediaX] widget to display a video player and its
/// associated controller.
class PlayerView extends StatefulWidget {
  /// The controller used to manage video playback.
  ///
  /// This controller is an instance of the [MediaX] class and provides
  /// functionalities to control and interact with the video player.
  final MediaX controller;

  /// Whether to keep the screen on while the video is playing.
  ///
  /// If this parameter is set to [true], the screen will be kept on while the
  /// video is playing. If this parameter is set to [false], the screen will be
  /// allowed to turn off while the video is playing.
  final bool awakeScreenWhilePlaying;

  /// Creates a [PlayerView] widget.
  ///
  /// The [controller] parameter is required and is used to manage video
  /// playback.
  ///
  /// The [awakeScreenWhilePlaying] parameter is optional and defaults to
  /// [false]. It is used to determine whether to keep the screen on while the
  /// video is playing. If this parameter is set to [true], the screen will be
  /// kept on while the video is playing. If this parameter is set to [false],
  /// the screen will be allowed to turn off while the video is playing.
  const PlayerView({
    super.key,
    required this.controller,
    this.awakeScreenWhilePlaying = false,
  });

  @override
  State<StatefulWidget> createState() => PlayerViewState();
}

/// The state class for the [PlayerView] widget.
///
/// This class is responsible for storing the state of the [PlayerView] widget.
/// It provides methods for getting and setting the state of the [PlayerView]
/// widget.
///
/// The [PlayerViewState] class is used by the [PlayerView] widget to store its
/// state. It is not intended to be used directly. Instead, use the [PlayerView]
/// widget to display a video player and its associated controller.
class PlayerViewState extends State<PlayerView> {
  late MethodChannel _methodChannel;

  /// Indicates whether the video controller is visible.
  ///
  /// This is a reactive boolean value that is used to control the visibility
  /// of the video controller. By default, it is set to `true`, meaning the
  /// controller is visible.
  final RxBool isControllerVisible = true.obs;

  ResizeMode _resizeMode = ResizeMode.fit;

  /// Returns the current resize mode of the video player.
  ///
  /// This getter provides the current resize mode, which determines how the video
  /// player is resized within its parent widget.
  ResizeMode get resizeMode => _resizeMode;

  bool _isControllerDisabled = false;

  @override
  void initState() {
    super.initState();
    _methodChannel = Constants.getPlatformChannelView(widget.controller.id);
    widget.controller.isPlaying.listen((isPlaying) {
      if (widget.awakeScreenWhilePlaying) {
        WakelockPlus.toggle(enable: isPlaying);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        _playerView(),
        GestureDetector(
          behavior: HitTestBehavior.translucent,
          onTap: toggleControllerVisibility,
        ),
        Obx(() => Visibility(
            visible: isControllerVisible.value, child: _playerController())),
      ],
    );
  }

  Widget _playerView() {
    final creationParams = {
      'controllerId': widget.controller.id,
    };
    const viewType = 'video_view';
    const messageCodec = StandardMessageCodec();
    if (Platform.isAndroid) {
      return PlatformViewLink(
        viewType: viewType,
        surfaceFactory: (context, controller) {
          return AndroidViewSurface(
            controller: controller as AndroidViewController,
            hitTestBehavior: PlatformViewHitTestBehavior.opaque,
            gestureRecognizers: const <Factory<OneSequenceGestureRecognizer>>{},
          );
        },
        onCreatePlatformView: (params) {
          return PlatformViewsService.initSurfaceAndroidView(
              id: params.id,
              viewType: viewType,
              layoutDirection: TextDirection.ltr,
              creationParams: creationParams,
              creationParamsCodec: messageCodec,
              onFocus: () {
                params.onFocusChanged(true);
              })
            ..addOnPlatformViewCreatedListener(params.onPlatformViewCreated)
            ..create();
        },
      );
    } else if (Platform.isIOS) {
      return UiKitView(
        viewType: 'video_view',
        creationParams: creationParams,
        creationParamsCodec: messageCodec,
        onPlatformViewCreated: (id) {},
      );
    } else {
      return Container(
        color: Colors.black,
        padding: EdgeInsets.all(Sizes.spacing.medium),
        child: const Text("View not supported on your platform"),
      );
    }
  }

  Widget _playerController() {
    if (_isControllerDisabled) {
      return const SizedBox.shrink();
    } else {
      return PlayerControllerView(
        playerViewState: this,
        playerController: widget.controller,
      );
    }
  }

  /// Hide the video controller.
  ///
  /// This method will hide the video controller if it is currently shown.
  ///
  void hideController() {
    isControllerVisible.value = false;
  }

  /// Show the video controller.
  ///
  /// This method will show the video controller if it is currently hidden.
  ///
  void showController() {
    isControllerVisible.value = true;
  }

  /// Set the resize mode of the video player.
  ///
  /// This method will set the resize mode of the video player to the specified [resizeMode].
  ///
  /// The [resizeMode] parameter determines how the video player is resized. The possible values
  /// are:
  ///
  /// * [ResizeMode.fit]: The video player is resized to fit within its parent widget while maintaining its
  ///   aspect ratio. Original video aspect ratio is preserved.
  /// * [ResizeMode.stretch]: The video player is resized to fit the entire parent widget, without maintaining
  ///   its aspect ratio. This may cause the video to be distorted.
  /// * [ResizeMode.crop]: The video player is resized to fit the entire parent widget while maintaining its
  ///   aspect ratio. This may cause some of the video to not be visible.
  ///
  /// The video player cannot be interacted with while it is resizing.
  ///
  /// Returns a [Future] that completes when the resize is complete.
  ///
  /// - Parameters:
  ///   - [resizeMode]: The value to set the resize mode to.
  Future<void> setResizeMode(ResizeMode resizeMode) async {
    _methodChannel.invokeMethod('setResizeMode', resizeMode.index);
    setState(() {
      _resizeMode = resizeMode;
    });
  }

  /// Disable the video controller.
  ///
  /// This method will disable the video controller.
  ///
  /// If [disable] is `true`, the controller will be disabled. If [disable] is
  /// `false`, the controller will be enabled.
  ///
  /// The controller cannot be interacted with while it is disabled.
  void disableController(bool disable) {
    setState(() {
      _isControllerDisabled = disable;
    });
  }

  /// Toggle the visibility of the video controller.
  ///
  /// This method will toggle the visibility of the video controller.
  ///
  /// If the controller is currently visible, it will be hidden. If the controller
  /// is currently hidden, it will be shown.
  void toggleControllerVisibility() {
    isControllerVisible.value = !isControllerVisible.value;
  }
}
