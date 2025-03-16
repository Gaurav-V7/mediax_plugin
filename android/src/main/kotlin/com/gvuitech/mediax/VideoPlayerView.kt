package com.gvuitech.mediax

import android.content.Context
import android.graphics.Color
import android.graphics.Rect
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams
import android.widget.FrameLayout
import androidx.annotation.OptIn
import androidx.media3.common.util.UnstableApi
import androidx.media3.ui.AspectRatioFrameLayout
import androidx.media3.ui.PlayerView
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.platform.PlatformView
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler

@UnstableApi
class VideoPlayerView(
    context: Context,
    id: Int,
    creationParams: Map<String?, Any?>?,
    flutterEngine: FlutterEngine,
) : PlatformView, MethodCallHandler {

    private val methodChannel: MethodChannel

    private var rootView: FrameLayout
    private var playerView: PlayerView

    private var sourceRectHint: Rect? = null

    private var controllerId: String? = null

    override fun getView(): View {
        return rootView
    }

    override fun dispose() {
        playerView.player = null
    }

    init {
        controllerId = creationParams?.get(Constants.CONTROLLER_ID) as? String
        methodChannel = MethodChannel(flutterEngine.dartExecutor.binaryMessenger, "${Constants.MEDIAX_VIEW}_$controllerId")
        methodChannel.setMethodCallHandler(this)

        val layoutInflater = LayoutInflater.from(context)
        rootView = layoutInflater.inflate(R.layout.player_view, null) as FrameLayout

        playerView = rootView.findViewById(R.id.player_view)

        playerView.addOnLayoutChangeListener { view, left, top, right, bottom, oldLeft, oldTop, oldRight, oldBottom ->
            if (left != oldLeft || top != oldTop || right != oldRight || bottom != oldBottom) {
                sourceRectHint = Rect()
                playerView.getGlobalVisibleRect(sourceRectHint)
            }
        }

//        playerView.setBackgroundColor(Color.BLACK)
        playerView.useController = false

        val playerController = controllerId?.let { ControllerManager.getController(it) }

        if (playerController != null) {
            playerView.player = playerController.getPlayer(context)
        } else {
            throw IllegalStateException("PlayerController with id $controllerId not found")
        }
    }

    override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
        when (call.method) {
            Constants.SET_RESIZE_MODE -> {
                setResizeMode((call.arguments as Int))
            }
        }
    }

    @UnstableApi
    private fun setResizeMode(resizeMode: Int) {
        if (resizeMode == ResizeMode.FIT.ordinal) {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FIT
        } else if (resizeMode == ResizeMode.STRETCH.ordinal) {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_FILL
        } else if (resizeMode == ResizeMode.CROP.ordinal) {
            playerView.resizeMode = AspectRatioFrameLayout.RESIZE_MODE_ZOOM
        }
    }
}