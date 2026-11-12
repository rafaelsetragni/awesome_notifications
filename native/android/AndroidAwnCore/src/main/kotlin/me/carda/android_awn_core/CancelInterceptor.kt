package me.carda.android_awn_core

import android.content.Context

/**
 * Generic hook letting a decorator react to cancellation. On Android some
 * decorators hold state the core's `NotificationManager` doesn't know about — a
 * scheduling decorator, for instance, registers AlarmManager PendingIntents that
 * a plain `cancel` would not drop. Such a decorator registers a
 * [CancelInterceptor] via [CancelInterceptorRegistry]; the core invokes it
 * alongside its own dismissal. The core itself stays feature-agnostic.
 *
 * All methods default to no-ops so an interceptor overrides only what it needs.
 */
interface CancelInterceptor {
    fun onCancel(context: Context, id: Int) {}
    fun onCancelAll(context: Context) {}
    fun onCancelByChannelKey(context: Context, channelKey: String) {}
    fun onCancelByGroupKey(context: Context, groupKey: String) {}
}

/** Registry of cancel interceptors; decorators register here (statically). */
object CancelInterceptorRegistry {
    private val interceptors = mutableListOf<CancelInterceptor>()

    fun register(interceptor: CancelInterceptor) {
        if (!interceptors.contains(interceptor)) interceptors.add(interceptor)
    }

    fun unregister(interceptor: CancelInterceptor) {
        interceptors.remove(interceptor)
    }

    fun onCancel(context: Context, id: Int) =
        interceptors.forEach { it.onCancel(context, id) }

    fun onCancelAll(context: Context) =
        interceptors.forEach { it.onCancelAll(context) }

    fun onCancelByChannelKey(context: Context, channelKey: String) =
        interceptors.forEach { it.onCancelByChannelKey(context, channelKey) }

    fun onCancelByGroupKey(context: Context, groupKey: String) =
        interceptors.forEach { it.onCancelByGroupKey(context, groupKey) }
}
