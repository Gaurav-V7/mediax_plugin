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

class PlayerView extends StatefulWidget {
  final MediaX controller;
  final bool awakeScreenWhilePlaying;

  const PlayerView({
    super.key,
    required this.controller,
    this.awakeScreenWhilePlaying = false,
  });

  @override
  State<StatefulWidget> createState() => PlayerViewState();
}

class PlayerViewState extends State<PlayerView> {
  late MethodChannel _methodChannel;

  final RxBool isControllerVisible = true.obs;

  ResizeMode _resizeMode = ResizeMode.fit;
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

  void hideController() {
    isControllerVisible.value = false;
  }

  void showController() {
    isControllerVisible.value = true;
  }

  Future<void> setResizeMode(ResizeMode resizeMode) async {
    _methodChannel.invokeMethod('setResizeMode', resizeMode.index);
    setState(() {
      _resizeMode = resizeMode;
    });
  }

  void disableController(bool disable) {
    setState(() {
      _isControllerDisabled = disable;
    });
  }

  void toggleControllerVisibility() {
    isControllerVisible.value = !isControllerVisible.value;
  }
}
