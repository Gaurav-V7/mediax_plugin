/// The different ways a video can be resized to fit its parent widget.
///
/// See also:
///
/// * [PlayerView.resizeMode], which controls how the video is resized.
enum ResizeMode {
  /// The video is resized to fit within its parent widget while maintaining its
  /// aspect ratio. Original video aspect ratio is preserved.
  fit,

  /// The video is resized to fit the entire parent widget, without maintaining
  /// its aspect ratio. This may cause the video to be distorted.
  stretch,

  /// The video is resized to fit the entire parent widget while maintaining its
  /// aspect ratio. This may cause some of the video to not be visible.
  crop,
}
