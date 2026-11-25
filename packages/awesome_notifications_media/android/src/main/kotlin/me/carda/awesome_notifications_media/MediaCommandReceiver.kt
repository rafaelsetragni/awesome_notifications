package me.carda.awesome_notifications_media

import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import me.carda.android_awn_core.NotificationBuilder

/**
 * Receives the media controls drawn as notification actions (Android < 13,
 * and after the session died with the app's process). The intent carries the
 * notification's model, so a killed app still gets the command.
 */
class MediaCommandReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val control = MediaControl.from(intent.getStringExtra(MediaKeys.EXTRA_CONTROL)) ?: return
        val sent = NotificationBuilder.getNewBuilder().notificationModel(intent) ?: return
        val sentMedia = MediaModel.parse(sent[MediaKeys.MEDIA]).first ?: return
        // The live session knows the latest model (a later update of the notification).
        val live = MediaSessions.entry(sentMedia.sessionId)
        val model = live?.model ?: sent
        val media = live?.media ?: sentMedia
        // The app may be killed: keep the receiver alive while a background isolate runs.
        val pending: PendingResult? = goAsync()
        MediaSessions.deliver(context, model, media, control) { pending?.finish() }
    }
}
