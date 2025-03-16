import 'package:flutter/material.dart';
import 'package:mediax/consts/sizes.dart';

class SeekbarTrackShape extends RoundedRectSliderTrackShape {
  @override
  Rect getPreferredRect({
    required RenderBox parentBox,
    Offset offset = Offset.zero,
    required SliderThemeData sliderTheme,
    bool isEnabled = false,
    bool isDiscrete = false,
  }) {
    final double trackHeight = sliderTheme.trackHeight ?? 0;
    final double horizontalPadding = Sizes.spacing.medium;
    final double trackLeft = offset.dx + horizontalPadding;
    final double trackTop =
        offset.dy + (parentBox.size.height - trackHeight) / 2;
    final double trackWidth = parentBox.size.width - (2 * horizontalPadding);
    return Rect.fromLTWH(trackLeft, trackTop, trackWidth, trackHeight);
  }
}
