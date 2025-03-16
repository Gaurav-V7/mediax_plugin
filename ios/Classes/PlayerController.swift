import Foundation
import AVFoundation
import Flutter

class PlayerController: NSObject {
    var player: AVPlayer? { // Make player accessible but still internally managed
        return _player
    }
    private var _player: AVPlayer?
    private var timeObserverToken: Any?
    private let methodChannel: FlutterMethodChannel
    private let registrar: FlutterPluginRegistrar
    private var isPositionUpdaterRunning = false
    private let updateInterval: TimeInterval = 0.1 // 100ms same as Android
    private var currentVolume: Float = 0
    private var playbackSpeed: Float = 1.0
    
    init(methodChannel: FlutterMethodChannel, registrar: FlutterPluginRegistrar) {
        self.methodChannel = methodChannel
        self.registrar = registrar
        super.init()
        setupPlayer()
        populatePlayerState()
        setupMethodCallHandler()
    }
    
    
    private func setupPlayer() {
        // Initialize player if needed
        if _player == nil {
            _player = AVPlayer()
            _player?.actionAtItemEnd = .pause
            
            // Add rate observer to handle playback state changes
            _player?.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
        }
        setupPlayerObservers()
    }
    
    private func populatePlayerState() {
        currentVolume = getPlayerVolume()
    }
    
    private func setupPlayerObservers() {
        // Remove any existing observers first
        if let timeObserverToken = timeObserverToken {
            _player?.removeTimeObserver(timeObserverToken)
            self.timeObserverToken = nil
        }
        
        // Time observer for position updates
        let interval = CMTime(seconds: updateInterval, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        timeObserverToken = _player?.addPeriodicTimeObserver(forInterval: interval, queue: .main) { [weak self] time in
            self?.sendCurrentPosition()
        }
        
        // Status observer for player
        _player?.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        
        // Status observer for player item
        if let currentItem = _player?.currentItem {
            currentItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        }
        
        // Rate observer for play/pause state
        _player?.addObserver(self, forKeyPath: "rate", options: [.new, .old], context: nil)
        
        // Add notification observer for when item finishes playing
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(playerItemDidReachEnd),
                                               name: .AVPlayerItemDidPlayToEndTime,
                                               object: nil)
    }
    
    private func handleAVError(_ error: NSError) -> [String: Any] {
        pauseVideo()
        let errorCode: Int
        
        // First check if it's a network error from URLError
        if error.domain == NSURLErrorDomain {
            print("Error Code: \(error.code)")
            switch error.code {
            case NSURLErrorNotConnectedToInternet, NSURLErrorNetworkConnectionLost, NSURLErrorTimedOut:
                errorCode = 1003 // networkError
            case NSURLErrorUnsupportedURL, NSURLErrorCannotFindHost, NSURLErrorFileDoesNotExist:
                errorCode = 1001 // sourceNotFound
            default:
                errorCode = 1000 // unknown
            }
        }
        // Then check AVFoundation errors
        else if error.domain == AVFoundationErrorDomain {
            if let avErrorCode = AVError.Code(rawValue: error.code) {
                switch avErrorCode {
                case .formatUnsupported, .decoderNotFound:
                    errorCode = 1008 // unsupportedFormat
                case .contentIsProtected:
                    errorCode = 1005 // drmError
                case .noLongerPlayable:
                    errorCode = 1006 // internalError
                case .mediaServicesWereReset:
                    errorCode = 1006 // internalError
                default:
                    errorCode = 1000
                }
            } else {
                errorCode = 1000 // unknown
            }
        } else {
            errorCode = 1000 // unknown
        }
        
        return [
            Constants.ERROR_CODE: errorCode,
            Constants.STACK_TRACE: "\(error.debugDescription)\nDomain: \(error.domain)\nCode: \(error.code)"
        ]
    }
    
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        if keyPath == "status" {
            if object as? AVPlayer == _player {
                // Handle player status
                switch _player?.status {
                case .failed:
                    if let error = _player?.error as NSError? {
                        let errorDetails = handleAVError(error)
                        methodChannel.invokeMethod(Constants.ON_PLAYBACK_ERROR, arguments: errorDetails)
                    }
                case .unknown:
                    methodChannel.invokeMethod(Constants.ON_PLAYBACK_STATE_CHANGED, arguments: PlaybackState.idle.rawValue)
                default:
                    break
                }
            } else if  object as? AVPlayerItem == _player?.currentItem {
                // Handle player item status
                if _player?.currentItem?.status == .readyToPlay {
                    methodChannel.invokeMethod(Constants.ON_PLAYBACK_STATE_CHANGED, arguments: PlaybackState.ready.rawValue)
                    if let videoSize = getVideoSize(), videoSize.width > 0, videoSize.height > 0 {
                        let videoSizeData: [String: Any] = [
                            Constants.WIDTH: Int(videoSize.width),
                            Constants.HEIGHT: Int(videoSize.height)
                        ]
                        methodChannel.invokeMethod(Constants.ON_VIDEO_SIZE_CHANGED, arguments: videoSizeData)
                    }
                    sendDuration()
                } else if _player?.currentItem?.status == .failed {
                    if let error = _player?.currentItem?.error as NSError? {
                        let errorDetails = handleAVError(error)
                        methodChannel.invokeMethod(Constants.ON_PLAYBACK_ERROR, arguments: errorDetails)
                    }
                    methodChannel.invokeMethod(Constants.ON_PLAYBACK_STATE_CHANGED, arguments: PlaybackState.idle.rawValue)
                }
            }
        } else if keyPath == "rate" {
            if let player = _player {
                let isPlaying = player.rate != 0
                methodChannel.invokeMethod(Constants.IS_PLAYING, arguments: isPlaying)
            }
        }
    }
    
    @objc func playerItemDidReachEnd(notification: NSNotification) {
        methodChannel.invokeMethod(Constants.ON_PLAYBACK_STATE_CHANGED, arguments: PlaybackState.ended.rawValue)
    }
    
    private func setupMethodCallHandler() {
        methodChannel.setMethodCallHandler { [weak self] call, result in
            guard let self = self else { return }
            
            switch call.method {
            case Constants.INIT_PLAYER:
                if let args = call.arguments as? [String: Any],
                   let uri = args[Constants.URI] as? String,
                   let type = args[Constants.TYPE] as? String {
                    
                    let autoplay = args[Constants.AUTOPLAY] as? Bool ?? true
                    let enableMediaSession = args[Constants.ENABLE_MEDIA_SESSION] as? Bool ?? false
                    print("PLAYING_URI: \(uri)")
                    
                    self.initPlayer(uri: uri, type: type, autoplay: autoplay, enableMediaSession: enableMediaSession)
                    
                    result(nil)  // Send back response if needed
                } else {
                    result(FlutterError(code: Constants.INVALID_ARGUMENTS_CODE,
                                        message: Constants.MISSING_INVALID_ARGUMENTS_INIT_PLAYER,
                                        details: nil))
                }
            case Constants.SET_MEDIA_ITEM:
                if let args = call.arguments as? [String: Any],
                   let dataSource = args[Constants.DATA_SOURCE] as? [String: Any],
                   let type = dataSource[Constants.TYPE] as? String,
                   let uri = dataSource[Constants.URI] as? String {
                    
                    print("PLAYING_URI: \(uri)")
                    
                    let autoplay = args[Constants.AUTOPLAY] as? Bool ?? false
                    self.setMediaItemIfNeeded(uri: uri, type: type, autoplay: autoplay)
                    
                    result(nil) // Return success response
                } else {
                    result(FlutterError(code: Constants.INVALID_ARGUMENTS_CODE,
                                        message: Constants.MISSING_INVALID_ARGUMENTS_MEDIAITEM_ERROR,
                                        details: nil))
                }
            case Constants.PLAY_PAUSE:
                self.playPause()
                result(nil)
                
            case Constants.PLAY:
                self.playVideo()
                result(nil)
                
            case Constants.PAUSE:
                self.pauseVideo()
                result(nil)
                
            case Constants.GET_CURRENT_POSITION:
                result(player?.currentItem?.duration ?? 0)
                
            case Constants.STOP:
                self.stop()
                result(nil)
                
            case Constants.SEEK_TO:
                if let position = call.arguments as? Int {
                    self.seekTo(position: position)
                    result(nil)
                } else {
                    result(FlutterError(code: Constants.INVALID_ARGUMENTS_CODE,
                                        message: Constants.INVALID_POSITION_FOR_SEEK_TO,
                                        details: nil))
                }
            case Constants.MUTED:
                let muted = call.arguments as? Bool ?? false
                self.toggleMute(muted: muted)
                result(nil)
            case Constants.PLAYBACK_SPEED:
                let playbackSpeed = call.arguments as? Double ?? 1.0
                self.setPlaybackSpeed(playbackSpeed: playbackSpeed)
                result(nil)
            default:
                result(FlutterMethodNotImplemented)
            }
        }
    }
    
    func initPlayer(uri: String?, type: String?, autoplay: Bool, enableMediaSession: Bool = false) {
        if (uri != nil && !uri!.isEmpty) {
            setMediaItemIfNeeded(uri: uri!, type: type, autoplay: autoplay)
        }
        
        if (player != nil) {
            methodChannel.invokeMethod(Constants.IS_INITIALIZED, arguments: true)
            if (enableMediaSession) {
                createMediaSession()
            }
        }
    }
    
    func createMediaSession() {
        let audioSession = AVAudioSession.sharedInstance()
        do {
            // Set the audio session category and mode.
            try audioSession.setCategory(.playback, mode: .moviePlayback)
            try audioSession.setActive(true)
        } catch {
            print(Constants.FAILED_TO_SET_AUDIO_SESSION_CONFIG)
        }
    }
    
    func autoplayMode(autoplay: Bool) {
        if autoplay {
            _player?.play()
            _player?.rate = self.playbackSpeed
        } else {
            if let isPlaying = _player?.timeControlStatus, isPlaying == .playing {
                pauseVideo()
            }
        }
    }
    
    func setMediaItemIfNeeded(uri: String, type: String?, autoplay: Bool = false) {
        let dataSource: DataSource
        
        switch type {
        case Constants.ASSET:
            do {
                dataSource = try DataSource.asset(context: registrar, assetPath: uri)
            } catch {
                print("Error loading asset: \(error.localizedDescription)")
                return
            }
        case Constants.NETWORK:
            guard let url = URL(string: uri), UIApplication.shared.canOpenURL(url) else {
                let errorDict = handleAVError(NSError(domain: NSURLErrorDomain, code: NSURLErrorUnsupportedURL, userInfo: nil))
                methodChannel.invokeMethod(Constants.ON_PLAYBACK_ERROR, arguments: errorDict)
                return
            }
            dataSource = DataSource.network(url: uri)
        case Constants.FILE:
            dataSource = DataSource.file(filePath: uri)
        default:
            print(Constants.UNSUPPORTED_URI_TYPE)
            return
        }
        
        let newMediaAsset = dataSource.getMediaAsset()
        
//        // Remove observer from old item if exists
//        if let currentItem = _player?.currentItem {
//            currentItem.removeObserver(self, forKeyPath: "status")
//        }
//        
//        // Check if the player is already playing the same media item
//        if let currentItem = _player?.currentItem,
//           currentItem.asset.isEqual(newMediaAsset) {
//            currentItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
//            return // Already playing the same media
//        }
        
        let playerItem = AVPlayerItem(asset: newMediaAsset)
        playerItem.addObserver(self, forKeyPath: "status", options: [.new, .old], context: nil)
        _player?.replaceCurrentItem(with: playerItem)
        
        methodChannel.invokeMethod(Constants.ON_PLAYBACK_STATE_CHANGED, arguments: PlaybackState.loading.rawValue)
        
        autoplayMode(autoplay: autoplay)
    }
    
    private func playPause() {
        if let player = _player {
            if player.rate != 0 {
                pauseVideo()
            } else {
                playVideo()
            }
        }
    }
    
    private func playVideo() {
        if let player = _player, player.currentItem?.status == .readyToPlay {
            if player.currentTime() >= player.currentItem?.duration ?? .zero {
                player.seek(to: .zero)
            }
            player.play()
            player.rate = self.playbackSpeed
        }
    }
    
    private func pauseVideo() {
        _player?.pause()
    }
    
    private func stop() {
        pauseVideo()
        _player?.seek(to: .zero)
    }
    
    private func seekTo(position: Int) {
        let time = CMTime(seconds: Double(position) / 1000.0, preferredTimescale: CMTimeScale(NSEC_PER_SEC))
        _player?.seek(to: time)
    }
    
    private func getCurrentPosition() -> Float64 {
        let currentPosition = CMTimeGetSeconds(player?.currentTime() ?? CMTime.zero)
        return currentPosition
    }
    
    private func getDuration() -> Float64 {
        guard let item = _player?.currentItem,
              item.status == .readyToPlay,
              CMTIME_IS_NUMERIC(item.duration) else { return 0 }
        
        let duration = CMTimeGetSeconds(item.duration)
        return duration.isFinite ? duration : 0
    }

    
    private func getBufferedPosition() -> Float64 {
        guard let timeRange = player?.currentItem?.loadedTimeRanges.first?.timeRangeValue else { return 0 }
        let bufferedPosition = CMTimeGetSeconds(timeRange.start) + CMTimeGetSeconds(timeRange.duration)
        return bufferedPosition
    }
    
    private func sendCurrentPosition() {
        guard let player = _player, let currentItem = player.currentItem else { return }
        
        let currentTime = getCurrentPosition()
        let bufferedTime = getBufferedPosition()
        
        // Check for valid values before converting to Int
        if currentTime.isFinite {
            let position = Int(currentTime * 1000)
            methodChannel.invokeMethod(Constants.CURRENT_POSITION, arguments: position)
        }
        
        if bufferedTime.isFinite {
            let buffered = Int(bufferedTime * 1000)
            methodChannel.invokeMethod(Constants.BUFFERED_POSITION, arguments: buffered)
        }
    }
    
    private func sendDuration() {
        let durationSeconds = getDuration()
        if durationSeconds.isFinite {
            methodChannel.invokeMethod(Constants.DURATION, arguments: Int(durationSeconds * 1000))
        }
    }
    
    func releasePlayer() {
        if let timeObserverToken = timeObserverToken {
            _player?.removeTimeObserver(timeObserverToken)
        }
        if let currentItem = _player?.currentItem {
            currentItem.removeObserver(self, forKeyPath: "status")
        }
        _player?.removeObserver(self, forKeyPath: "status")
        _player?.removeObserver(self, forKeyPath: "rate")
        NotificationCenter.default.removeObserver(self)
        _player = nil
    }
    
    func toggleMute(muted: Bool) {
        if muted {
            currentVolume = getPlayerVolume()
            setPlayerVolume(0)
        } else {
            setPlayerVolume(currentVolume)
        }
    }

    func setPlaybackSpeed(playbackSpeed: Double) {
        if playbackSpeed > 0 {
            self.playbackSpeed = Float(playbackSpeed)
            player?.rate = self.playbackSpeed
        }
    }
    
    func getPlayerVolume() -> Float {
        return player?.volume ?? 0
    }
    
    func setPlayerVolume(_ volume: Float) {
        player?.isMuted = volume == 0
        player?.volume = volume
    }
    
    func getVideoSize() -> CGSize? {
        guard let track = player?.currentItem?.asset.tracks(withMediaType: .video).first else {
            return nil
        }
        let size = track.naturalSize.applying(track.preferredTransform)
        return CGSize(width: abs(size.width), height: abs(size.height))
    }
}
