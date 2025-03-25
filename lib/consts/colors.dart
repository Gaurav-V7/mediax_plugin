import 'dart:ui';

/// Colors for the plugin
class AppColors {
  /// Colors for the seekbar
  static final seekbar = _Seekbar();
}

class _Seekbar {
  /// Color to show the inactive part of the seekbar
  final inactiveTrackColor = const Color(0xE0423D3D);

  /// Color to show the buffered part of the seekbar
  final bufferedTrackColor = const Color(0xFFA5A5A5);
}
