package me.carda.android_awn_core

import org.json.JSONArray
import org.json.JSONObject

/**
 * Minimal Map <-> JSON conversion used to carry a notification's content map
 * through PendingIntent extras (tap / dismiss) without a serialization library.
 */
object MapJson {

    fun toJson(map: Map<String, Any?>): String = JSONObject(wrapMap(map)).toString()

    fun fromJson(json: String): Map<String, Any?> = unwrapObject(JSONObject(json))

    private fun wrapMap(map: Map<String, Any?>): Map<String, Any?> =
        map.mapValues { (_, value) -> wrap(value) }

    private fun wrap(value: Any?): Any = when (value) {
        null -> JSONObject.NULL
        is Map<*, *> ->
            JSONObject(value.entries.associate { (k, v) -> k.toString() to wrap(v) })
        is List<*> -> JSONArray(value.map { wrap(it) })
        else -> value
    }

    private fun unwrapObject(obj: JSONObject): Map<String, Any?> {
        val result = mutableMapOf<String, Any?>()
        for (key in obj.keys()) {
            result[key] = unwrap(obj.get(key))
        }
        return result
    }

    private fun unwrap(value: Any?): Any? = when (value) {
        JSONObject.NULL -> null
        is JSONObject -> unwrapObject(value)
        is JSONArray -> (0 until value.length()).map { unwrap(value.get(it)) }
        else -> value
    }
}
