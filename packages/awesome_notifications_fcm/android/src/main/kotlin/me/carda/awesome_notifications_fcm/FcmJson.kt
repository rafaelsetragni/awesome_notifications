package me.carda.awesome_notifications_fcm

import org.json.JSONArray
import org.json.JSONObject

/**
 * Tolerant JSON decoding for FCM payload sections. Unlike the core `JsonUtils`
 * (map-only, throws on malformed input), these return null on anything that is
 * not the expected shape, so a bad section is skipped instead of dropping the
 * whole push.
 */
object FcmJson {

    fun parseObjectOrNull(raw: String?): Map<String, Any?>? {
        if (raw.isNullOrBlank()) return null
        return try {
            unwrapObject(JSONObject(raw))
        } catch (_: Exception) {
            null
        }
    }

    fun parseListOrNull(raw: String?): List<Any?>? {
        if (raw.isNullOrBlank()) return null
        return try {
            unwrapArray(JSONArray(raw))
        } catch (_: Exception) {
            null
        }
    }

    private fun unwrapObject(obj: JSONObject): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        for (key in obj.keys()) map[key] = unwrap(obj.get(key))
        return map
    }

    private fun unwrapArray(arr: JSONArray): List<Any?> =
        (0 until arr.length()).map { unwrap(arr.get(it)) }

    private fun unwrap(value: Any?): Any? = when (value) {
        is JSONObject -> unwrapObject(value)
        is JSONArray -> unwrapArray(value)
        JSONObject.NULL -> null
        else -> value
    }
}
