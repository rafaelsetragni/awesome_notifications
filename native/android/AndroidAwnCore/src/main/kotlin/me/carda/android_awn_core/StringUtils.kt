package me.carda.android_awn_core

/**
 * Instance-based string helpers (singleton via getInstance, instance methods —
 * no static utilities), mirroring the original AndroidAwnCore `StringUtils`.
 */
class StringUtils private constructor() {
    companion object {
        private var instance: StringUtils? = null
        fun getInstance(): StringUtils = instance ?: StringUtils().also { instance = it }
    }

    fun isNullOrEmpty(value: String?): Boolean = value == null || value.trim().isEmpty()
}
