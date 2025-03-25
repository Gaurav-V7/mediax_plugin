package com.gvuitech.mediax

import android.app.Activity
import android.app.Application.ActivityLifecycleCallbacks
import android.app.PictureInPictureParams
import android.content.Context
import android.content.res.Configuration
import android.os.Build
import android.os.Bundle
import android.util.Log
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

/** MediaxPlugin */
class MediaxPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {

  private lateinit var context: Context
  private lateinit var channel: MethodChannel
  private lateinit var flutterPluginBinding: FlutterPlugin.FlutterPluginBinding
  private var activity: Activity? = null

  override fun onAttachedToEngine(@NonNull flutterPluginBinding: FlutterPlugin.FlutterPluginBinding) {
    this.context = flutterPluginBinding.applicationContext

    this.flutterPluginBinding = flutterPluginBinding
    channel = MethodChannel(flutterPluginBinding.binaryMessenger, Constants.MEDIAX)
    channel.setMethodCallHandler(this)

    val platformViewRegistry = flutterPluginBinding.platformViewRegistry

    // Register the platform view factory
    platformViewRegistry.registerViewFactory(
      Constants.VIDEO_VIEW,
      VideoPlayerViewFactory(flutterPluginBinding.flutterEngine)
    )
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      Constants.INIT_PLAYER -> {
        val controllerId = (call.arguments as? Map<*, *>)?.get(Constants.CONTROLLER_ID) as? String
        controllerId?.let {
          val controllerChannel = MethodChannel(
            flutterPluginBinding.binaryMessenger,
            "mediax_$it"
          )
          if (ControllerManager.getController(it) == null) {
            ControllerManager.createController(
              it,
              flutterPluginBinding.flutterEngine,
              context,
              activity,
              call.arguments as Map<String?, Any?>,
              controllerChannel
            )
          }
        }
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }

  override fun onDetachedFromEngine(@NonNull binding: FlutterPlugin.FlutterPluginBinding) {
    if (::channel.isInitialized) {
      channel.setMethodCallHandler(null)
    }

    ControllerManager.releaseAllControllers()

    if (::flutterPluginBinding.isInitialized) {
      flutterPluginBinding = binding
    }
  }

  override fun onAttachedToActivity(binding: ActivityPluginBinding) {
      activity = binding.activity
  }

  override fun onDetachedFromActivityForConfigChanges() {
    activity = null
  }

  override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
    activity = binding.activity
  }

  override fun onDetachedFromActivity() {
    activity = null
  }
}
