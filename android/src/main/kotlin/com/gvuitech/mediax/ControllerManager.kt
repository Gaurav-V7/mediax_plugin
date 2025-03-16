package com.gvuitech.mediax

import android.app.Activity
import android.content.Context
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

object ControllerManager {

    private val controllers = mutableMapOf<String, PlayerController>()

    fun getController(controllerId: String) : PlayerController? {
        return controllers[controllerId]
    }

    fun createController(
        controllerId: String,
        flutterEngine: FlutterEngine,
        context: Context,
        activity: Activity?,
        params: Map<String?, Any?>,
        methodChannel: MethodChannel
    ) {
        val playerController = PlayerController(context, flutterEngine, controllerId, methodChannel)

        val dataSource = params[Constants.DATA_SOURCE] as? Map<*, *>

        var type: String? = null
        var uri: String? = null
        var autoplay = false

        if (dataSource != null) {
            type = dataSource[Constants.TYPE] as? String
                ?: throw IllegalArgumentException("Type must be provided in dataSource")

            uri = dataSource[Constants.URI] as? String
                ?: throw IllegalArgumentException("URI must be provided in dataSource")
            autoplay = params[Constants.AUTOPLAY] as? Boolean ?: true
        }
        val enableMediaSession = params[Constants.ENABLE_MEDIA_SESSION] as? Boolean ?: false
        playerController.initPlayer(uri, type, autoplay, enableMediaSession)
        controllers[controllerId] = playerController
    }

    fun releaseController(controllerId: String) {
        controllers[controllerId]?.releasePlayer()
        controllers.remove(controllerId)
    }
}