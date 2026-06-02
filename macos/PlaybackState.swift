enum PlaybackState: Int {
    case idle = 0
    case loading
    case ready
    case buffering
    case ended
}
