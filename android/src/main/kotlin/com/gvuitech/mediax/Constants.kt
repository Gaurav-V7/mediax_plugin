package com.gvuitech.mediax

object Constants {

    const val MEDIAX = "mediax"
    const val MEDIAX_VIEW = "mediax:view"
    const val VIDEO_VIEW = "video_view"
    const val CONTROLLER_ID = "controllerId"
    const val IS_INITIALIZED = "isInitialized"

    const val URI = "uri"
    const val TYPE = "type"
    const val AUTOPLAY = "autoplay"
    const val MUTED = "muted"
    const val DATA_SOURCE = "dataSource"
    const val WIDTH = "width"
    const val HEIGHT = "height"

    const val INIT_PLAYER = "initPlayer"
    const val SET_MEDIA_ITEM = "setMediaItem"
    const val PLAY_PAUSE = "playPause"
    const val PLAY = "play"
    const val PAUSE = "pause"
    const val GET_CURRENT_POSITION = "getCurrentPosition"
    const val GET_DURATION = "getDuration"
    const val SEEK_TO = "seekTo"
    const val ENTER_PIP = "enterPip"
    const val EXIT_PIP = "exitPip"
    const val STOP = "stop"
    const val RELEASE_PLAYER = "releasePlayer"
    const val DURATION = "duration"
    const val CURRENT_POSITION = "currentPosition"
    const val BUFFERED_POSITION = "bufferedPosition"
    const val ASSET = "asset"
    const val NETWORK = "network"
    const val FILE = "file"
    const val IS_PLAYING = "isPlaying"
    const val ERROR_CODE = "errorCode"
    const val STACK_TRACE = "stackTrace"
    const val PLAYBACK_SPEED = "playbackSpeed"

    const val SET_RESIZE_MODE = "setResizeMode"

    const val ON_PLAYBACK_STATE_CHANGED = "onPlaybackStateChanged"
    const val ON_PLAYBACK_ERROR = "onPlaybackError"
    const val ON_VIDEO_SIZE_CHANGED = "onVideoSizeChanged"

    const val ENABLE_MEDIA_SESSION = "enableMediaSession"

    // Errors
    const val DATASOURCE_NULL_ERROR = "Data source must not be null"
    const val DATASOURCE_TYPE_NULL_ERROR = "Type must be provided in dataSource"
    const val URI_NULL_ERROR = "URI must be provided in dataSource"
    const val UNSUPPORTED_URI_TYPE = "Unsupported URI type"
}