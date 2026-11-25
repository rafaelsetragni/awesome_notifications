package me.carda.android_awn_core

import android.content.Context
import androidx.core.app.NotificationManagerCompat

/**
 * Turns a notification's control into its action event: the path a tap on a
 * non-foreground button takes, open to add-ons whose controls are not
 * notification buttons (a media session command, for instance).
 */
object NotificationActions {

    /**
     * Emits the action (or dismiss) event of [model] for the control
     * [buttonKey], with [input] as its typed value (`buttonKeyInput`).
     *
     * [button] describes a control that is not one of the model's action
     * buttons (its key, `actionType`, `autoDismissible`); null takes the
     * model's button with that key. As for a pressed button, the notification
     * is dismissed when the button asks for it, and a `DismissAction` emits the
     * dismiss event instead. [onFinished] runs once the action was delivered
     * (a background isolate may take a while: a receiver keeps itself alive
     * until then).
     */
    @JvmStatic
    @JvmOverloads
    fun dispatch(
        context: Context,
        model: Map<String, Any?>,
        buttonKey: String,
        input: String? = null,
        button: Map<String, Any?>? = null,
        onFinished: () -> Unit = {}
    ) {
        val builder = NotificationBuilder.getNewBuilder()
        val control = button ?: builder.findButton(model, buttonKey)
        val actionType = builder.buttonActionType(control)

        var content = builder.contentMap(model) +
            (Definitions.NOTIFICATION_BUTTON_KEY_PRESSED to buttonKey)
        if (input != null) content = content + (Definitions.NOTIFICATION_BUTTON_KEY_INPUT to input)

        if (builder.shouldButtonAutoDismiss(control)) {
            builder.readId(content)?.let { NotificationManagerCompat.from(context).cancel(it) }
        }

        // 0.12 routing: a disabled control does nothing; a silent-background
        // one always runs in the background isolate; any other runs in the app
        // when it is listening, otherwise (app killed) in the background isolate.
        when {
            actionType == ActionType.DisabledAction -> onFinished()

            actionType == ActionType.DismissAction -> {
                AwesomeEventsReceiver.notifyAwesomeEvent(
                    Definitions.EVENT_NOTIFICATION_DISMISSED,
                    builder.registerDismissedEvent(content, NotificationLifeCycle.Background)
                )
                onFinished()
            }

            actionType == ActionType.SilentBackgroundAction ||
                !AwesomeEventsReceiver.hasListeners() -> {
                val lifeCycle = if (AwesomeEventsReceiver.hasListeners()) {
                    NotificationLifeCycle.Background
                } else {
                    NotificationLifeCycle.Terminated
                }
                BackgroundActions.execute(
                    context, builder.registerActionEvent(content, lifeCycle, actionType), onFinished)
            }

            else -> {
                AwesomeEventsReceiver.notifyAwesomeEvent(
                    Definitions.EVENT_DEFAULT_ACTION,
                    builder.registerActionEvent(content, NotificationLifeCycle.Background, actionType)
                )
                onFinished()
            }
        }
    }
}
