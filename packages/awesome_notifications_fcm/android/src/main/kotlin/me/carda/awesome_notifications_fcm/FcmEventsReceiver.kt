package me.carda.awesome_notifications_fcm

/**
 * Process-global bridge between the headless FirebaseMessagingService and the
 * (optionally attached) Flutter plugin. The service has no plugin reference, so
 * it publishes token / silent events here; the plugin subscribes while attached
 * and forwards them to Dart.
 *
 * When no listener is attached (app terminated), token events are simply
 * persisted (delivered on next launch) and silent data is handed to the headless
 * background isolate instead — see [FcmBackgroundExecutor].
 */
object FcmEventsReceiver {

    interface TokenListener {
        fun onNewFcmToken(token: String?)
        fun onNewNativeToken(token: String?)
    }

    interface SilentListener {
        /** Return true if the (foreground) listener consumed the silent data. */
        fun onSilentData(silentData: SilentDataModel): Boolean
    }

    private val tokenListeners = mutableListOf<TokenListener>()
    private val silentListeners = mutableListOf<SilentListener>()

    fun subscribeToken(listener: TokenListener) {
        if (!tokenListeners.contains(listener)) tokenListeners.add(listener)
    }

    fun unsubscribeToken(listener: TokenListener) { tokenListeners.remove(listener) }

    fun subscribeSilent(listener: SilentListener) {
        if (!silentListeners.contains(listener)) silentListeners.add(listener)
    }

    fun unsubscribeSilent(listener: SilentListener) { silentListeners.remove(listener) }

    fun hasSilentListener(): Boolean = silentListeners.isNotEmpty()

    fun notifyFcmToken(token: String?) {
        tokenListeners.toList().forEach { it.onNewFcmToken(token) }
    }

    fun notifyNativeToken(token: String?) {
        tokenListeners.toList().forEach { it.onNewNativeToken(token) }
    }

    /** Returns true if any attached listener consumed the silent data. */
    fun notifySilentData(silentData: SilentDataModel): Boolean =
        silentListeners.toList().any { it.onSilentData(silentData) }
}
