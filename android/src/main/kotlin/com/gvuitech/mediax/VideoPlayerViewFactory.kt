package com.gvuitech.mediax

import android.app.Activity
import android.content.Context
import android.content.res.Configuration
import android.util.Log
import android.view.View
import androidx.annotation.NonNull
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.platform.PlatformViewFactory
import io.flutter.plugin.platform.PlatformView
import io.flutter.embedding.engine.dart.DartExecutor
import io.flutter.embedding.engine.loader.FlutterLoader
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.StandardMessageCodec

class VideoPlayerViewFactory(
    private val flutterEngine: FlutterEngine
) : PlatformViewFactory(StandardMessageCodec.INSTANCE) {


    override fun create(context: Context?, viewId: Int, args: Any?): PlatformView {
        @Suppress("UNCHECKED_CAST")
        val arguments = args as? Map<String?, Any?> ?: emptyMap()
        val controllerId = arguments[Constants.CONTROLLER_ID] as? String ?: throw IllegalArgumentException("Controller ID must be provided")

        ControllerManager.getController(controllerId)

        return VideoPlayerView(context!!, viewId, arguments, flutterEngine)
    }

}