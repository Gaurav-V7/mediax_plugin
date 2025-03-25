/// Represents the various states a media player can be in during playback.
enum PlaybackState {
  /// The player is stopped or not playing anything.
  idle,

  /// A media item is currently being loaded.
  loading,

  /// The media item has loaded and is ready to play.
  ready,

  /// The media item is buffering or loading initially.
  buffering,

  /// The media item has completed playing after reaching the end.
  ended
}
