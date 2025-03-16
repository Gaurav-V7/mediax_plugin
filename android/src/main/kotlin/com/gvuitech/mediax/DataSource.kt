package com.gvuitech.mediax

import android.content.Context
import android.content.res.AssetFileDescriptor
import androidx.media3.common.MediaItem
import io.flutter.embedding.engine.loader.FlutterLoader
import java.io.File
import java.io.FileNotFoundException

class DataSource private constructor(private val uri: String) {

    companion object {
        fun asset(context: Context, assetPath: String): DataSource {
            val assetManager = context.assets
            val flutterLoader = FlutterLoader()
            flutterLoader.startInitialization(context)
            val finalAssetPath = flutterLoader.getLookupKeyForAsset(assetPath)
            try {
                val assetFileDescriptor: AssetFileDescriptor = assetManager.openFd(finalAssetPath)
                val filePath = copyAssetToTempFile(context, assetFileDescriptor)
                return DataSource(filePath)
            } catch (e: Exception) {
                throw IllegalArgumentException("Asset error:\n$assetPath\n${e.localizedMessage}")
            }
        }

        fun network(url: String): DataSource {
            return DataSource(url)
        }

        fun file(filePath: String): DataSource {
            return DataSource(filePath)
        }

        private fun copyAssetToTempFile(context: Context, assetFileDescriptor: AssetFileDescriptor): String {
            val tempFile = File(context.cacheDir, "temp_asset_file.mp4")
            tempFile.outputStream().use { outputStream ->
                assetFileDescriptor.createInputStream().use { inputStream ->
                    inputStream.copyTo(outputStream)
                }
            }
            return tempFile.absolutePath
        }
    }

    fun getMediaItem(): MediaItem {
        return MediaItem.Builder()
            .setUri(uri)
            .setMediaId(uri) // Use URI as unique media ID
            .build()
    }
}
