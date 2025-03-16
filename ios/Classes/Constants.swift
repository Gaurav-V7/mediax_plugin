//
//  Constants.swift
//  Pods
//
//  Created by AI Alpha Tech on 18/02/25.
//

struct Constants {
    
    static let MEDIAX = "mediax"
    static let MEDIAX_VIEW = "mediax:view"
    static let VIDEO_VIEW = "video_view"
    static let CONTROLLER_ID = "controllerId"
    static let IS_INITIALIZED = "isInitialized"
    
    static let URI = "uri"
    static let TYPE = "type"
    static let AUTOPLAY = "autoplay"
    static let MUTED = "muted"
    static let DATA_SOURCE = "dataSource"
    static let WIDTH = "width"
    static let HEIGHT = "height"
    
    static let INIT_PLAYER = "initPlayer"
    static let SET_MEDIA_ITEM = "setMediaItem"
    static let PLAY_PAUSE = "playPause"
    static let PLAY = "play"
    static let PAUSE = "pause"
    static let GET_CURRENT_POSITION = "getCurrentPosition"
    static let GET_DURATION = "getDuration"
    static let SEEK_TO = "seekTo"
    static let ENTER_PIP = "enterPip"
    static let EXIT_PIP = "exitPip"
    static let STOP = "stop"
    static let RELEASE_PLAYER = "releasePlayer"
    static let DURATION = "duration"
    static let CURRENT_POSITION = "currentPosition"
    static let BUFFERED_POSITION = "bufferedPosition"
    static let ASSET = "asset"
    static let NETWORK = "network"
    static let FILE = "file"
    static let IS_PLAYING = "isPlaying"
    static let ERROR_CODE = "errorCode"
    static let STACK_TRACE = "stackTrace"
    static let PLAYBACK_SPEED = "playbackSpeed"
    static let INVALID_ARGUMENTS_CODE = "INVALID_ARGUMENTS"
    static let CONTROLLER_MANAGER_ERROR_DOMAIN = "ControllerManager"

    static let SET_RESIZE_MODE = "setResizeMode"
    
    static let ON_PLAYBACK_STATE_CHANGED = "onPlaybackStateChanged"
    static let ON_PLAYBACK_ERROR = "onPlaybackError"
    static let ON_VIDEO_SIZE_CHANGED = "onVideoSizeChanged"
    
    static let ENABLE_MEDIA_SESSION = "enableMediaSession"
    
    // Errors
    static let DATASOURCE_NULL_ERROR = "Data source must not be null"
    static let DATASOURCE_TYPE_NULL_ERROR = "Type must be provided in dataSource"
    static let PARAMS_MUST_NOT_BE_NULL = "Params must not be null"
    static let URI_NULL_ERROR = "URI must be provided in dataSource"
    static let UNSUPPORTED_URI_TYPE = "Unsupported URI type"
    static let FAILED_TO_SET_AUDIO_SESSION_CONFIG = "Failed to set the audio session configuration"
    static let MISSING_INVALID_ARGUMENTS_MEDIAITEM_ERROR = "Missing or invalid arguments for setMediaItem"
    static let MISSING_INVALID_ARGUMENTS_INIT_PLAYER = "Missing or invalid arguments for initPlayer"
    static let INVALID_POSITION_FOR_SEEK_TO = "Invalid position for seekTo"
}
