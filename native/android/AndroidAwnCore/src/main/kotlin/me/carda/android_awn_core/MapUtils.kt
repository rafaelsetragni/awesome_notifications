package me.carda.android_awn_core

/**
 * Instance-based map helpers (singleton via getInstance, instance methods — no
 * static utilities): typed extraction from a `Map<String, Any?>`. Flutter
 * encodes Dart ints/bools as Int/Long/Double depending on the path, so read
 * tolerantly. Mirrors the original AndroidAwnCore type utils intent.
 */
class MapUtils private constructor() {
    companion object {
        private var instance: MapUtils? = null
        fun getInstance(): MapUtils = instance ?: MapUtils().also { instance = it }
    }

    fun getInt(value: Any?): Int? = when (value) {
        is Int -> value
        is Number -> value.toInt()
        is String -> value.toIntOrNull()
        else -> null
    }

    fun getString(value: Any?): String? = value as? String

    fun getBool(value: Any?): Boolean? = when (value) {
        is Boolean -> value
        is Number -> value.toInt() != 0
        else -> null
    }
}
