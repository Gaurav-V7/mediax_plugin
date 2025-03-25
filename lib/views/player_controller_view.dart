// ignore_for_file: public_member_api_docs

import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:mediax/consts/colors.dart';
import 'package:mediax/consts/sizes.dart';
import 'package:mediax/enums/playback_state.dart';
import 'package:mediax/enums/resize_mode.dart';
import 'package:mediax/mediax.dart';
import 'package:mediax/utils/debouncer.dart';
import 'package:mediax/views/player_view.dart';

import 'slider_track_shape.dart';

class PlayerControllerView extends StatefulWidget {
  final PlayerViewState playerViewState;
  final MediaX playerController;

  const PlayerControllerView({
    super.key,
    required this.playerViewState,
    required this.playerController,
  });

  @override
  State<StatefulWidget> createState() => PlayerControllerViewState();
}

class PlayerControllerViewState extends State<PlayerControllerView> {
  final Debouncer debouncer =
      Debouncer(delay: const Duration(milliseconds: 250));

  late MediaX playerController;
  RxDouble seekbarPosition = 0.0.obs;
  StreamSubscription? _positionSubscription;

  bool _isDragging = false;
  bool _restorePlayState = false;
  Timer? _seekTimer;
  Timer? _hideTimer;
  bool _isControllerInFocus = false;
  double _lastSeekPosition = 0.0;
  // bool _isShowingRemainingDuration = false;

  @override
  void initState() {
    super.initState();
    WidgetsFlutterBinding.ensureInitialized();
    playerController = widget.playerController;

    seekbarPosition.value = playerController.position.value.toDouble();

    WidgetsBinding.instance.addPostFrameCallback((_) {});

    _positionSubscription?.cancel();

    _positionSubscription = playerController.position.listen((position) {
      seekbarPosition.value = position.toDouble();
    });

    if (widget.playerViewState.isControllerVisible.value) {
      _setupAutoHide();
    }

    ever(widget.playerViewState.isControllerVisible, (bool visible) {
      if (visible && !_isControllerInFocus) {
        _setupAutoHide();
      }
    });
  }

  void _setupAutoHide() {
    _hideTimer?.cancel();
    _hideTimer = Timer(const Duration(seconds: 3), () {
      if (widget.playerViewState.isControllerVisible.value &&
          !_isControllerInFocus &&
          !_isDragging &&
          playerController.isPlaying.value) {
        widget.playerViewState.hideController();
      }
    });
  }

  void _cancelAutoHide() {
    _hideTimer?.cancel();
  }

  Widget _buildTimeDisplay(double time) {
    return Text(
      formatElapsedTime(time),
      style: const TextStyle(
          color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
    );
  }

  Widget _buildProgressSlider() {
    return Focus(
      onFocusChange: (hasFocus) {
        _isControllerInFocus = hasFocus;
        if (hasFocus) {
          _cancelAutoHide();
        } else if (widget.playerViewState.isControllerVisible.value &&
            !_isDragging) {
          _setupAutoHide();
        }
      },
      child: SizedBox(
        height: 30,
        child: SliderTheme(
          data: SliderThemeData(
            trackHeight: Sizes.seekbar.trackHeight,
            trackShape: SeekbarTrackShape(),
            thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
            overlayShape: const RoundSliderOverlayShape(overlayRadius: 12),
            inactiveTrackColor: AppColors.seekbar.inactiveTrackColor,
            secondaryActiveTrackColor: AppColors.seekbar.bufferedTrackColor,
          ),
          child: Slider(
            min: 0.0,
            max: playerController.duration.value.toDouble(),
            value: seekbarPosition.value
                .clamp(0.0, playerController.duration.value.toDouble()),
            secondaryTrackValue: playerController.bufferedPosition.value
                .toDouble()
                .clamp(0.0, playerController.duration.value.toDouble()),
            onChangeStart: _handleSliderChangeStart,
            onChangeEnd: _handleSliderChangeEnd,
            onChanged: _handleSliderChange,
          ),
        ),
      ),
    );
  }

  void _handleSliderChangeStart(double val) {
    _isDragging = true;
    _lastSeekPosition = val;
    _restorePlayState = playerController.isPlaying.value;
    if (_restorePlayState) {
      playerController.pause();
    }
    _cancelAutoHide();
  }

  void _handleSliderChangeEnd(double val) {
    _isDragging = false;
    _seekTimer?.cancel();

    if (_lastSeekPosition != val) {
      playerController.seekTo(val).then((_) {
        if (_restorePlayState) {
          _restorePlayState = false;
          playerController.play();
        }
      });
    }

    if (!_isControllerInFocus) {
      _setupAutoHide();
    }
  }

  void _handleSliderChange(double val) {
    seekbarPosition.value = val;
  }

  double getAdjustedSeekbarPosition(double position) {
    // Check if position is less than 0
    if (position < 0 || position > playerController.duration.value.toDouble()) {
      return 0.0; // Ensure it's at the start if negative
    }

    // Return the valid position
    return position;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: toggleVisibility,
      child: Obx(
        () => Container(
          color: Colors.black38,
          padding: const EdgeInsets.all(10.0),
          child: Stack(
            children: [
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                top: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    IconButton(
                        onPressed: () => playerController.seekBackward(),
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.gobackward,
                              color: Colors.white,
                              size: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.5),
                              child: Text(
                                "${playerController.backwardSeekSeconds.toInt()}",
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            )
                          ],
                        )),
                    const SizedBox(
                      width: 30,
                    ),
                    SizedBox(
                      width: 60, // Ensure consistent width
                      height: 60, // Ensure consistent height
                      child: Center(
                        // Centers the widget inside the SizedBox
                        child: playerController.playbackState.value ==
                                    PlaybackState.buffering ||
                                playerController.playbackState.value ==
                                    PlaybackState.loading
                            ? const CircularProgressIndicator(
                                color: Colors.white,
                                strokeAlign: BorderSide.strokeAlignOutside,
                                strokeCap: StrokeCap.round,
                              )
                            : GestureDetector(
                                onTap: playerController.playPause,
                                child: Icon(
                                  playerController.isPlaying.value
                                      ? Icons.pause_rounded
                                      : Icons.play_arrow_rounded,
                                  color: Colors.white,
                                  size: 60,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(
                      width: 30,
                    ),
                    IconButton(
                        onPressed: () => playerController.seekForward(),
                        icon: Stack(
                          alignment: Alignment.center,
                          children: [
                            const Icon(
                              CupertinoIcons.goforward,
                              color: Colors.white,
                              size: 30,
                            ),
                            Padding(
                              padding: const EdgeInsets.only(top: 2.5),
                              child: Text(
                                "${playerController.forwardSeekSeconds.toInt()}",
                                style: const TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white),
                              ),
                            )
                          ],
                        )),
                  ],
                ),
              ),
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    _buildTimeDisplay(seekbarPosition.value),
                    Expanded(
                      child: _buildProgressSlider(),
                    ),
                    _buildTimeDisplay(
                        playerController.duration.value.toDouble()),
                    extraControlButton(
                        onPressed: () async {
                          await playerController.toggleMute();
                        },
                        icon: Icon(
                          playerController.isMuted.value
                              ? CupertinoIcons.volume_off
                              : CupertinoIcons.volume_up,
                          color: Colors.white,
                        )),
                    extraControlButton(
                        onPressed: () async {
                          toggleResizeMode();
                        },
                        icon: const Icon(
                          CupertinoIcons.resize,
                          color: Colors.white,
                        )),
                    extraControlButton(
                        onPressed: () async {
                          hide();
                          playerController.isFullScreen.value =
                              !playerController.isFullScreen.value;
                        },
                        icon: const Icon(
                          Icons.fullscreen_rounded,
                          color: Colors.white,
                        )),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void toggleResizeMode() {
    final currentResizeMode = widget.playerViewState.resizeMode;
    if (currentResizeMode == ResizeMode.fit) {
      widget.playerViewState.setResizeMode(ResizeMode.stretch);
    } else if (currentResizeMode == ResizeMode.stretch) {
      widget.playerViewState.setResizeMode(ResizeMode.crop);
    } else if (currentResizeMode == ResizeMode.crop) {
      widget.playerViewState.setResizeMode(ResizeMode.fit);
    }
  }

  void toggleVisibility() {
    widget.playerViewState.toggleControllerVisibility();
  }

  void show() {
    widget.playerViewState.showController();
  }

  void hide() {
    widget.playerViewState.hideController();
  }

  String formatElapsedTime(double timeInSeconds) {
    final duration = Duration(milliseconds: timeInSeconds.toInt());
    final hours = duration.inHours;
    final minutes = duration.inMinutes % 60;
    final seconds = duration.inSeconds % 60;

    if (hours > 0) {
      return '${NumberFormat('00').format(hours)}:${NumberFormat('00').format(minutes)}:${NumberFormat('00').format(seconds)}';
    } else {
      return '${NumberFormat('00').format(minutes)}:${NumberFormat('00').format(seconds)}';
    }
  }

  Widget extraControlButton({
    double iconSize = 25,
    required VoidCallback onPressed,
    required Icon icon,
  }) {
    return IconButton(iconSize: iconSize, onPressed: onPressed, icon: icon);
  }
}
