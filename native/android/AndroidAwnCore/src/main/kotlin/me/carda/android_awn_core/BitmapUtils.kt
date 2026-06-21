package me.carda.android_awn_core

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import io.flutter.FlutterInjector
import java.io.BufferedInputStream
import java.io.File
import java.net.URL

/**
 * Loads a [Bitmap] from a media reference, supporting the four awesome
 * notifications media sources by scheme prefix:
 * `https://` (network), `asset://` (Flutter asset), `file://` (local file) and
 * `resource://type/name` (Android resource). Mirrors the original AndroidAwnCore
 * BitmapUtils.
 *
 * NOTE: network/file/asset decoding does I/O; call off the main thread.
 */
class BitmapUtils private constructor() {
    companion object {
        private var instance: BitmapUtils? = null
        fun getInstance(): BitmapUtils = instance ?: BitmapUtils().also { instance = it }
    }

    private enum class MediaSource { NETWORK, FILE, ASSET, RESOURCE, UNKNOWN }

    fun getBitmapFromSource(context: Context, path: String?): Bitmap? {
        if (path.isNullOrEmpty()) return null
        return when (mediaSource(path)) {
            MediaSource.NETWORK -> bitmapFromUrl(clean(path))
            MediaSource.FILE -> bitmapFromFile(clean(path))
            MediaSource.ASSET -> bitmapFromAsset(context, clean(path))
            MediaSource.RESOURCE -> bitmapFromResource(context, clean(path))
            MediaSource.UNKNOWN -> null
        }
    }

    private fun mediaSource(path: String): MediaSource {
        val lower = path.lowercase()
        return when {
            lower.startsWith("http://") || lower.startsWith("https://") -> MediaSource.NETWORK
            lower.startsWith("file://") -> MediaSource.FILE
            lower.startsWith("resource://") -> MediaSource.RESOURCE
            lower.startsWith("asset://") -> MediaSource.ASSET
            else -> MediaSource.UNKNOWN
        }
    }

    /** Strips the scheme prefix (network URLs are kept whole). */
    private fun clean(path: String): String {
        val lower = path.lowercase()
        return when {
            lower.startsWith("http") -> path
            lower.startsWith("asset://") -> path.substring("asset://".length)
            lower.startsWith("file://") -> path.substring("file://".length)
            lower.startsWith("resource://") -> path.substring("resource://".length)
            else -> path
        }
    }

    private fun bitmapFromUrl(url: String): Bitmap? = try {
        val connection = URL(url).openConnection().apply {
            connectTimeout = 5000
            readTimeout = 5000
            connect()
        }
        BufferedInputStream(connection.getInputStream(), 8192).use {
            BitmapFactory.decodeStream(it)
        }
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }

    private fun bitmapFromFile(path: String): Bitmap? = try {
        BitmapFactory.decodeFile(File(path).absolutePath)
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }

    private fun bitmapFromAsset(context: Context, path: String): Bitmap? = try {
        val key = FlutterInjector.instance().flutterLoader().getLookupKeyForAsset(path)
        context.assets.open(key).use { BitmapFactory.decodeStream(it) }
    } catch (e: Exception) {
        e.printStackTrace()
        null
    }

    /** `resource://type/name`, e.g. `resource://drawable/app_icon`. */
    private fun bitmapFromResource(context: Context, reference: String): Bitmap? {
        val parts = reference.split("/")
        if (parts.size < 2) return null
        val resourceId = context.resources.getIdentifier(
            parts[1], parts[0], context.packageName
        )
        if (resourceId == 0) return null
        return try {
            BitmapFactory.decodeResource(context.resources, resourceId)
        } catch (e: Exception) {
            e.printStackTrace()
            null
        }
    }
}
