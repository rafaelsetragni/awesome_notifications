package me.carda.awesome_notifications_calls

import android.app.PendingIntent
import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.Person
import androidx.core.graphics.drawable.IconCompat
import me.carda.android_awn_core.BitmapUtils
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils

/**
 * Styles a live call's notification: NotificationCompat.CallStyle (incoming:
 * decline + answer; outgoing / ongoing / held: hang up) with the caller, or,
 * where CallStyle can't be used (no foreground service for an ongoing call on
 * Android 12+, a call without the system's buttons), the same buttons as
 * plain actions with the call's texts.
 */
internal object CallNotifications {

    fun render(context: Context, call: CallModel, model: Map<String, Any?>, builder: NotificationCompat.Builder) {
        @Suppress("UNCHECKED_CAST")
        val content = (model[Definitions.NOTIFICATION_CONTENT] as? Map<String, Any?>).orEmpty()
        val id = (content[Definitions.NOTIFICATION_ID] as? Number)?.toInt() ?: return
        val plain = model[CallKeys.MODEL_PLAIN] == true
        val muted = model[CallKeys.MODEL_MUTED] == true

        val avatar = call.caller.avatarBitmap(context, BitmapUtils.getInstance())
        val person = Person.Builder()
            .setKey(call.caller.key)
            .setName(call.displayName)
            .setBot(call.caller.isBot)
            .setImportant(call.caller.isImportant)
            .apply {
                call.caller.uri?.let { setUri(it) }
                avatar?.let { setIcon(IconCompat.createWithBitmap(it)) }
            }
            .build()

        // The model's own buttons go after the call's.
        val modelButtons = ArrayList(builder.mActions)
        builder.clearActions()

        val tap = contentIntent(context, id, model, call)
        builder.setContentIntent(tap)
            .setCategory(NotificationCompat.CATEGORY_CALL)
            .setOngoing(true)
            .setAutoCancel(false)
            .setVisibility(NotificationCompat.VISIBILITY_PUBLIC)
            .setContentTitle(call.displayName)
            .addPerson(person)
        if (avatar != null && (content[Definitions.NOTIFICATION_LARGE_ICON] as? String).isNullOrEmpty()) {
            builder.setLargeIcon(avatar)
        }

        var style: NotificationCompat.CallStyle? = null
        when (call.state) {
            CallState.incoming -> {
                builder.setContentText(call.text(if (call.video) CallKeys.TEXT_INCOMING_VIDEO else CallKeys.TEXT_INCOMING))
                    .setPriority(NotificationCompat.PRIORITY_MAX)
                    .setFullScreenIntent(tap, true)
                    .setOnlyAlertOnce(true)
                    .setShowWhen(false)
                val decline = if (CallControl.decline in call.controls)
                    commandIntent(context, model, call, CallAction.decline) else null
                val answer = if (CallControl.accept in call.controls) answerIntent(context, model, call) else null
                if (!plain && decline != null && answer != null) {
                    style = NotificationCompat.CallStyle.forIncomingCall(person, decline, answer)
                } else {
                    decline?.let { builder.addAction(R.drawable.awn_call_ic_call_end, call.text(CallKeys.TEXT_DECLINE), it) }
                    answer?.let { builder.addAction(R.drawable.awn_call_ic_call, call.text(CallKeys.TEXT_ACCEPT), it) }
                }
            }
            CallState.outgoing, CallState.ongoing, CallState.held -> {
                val text = when (call.state) {
                    CallState.outgoing -> CallKeys.TEXT_OUTGOING
                    CallState.held -> CallKeys.TEXT_HELD
                    else -> CallKeys.TEXT_ONGOING
                }
                // Never a sound: the package's silent channel. An update on a
                // channel with a sound (the ringing call's) leaves its looping
                // ringtone and vibration playing; one without a sound stops them.
                builder.setContentText(call.text(text))
                    .setPriority(NotificationCompat.PRIORITY_HIGH)
                    .setFullScreenIntent(null, false)
                    .setChannelId(SilentCallChannel.id(context, call.text(CallKeys.TEXT_ONGOING)))
                    .setSound(null)
                    .setVibrate(null)
                    .setDefaults(0)
                    .setSilent(true)
                if (call.state == CallState.outgoing) {
                    builder.setShowWhen(false).setUsesChronometer(false)
                } else {
                    builder.setWhen(call.startedAt ?: System.currentTimeMillis())
                        .setShowWhen(true)
                        .setUsesChronometer(true)
                }
                val hangUp = if (CallControl.hangUp in call.controls)
                    commandIntent(context, model, call, CallAction.hangUp) else null
                if (!plain && hangUp != null) {
                    style = NotificationCompat.CallStyle.forOngoingCall(person, hangUp)
                } else {
                    hangUp?.let { builder.addAction(R.drawable.awn_call_ic_call_end, call.text(CallKeys.TEXT_HANG_UP), it) }
                }
                // CallStyle shows one button besides hang up: the one that
                // matters now first (resume a held call, else mute), then the other.
                val held = call.state == CallState.held
                val mute = if (CallControl.mute !in call.controls) null else {
                    val action = if (muted) CallAction.unmute else CallAction.mute
                    NotificationCompat.Action(
                        if (muted) R.drawable.awn_call_ic_mic else R.drawable.awn_call_ic_mic_off,
                        call.text(if (muted) CallKeys.TEXT_UNMUTE else CallKeys.TEXT_MUTE),
                        commandIntent(context, model, call, action)
                    )
                }
                val hold = if (CallControl.hold !in call.controls || call.state == CallState.outgoing) null else
                    NotificationCompat.Action(
                        if (held) R.drawable.awn_call_ic_play else R.drawable.awn_call_ic_pause,
                        call.text(if (held) CallKeys.TEXT_RESUME else CallKeys.TEXT_HOLD),
                        commandIntent(context, model, call, if (held) CallAction.unhold else CallAction.hold)
                    )
                (if (held) listOf(hold, mute) else listOf(mute, hold)).filterNotNull().forEach { builder.addAction(it) }
            }
            else -> return
        }
        style?.let {
            it.setIsVideo(call.video)
            builder.setStyle(it)
        }
        modelButtons.forEach { builder.addAction(it) }
    }

    /**
     * The core's tap intent (the launch activity with the model), marked as a
     * call's so the app's activity shows over the lock screen. Same request
     * code and intent as the core's: it replaces it. Also the full-screen intent.
     */
    fun contentIntent(context: Context, id: Int, model: Map<String, Any?>, call: CallModel): PendingIntent {
        val launch = context.packageManager.getLaunchIntentForPackage(context.packageName) ?: Intent()
        launch.action = Definitions.SELECT_NOTIFICATION
        launch.putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        launch.putExtra(CallKeys.EXTRA_CALL_ID, call.callId)
        launch.addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP)
        return PendingIntent.getActivity(context, id, launch, immutable())
    }

    /** Decline, hang up, mute, hold: to [CallCommandReceiver] (works with the app killed). */
    fun commandIntent(context: Context, model: Map<String, Any?>, call: CallModel, action: CallAction): PendingIntent {
        val intent = Intent(context, CallCommandReceiver::class.java).apply {
            this.action = CallKeys.INTENT_COMMAND
            // Unique per call and command (extras don't tell PendingIntents apart).
            data = Uri.parse("awn-call://" + Uri.encode(call.callId) + "/" + action.name)
            putExtra(CallKeys.EXTRA_ACTION, action.name)
            putExtra(CallKeys.EXTRA_CALL_ID, call.callId)
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
        }
        return PendingIntent.getBroadcast(context, ("${call.callId}/${action.name}").hashCode(), intent, immutable())
    }

    /** Answer: [CallAnswerActivity] applies it and opens the app (an activity: no trampoline). */
    fun answerIntent(context: Context, model: Map<String, Any?>, call: CallModel): PendingIntent {
        val intent = Intent(context, CallAnswerActivity::class.java).apply {
            data = Uri.parse("awn-call://" + Uri.encode(call.callId) + "/accept")
            putExtra(CallKeys.EXTRA_CALL_ID, call.callId)
            putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
            addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
        }
        return PendingIntent.getActivity(context, ("${call.callId}/accept").hashCode(), intent, immutable())
    }

    private fun immutable(): Int {
        var flags = PendingIntent.FLAG_UPDATE_CURRENT
        if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.M) flags = flags or PendingIntent.FLAG_IMMUTABLE
        return flags
    }
}
