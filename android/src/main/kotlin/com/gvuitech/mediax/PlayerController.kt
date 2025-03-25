package com.gvuitech.mediax

import android.annotation.SuppressLint
import android.app.PictureInPictureParams
import android.content.Context
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.provider.MediaStore.Video
import android.util.Log
import android.util.Rational
import androidx.media3.common.ForwardingPlayer
import androidx.media3.common.PlaybackException
import androidx.media3.common.Player
import androidx.media3.common.VideoSize
import androidx.media3.common.util.UnstableApi
import androidx.media3.exoplayer.ExoPlayer
import androidx.media3.session.MediaSession
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class PlayerController(
    private val activity: Context,
    flutterEngine: FlutterEngine,
    private val controllerId: String,
    private val methodChannel: MethodChannel
) {

    private var player: Player? = null
    private var mediaSession: MediaSession? = null

    private val updateInterval = 100L
    private val handler = Handler(Looper.getMainLooper())
    private var isPositionUpdaterRunning = false

    private var currentVolume = 0f

    init {
        getPlayer(activity)
        populatePlayerState()
        setupPlayerListeners()
        setupNativeCalls()
    }

    fun getPlayer(context: Context): Player {
        if (player == null) {
            player = ExoPlayer.Builder(context).build()
        }
        return player!!
    }

    private fun populatePlayerState() {
        this.currentVolume = getPlayerVolume()
    }

    private fun setMediaItemIfNeeded(uri: String, type: String?, autoplay: Boolean = false) {
        val dataSource = when (type) {
            Constants.ASSET -> DataSource.asset(activity, uri)
            Constants.NETWORK -> DataSource.network(uri)
            Constants.FILE -> DataSource.file(uri)
            else -> throw IllegalArgumentException(Constants.UNSUPPORTED_URI_TYPE)
        }

        player?.setMediaItem(dataSource.getMediaItem())

        player?.prepare()

        autoplayMode(autoplay)
    }

    fun initPlayer(uri: String?, type: String?, autoplay: Boolean = true, enableMediaSession: Boolean = false) {
        if (!uri.isNullOrEmpty()) {
            setMediaItemIfNeeded(uri, type, autoplay)
        }

        if (player != null) {
            methodChannel.invokeMethod(Constants.IS_INITIALIZED, true)
            if (enableMediaSession) {
                createMediaSession()
            }
        }
    }

    private fun createMediaSession() {
        val forwardingPlayer = @UnstableApi object : ForwardingPlayer(player!!) {
            override fun getAvailableCommands(): Player.Commands {
                return super.getAvailableCommands()
                    .buildUpon()
                    .remove(COMMAND_SEEK_TO_PREVIOUS)
                    .remove(COMMAND_SEEK_TO_NEXT)
                    .build()
            }
        }
        mediaSession = MediaSession.Builder(activity.applicationContext, forwardingPlayer).build()
    }

    private fun autoplayMode(autoplay: Boolean) {
        if (autoplay) {
            player?.play()
        } else {
            if (player?.isPlaying == true) pauseVideo()
        }
    }

    private fun playPause() {
        if (player?.isPlaying == true) {
            pauseVideo()
        } else {
            playVideo()
        }
    }

    private fun playVideo() {
        if (player?.playbackState == Player.STATE_ENDED) {
            player!!.seekTo(0)
        }
        player?.play()
    }

    private fun pauseVideo() {
        player?.pause()
    }

    private fun stop() {
        player?.stop()
    }

    fun releasePlayer() {
        handler.removeCallbacksAndMessages(null)
        methodChannel.setMethodCallHandler(null)
        player?.release()
        mediaSession?.release()
        mediaSession = null
        player = null
    }

    private fun seekTo(arguments: Any?) {
        val position = arguments ?: 0L
        player?.seekTo(position.toString().toLong())
        sendCurrentPosition()
    }

    private fun getCurrentPosition(): Long {
        return player?.currentPosition ?: 0L
    }

    private fun getBufferedPosition(): Long {
        return player?.bufferedPosition ?: 0L
    }

    private fun getDuration(): Long {
        return player?.duration ?: 0L
    }

    fun startPositionUpdates() {
        if (isPositionUpdaterRunning) return

        isPositionUpdaterRunning = true
        handler.postDelayed(object : Runnable {
            override fun run() {
                sendCurrentPosition()
                handler.postDelayed(this, updateInterval)
            }
        }, updateInterval)
    }

    fun stopPositionUpdates() {
        handler.removeCallbacksAndMessages(null)
        isPositionUpdaterRunning = false
    }

    @SuppressLint("UnsafeOptInUsageError")
    fun enterPipMode() {
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
            val params = PictureInPictureParams.Builder()
                .setAspectRatio(
                    Rational(
                        player?.videoSize?.width.takeIf { (it ?: 0) > 0 } ?: 1280,
                        player?.videoSize?.height.takeIf { (it ?: 0) > 0 } ?: 720
                    )
                ).build()
//            activity.enterPictureInPictureMode(params)
        }
    }

    private fun exitPipMode() {

    }

    private fun setupPlayerListeners() {
        player?.addListener(object : Player.Listener {
            override fun onVideoSizeChanged(videoSize: VideoSize) {
                super.onVideoSizeChanged(videoSize)
                if (videoSize.width == 0 || videoSize.height == 0) return
                methodChannel.invokeMethod(Constants.ON_VIDEO_SIZE_CHANGED, mapOf(
                    Constants.WIDTH to (videoSize.width),
                    Constants.HEIGHT to (videoSize.height)
                ))
            }

            override fun onIsPlayingChanged(isPlaying: Boolean) {
                methodChannel.invokeMethod(Constants.IS_PLAYING, isPlaying)
                if (isPlaying) {
                    startPositionUpdates()
                } else {
                    stopPositionUpdates()
                }
            }

            override fun onPlayerError(error: PlaybackException) {
                super.onPlayerError(error)

                val errorCode = when (error.errorCode) {
                    PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_FAILED,
                    PlaybackException.ERROR_CODE_IO_BAD_HTTP_STATUS,
                    PlaybackException.ERROR_CODE_IO_NETWORK_CONNECTION_TIMEOUT -> 1003 // networkError
                    PlaybackException.ERROR_CODE_IO_FILE_NOT_FOUND -> 1001 // sourceNotFound
                    PlaybackException.ERROR_CODE_DECODER_INIT_FAILED,
                    PlaybackException.ERROR_CODE_AUDIO_TRACK_INIT_FAILED -> 1002 // codecError
                    PlaybackException.ERROR_CODE_TIMEOUT -> 1004 // timeout
                    PlaybackException.ERROR_CODE_DRM_SYSTEM_ERROR -> 1005 // drmError
                    PlaybackException.ERROR_CODE_UNSPECIFIED -> 1000 // unknown
                    else -> 1006 // internalError
                }

                val errorDetails = mapOf(
                    Constants.ERROR_CODE to errorCode,
                    Constants.STACK_TRACE to error.stackTraceToString()
                )
                methodChannel.invokeMethod(Constants.ON_PLAYBACK_ERROR, errorDetails)
            }

            override fun onIsLoadingChanged(isLoading: Boolean) {
                super.onIsLoadingChanged(isLoading)
                if (player != null) {
                    if (isLoading) {
                        sendPlaybackState(PlaybackState.loading)
                    } else {
                        parsePlaybackState(player!!.playbackState)
                    }
                }
            }

            override fun onPlaybackStateChanged(playbackState: Int) {
                super.onPlaybackStateChanged(playbackState)
                parsePlaybackState(playbackState)
                when (playbackState) {
                    Player.STATE_IDLE -> {
                        seekTo(0)
                        stopPositionUpdates()
                    }
                    Player.STATE_READY -> {
                        sendDuration()
                        if (player?.isPlaying == true) {
                            startPositionUpdates()
                        }
                    }
                    Player.STATE_ENDED -> {
                        stopPositionUpdates()
                    }

                    Player.STATE_BUFFERING -> {
                    }
                }
            }
        })
    }

    private fun setupNativeCalls() {
        methodChannel.setMethodCallHandler { call, result ->
            when (call.method) {
                Constants.INIT_PLAYER -> {
                    val args = call.arguments as Map<*, *>
                    val uri = args[Constants.URI] as String
                    val type = args[Constants.TYPE] as String
                    val autoplay = args[Constants.AUTOPLAY] as Boolean? ?: true
                    val enableMediaSession = args[Constants.ENABLE_MEDIA_SESSION] as Boolean? ?: false
                    initPlayer(uri, type, autoplay, enableMediaSession)
                }
                Constants.SET_MEDIA_ITEM -> {
                    val args = call.arguments as Map<*, *>

                    val dataSource = args[Constants.DATA_SOURCE] as? Map<*, *>
                        ?: throw IllegalArgumentException(Constants.DATASOURCE_NULL_ERROR)

                    val type = dataSource[Constants.TYPE] as? String ?: throw IllegalArgumentException(Constants.DATASOURCE_TYPE_NULL_ERROR)

                    val uri = dataSource[Constants.URI] as? String ?: throw IllegalArgumentException(Constants.URI_NULL_ERROR)

                    val autoplay = args[Constants.AUTOPLAY] as? Boolean ?: false

                    setMediaItemIfNeeded(uri, type, autoplay)
                }
                Constants.PLAY_PAUSE -> playPause()
                Constants.PLAY -> playVideo()
                Constants.PAUSE -> pauseVideo()
                Constants.GET_CURRENT_POSITION -> result.success(getCurrentPosition())
                Constants.GET_DURATION -> result.success(getDuration())
                Constants.SEEK_TO -> seekTo(call.arguments)
                Constants.ENTER_PIP -> enterPipMode()
                Constants.EXIT_PIP -> exitPipMode()
                Constants.STOP -> stop()
                Constants.RELEASE_PLAYER -> releasePlayer()
                Constants.MUTED -> {
                    val muted = call.arguments as? Boolean ?: false
                    toggleMute(muted)
                }
                Constants.PLAYBACK_SPEED -> {
                    val playbackSpeed = call.arguments as? Double ?: 1.0
                    setPlaybackSpeed(playbackSpeed)
                }
                else -> {

                }
            }
        }
    }

    private fun setPlaybackSpeed(playbackSpeed: Double) {
        if (playbackSpeed > 0) {
            player?.setPlaybackSpeed(playbackSpeed.toFloat())
        }
    }

    private fun toggleMute(muted: Boolean) {
        if (muted) {
            this.currentVolume = getPlayerVolume()
            setPlayerVolume(0f)
        } else {
            setPlayerVolume(1f)
        }
    }

    private fun getPlayerVolume(): Float {
        return player?.volume ?: 0f
    }

    private fun setPlayerVolume(volume: Float) {
        player?.volume = volume
    }

    private fun parsePlaybackState(state: Int) {
        var currentState: PlaybackState? = null
        when (state) {
            Player.STATE_IDLE -> currentState = PlaybackState.idle
            Player.STATE_READY -> currentState = PlaybackState.ready
            Player.STATE_BUFFERING -> currentState = PlaybackState.buffering
            Player.STATE_ENDED -> currentState = PlaybackState.ended
        }

        if (currentState != null) {
            sendPlaybackState(currentState)
        }
    }

    private fun sendPlaybackState(playbackState: PlaybackState) {
        methodChannel.invokeMethod(Constants.ON_PLAYBACK_STATE_CHANGED, playbackState.ordinal)
    }

    private fun sendDuration() {
        methodChannel.invokeMethod(Constants.DURATION, getDuration())
    }

    private fun sendCurrentPosition() {
        val currentPosition = getCurrentPosition()
        val bufferedPosition = getBufferedPosition()

        // Send current position along with playback speed to Flutter
        methodChannel.invokeMethod(Constants.CURRENT_POSITION, currentPosition)
        methodChannel.invokeMethod(Constants.BUFFERED_POSITION, bufferedPosition)
    }



}