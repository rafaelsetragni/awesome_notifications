package me.carda.awesome_notifications

import android.Manifest
import android.app.Activity
import android.app.NotificationManager
import android.content.Context
import android.content.Intent
import android.os.Bundle
import android.os.Looper
import androidx.core.app.RemoteInput
import androidx.test.core.app.ApplicationProvider
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import io.flutter.plugin.common.BinaryMessenger
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.StandardMethodCodec
import java.nio.ByteBuffer
import java.util.TimeZone
import java.util.concurrent.Executor
import me.carda.android_awn_core.AwesomeEventsReceiver
import me.carda.android_awn_core.AwesomeMethodHandler
import me.carda.android_awn_core.AwesomeMethodHandlerRegistry
import me.carda.android_awn_core.AwesomeNotifications
import me.carda.android_awn_core.BackgroundActions
import me.carda.android_awn_core.BuildOutcome
import me.carda.android_awn_core.CancelInterceptor
import me.carda.android_awn_core.CancelInterceptorRegistry
import me.carda.android_awn_core.ChannelManager
import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationBuilder
import me.carda.android_awn_core.NotificationBuilderRegistry
import me.carda.android_awn_core.PermissionManager
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertSame
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.mockito.Mockito
import org.robolectric.Robolectric
import org.robolectric.RobolectricTestRunner
import org.robolectric.Shadows.shadowOf
import org.robolectric.android.controller.ActivityController
import org.robolectric.annotation.Config

/**
 * The Flutter bridge end to end: the method channel calls it answers, the
 * events it sends to Dart, the notification taps (cold start and new intent)
 * it turns into action / dismiss events, and the permission request bound to
 * the attached Activity.
 */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class PluginBridgeTest {

    /** Records what the plugin sends to Dart and the handlers it installs. */
    private class FakeMessenger : BinaryMessenger {
        val sent = mutableListOf<MethodCall>()
        val handlers = mutableMapOf<String, BinaryMessenger.BinaryMessageHandler?>()

        override fun send(channel: String, message: ByteBuffer?) = send(channel, message, null)

        override fun send(channel: String, message: ByteBuffer?, callback: BinaryMessenger.BinaryReply?) {
            message!!.rewind()
            sent.add(StandardMethodCodec.INSTANCE.decodeMethodCall(message))
        }

        override fun setMessageHandler(channel: String, handler: BinaryMessenger.BinaryMessageHandler?) {
            handlers[channel] = handler
        }
    }

    private val context: Context = ApplicationProvider.getApplicationContext()
    private val messenger = FakeMessenger()
    private lateinit var plugin: AwesomeNotificationsPlugin
    private val calls = mutableListOf<String>()

    private val interceptor = object : CancelInterceptor {
        override fun onDismiss(context: Context, id: Int) { calls.add("dismiss:$id") }
        override fun onCancel(context: Context, id: Int) { calls.add("cancel:$id") }
        override fun onDismissAll(context: Context) { calls.add("dismissAll") }
        override fun onCancelAll(context: Context) { calls.add("cancelAll") }
        override fun onDismissByChannelKey(context: Context, channelKey: String) { calls.add("dismissChannel:$channelKey") }
        override fun onCancelByChannelKey(context: Context, channelKey: String) { calls.add("cancelChannel:$channelKey") }
        override fun onDismissByGroupKey(context: Context, groupKey: String) { calls.add("dismissGroup:$groupKey") }
        override fun onCancelByGroupKey(context: Context, groupKey: String) { calls.add("cancelGroup:$groupKey") }
    }

    private fun manager() = context.getSystemService(Context.NOTIFICATION_SERVICE) as NotificationManager

    /** A real binding on the fake messenger (the engine parts the plugin never reads are null). */
    private fun binding(): FlutterPlugin.FlutterPluginBinding =
        FlutterPlugin.FlutterPluginBinding::class.java.constructors.single()
            .newInstance(context, null, messenger, null, null, null, null) as FlutterPlugin.FlutterPluginBinding

    @Before fun setUp() {
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
        shadowOf(manager()).setNotificationsEnabled(true)
        shadowOf(manager()).setImportance(NotificationManager.IMPORTANCE_DEFAULT)
        BackgroundActions.executor = null
        plugin = AwesomeNotificationsPlugin()
        plugin.onAttachedToEngine(binding())
        CancelInterceptorRegistry.register(interceptor)
        PermissionManager.onForeground() // drain anything a previous test left waiting
    }

    @After fun tearDown() {
        CancelInterceptorRegistry.unregister(interceptor)
        AwesomeEventsReceiver.unsubscribe(plugin)
        NotificationBuilderRegistry.clearForTest()
        ChannelManager.clearForTest()
        BackgroundActions.executor = null
    }

    /** Swaps the plugin's engine for one that builds inline (no background thread). */
    private fun useSyncCore() {
        val field = AwesomeNotificationsPlugin::class.java.getDeclaredField("core")
        field.isAccessible = true
        field.set(plugin, AwesomeNotifications(context, Executor { it.run() }))
    }

    private fun call(method: String, arguments: Any? = null): MethodChannel.Result {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(MethodCall(method, arguments), result)
        shadowOf(Looper.getMainLooper()).idle()
        return result
    }

    private fun idle() = shadowOf(Looper.getMainLooper()).idle()

    // MARK: - Engine attach / detach

    @Test fun attachingInstallsTheChannelAndTheBackgroundExecutor() {
        assertNotNull(messenger.handlers["awesome_notifications"])
        assertSame(ActionBackgroundExecutor, BackgroundActions.executor)
    }

    @Test fun detachingRemovesTheChannelHandlerAndStopsTheEvents() {
        call("initialize", emptyMap<String, Any?>())
        plugin.onDetachedFromEngine(binding())
        assertNull(messenger.handlers["awesome_notifications"])
        assertFalse(AwesomeEventsReceiver.hasListeners())
    }

    // MARK: - initialize / handles

    @Test fun initializeSetsChannelsGroupsIconAndBackgroundHandle() {
        val result = call(
            "initialize",
            mapOf(
                Definitions.INITIALIZE_CHANNELS to listOf(
                    mapOf(
                        Definitions.NOTIFICATION_CHANNEL_KEY to "basic",
                        Definitions.NOTIFICATION_CHANNEL_NAME to "Basic",
                        Definitions.NOTIFICATION_CHANNEL_GROUP_KEY to "grp"
                    )
                ),
                Definitions.INITIALIZE_CHANNEL_GROUPS to listOf(
                    mapOf(
                        Definitions.NOTIFICATION_CHANNEL_GROUP_KEY to "grp",
                        Definitions.NOTIFICATION_CHANNEL_GROUP_NAME to "Group"
                    )
                ),
                Definitions.INITIALIZE_DEFAULT_ICON to null,
                ActionHandles.BACKGROUND_HANDLE to 1234L
            )
        )
        Mockito.verify(result).success(true)
        val channel = manager().getNotificationChannel("basic")
        assertEquals("Basic", channel.name)
        assertEquals("grp", channel.group)
        assertEquals(1234L, ActionHandles.get(context, ActionHandles.BACKGROUND_HANDLE))
        assertTrue(AwesomeEventsReceiver.hasListeners())
    }

    @Test fun initializeWithoutArgumentsStillListens() {
        Mockito.verify(call("initialize")).success(true)
        assertEquals(0L, ActionHandles.get(context, ActionHandles.BACKGROUND_HANDLE))
        assertTrue(AwesomeEventsReceiver.hasListeners())
    }

    @Test fun eventsReachDartOnTheMainThreadOnceInitialized() {
        call("initialize", emptyMap<String, Any?>())
        AwesomeEventsReceiver.notifyAwesomeEvent("notificationCreated", mapOf("id" to 3))
        assertTrue(messenger.sent.isEmpty()) // posted, not sent inline
        idle()
        assertEquals(1, messenger.sent.size)
        assertEquals("notificationCreated", messenger.sent[0].method)
        assertEquals(mapOf("id" to 3), messenger.sent[0].arguments)
    }

    @Test fun setEventHandlesKeepsTheActionHandle() {
        Mockito.verify(call("setEventHandles", mapOf(ActionHandles.ACTION_HANDLE to 99))).success(true)
        assertEquals(99L, ActionHandles.get(context, ActionHandles.ACTION_HANDLE))
        // A missing handle forgets it.
        Mockito.verify(call("setEventHandles", null)).success(true)
        assertEquals(0L, ActionHandles.get(context, ActionHandles.ACTION_HANDLE))
    }

    // MARK: - Simple answers

    @Test fun timeZoneIdentifiers() {
        Mockito.verify(call("getLocalTimeZoneIdentifier")).success(TimeZone.getDefault().id)
        Mockito.verify(call("getUtcTimeZoneIdentifier")).success("UTC")
    }

    @Test fun isNotificationAllowedFollowsTheSystem() {
        Mockito.verify(call("isNotificationAllowed")).success(true)
        shadowOf(manager()).setNotificationsEnabled(false)
        Mockito.verify(call("isNotificationAllowed")).success(false)
    }

    @Test fun setNotificationChannelCreatesTheChannel() {
        Mockito.verify(
            call(
                "setNotificationChannel",
                mapOf(
                    Definitions.NOTIFICATION_CHANNEL_KEY to "news",
                    Definitions.NOTIFICATION_CHANNEL_NAME to "News"
                )
            )
        ).success(true)
        assertNotNull(manager().getNotificationChannel("news"))
        // Without arguments it still answers true.
        Mockito.verify(call("setNotificationChannel", "bad")).success(true)
    }

    @Test fun unknownMethodsGoToTheDecoratorsOrAreNotImplemented() {
        val handler = object : AwesomeMethodHandler {
            override fun handle(method: String, arguments: Any?, result: (Any?) -> Unit): Boolean = false
            override fun handle(
                method: String,
                arguments: Any?,
                result: (Any?) -> Unit,
                error: (String, String?, Any?) -> Unit
            ): Boolean = when (method) {
                "decoratorOk" -> { result("ok:$arguments"); true }
                "decoratorFail" -> { error("CODE", "msg", "details"); true }
                else -> false
            }
        }
        AwesomeMethodHandlerRegistry.register(handler)
        try {
            Mockito.verify(call("decoratorOk", 5)).success("ok:5")
            Mockito.verify(call("decoratorFail")).error("CODE", "msg", "details")
            Mockito.verify(call("nobodyKnowsThis")).notImplemented()
        } finally {
            AwesomeMethodHandlerRegistry.unregister(handler)
        }
    }

    // MARK: - Create / dismiss / cancel

    @Test fun createNewNotificationWithoutArgumentsIsFalse() {
        Mockito.verify(call("createNewNotification", null)).success(false)
    }

    @Test fun createNewNotificationPostsAndAnswersTrue() {
        useSyncCore()
        ChannelManager.setChannel(
            context,
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to "ch", Definitions.NOTIFICATION_CHANNEL_NAME to "Ch")
        )
        val result = call(
            "createNewNotification",
            mapOf(
                Definitions.NOTIFICATION_CONTENT to mapOf(
                    Definitions.NOTIFICATION_ID to 11,
                    Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
                    Definitions.NOTIFICATION_TITLE to "Hello"
                )
            )
        )
        Mockito.verify(result).success(true)
        assertEquals(11, manager().activeNotifications.single().id)
    }

    @Test fun createNewNotificationRejectedByADecoratorFails() {
        useSyncCore()
        NotificationBuilderRegistry.register(10) { inner ->
            object : NotificationBuilder(inner) {
                override fun build(context: Context, model: Map<String, Any?>) =
                    BuildOutcome.Failed("INVALID_ARGUMENTS", "bad schedule", "arguments.invalid.schedule")
            }
        }
        val result = call(
            "createNewNotification",
            mapOf(Definitions.NOTIFICATION_CONTENT to mapOf(Definitions.NOTIFICATION_ID to 1))
        )
        Mockito.verify(result).error("INVALID_ARGUMENTS", "bad schedule", "arguments.invalid.schedule")
        Mockito.verify(result, Mockito.never()).success(Mockito.any())
    }

    @Test fun dismissAndCancelCallsReachTheEngine() {
        Mockito.verify(call("dismissNotification", 1)).success(true)
        Mockito.verify(call("cancelNotification", 2L)).success(true)
        Mockito.verify(call("dismissNotificationsByChannelKey", "c1")).success(true)
        Mockito.verify(call("cancelNotificationsByChannelKey", "c2")).success(true)
        Mockito.verify(call("dismissNotificationsByGroupKey", "g1")).success(true)
        Mockito.verify(call("cancelNotificationsByGroupKey", "g2")).success(true)
        Mockito.verify(call("dismissAllNotifications")).success(true)
        Mockito.verify(call("cancelAllNotifications")).success(true)
        assertEquals(
            listOf(
                "dismiss:1",
                "cancel:2", "dismiss:2",
                "dismissChannel:c1",
                "cancelChannel:c2", "dismissChannel:c2",
                "dismissGroup:g1",
                "cancelGroup:g2", "dismissGroup:g2",
                "dismissAll",
                "cancelAll", "dismissAll"
            ),
            calls
        )
    }

    @Test fun dismissAndCancelWithBadArgumentsOnlyAnswerTrue() {
        Mockito.verify(call("dismissNotification", "x")).success(true)
        Mockito.verify(call("cancelNotification", null)).success(true)
        Mockito.verify(call("dismissNotificationsByChannelKey", 1)).success(true)
        Mockito.verify(call("cancelNotificationsByChannelKey", null)).success(true)
        Mockito.verify(call("dismissNotificationsByGroupKey", 1)).success(true)
        Mockito.verify(call("cancelNotificationsByGroupKey", null)).success(true)
        assertTrue(calls.isEmpty())
    }

    // MARK: - Permissions

    @Test fun getPermissionStatusesFailsUnexpectedErrorsAsUnknown() {
        val result = call(
            "getPermissionStatuses",
            mapOf(Definitions.NOTIFICATION_CHANNEL_KEY to 5, Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert"))
        )
        Mockito.verify(result).error(
            Mockito.eq("UNKNOWN_EXCEPTION"), Mockito.anyString(), Mockito.eq("unexpectedError.ClassCastException"))
    }

    @Test fun requestNotificationsAnswersNothingMissingWhenAllowed() {
        val result = call(
            "requestNotifications",
            mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert", "Sound"))
        )
        Mockito.verify(result).success(emptyList<String>())
    }

    @Test fun requestNotificationsWithoutArgumentsAnswersAnEmptyList() {
        Mockito.verify(call("requestNotifications")).success(emptyList<String>())
    }

    @Test fun requestNotificationsForAnUnknownChannelFails() {
        val result = call(
            "requestNotifications",
            mapOf(
                Definitions.NOTIFICATION_CHANNEL_KEY to "nope",
                Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert")
            )
        )
        Mockito.verify(result).error("INVALID_ARGUMENTS", "Channel nope does not exist.", "arguments.invalid.channel.key")
    }

    @Test fun requestNotificationsFailsUnexpectedErrorsAsUnknown() {
        val result = call(
            "requestNotifications",
            mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf(1, 2))
        )
        Mockito.verify(result).error(
            Mockito.eq("UNKNOWN_EXCEPTION"), Mockito.anyString(), Mockito.eq("unexpectedError.ClassCastException"))
    }

    @Test fun permissionDialogResultsAreRoutedToThePermissionManager() {
        assertTrue(plugin.onRequestPermissionsResult(PermissionManager.REQUEST_CODE, arrayOf(), intArrayOf()))
        assertFalse(plugin.onRequestPermissionsResult(3, arrayOf(), intArrayOf()))
    }

    // MARK: - Activity

    private fun activityBinding(activity: Activity): ActivityPluginBinding {
        val binding = Mockito.mock(ActivityPluginBinding::class.java)
        Mockito.`when`(binding.activity).thenReturn(activity)
        return binding
    }

    private fun notificationModel(
        id: Int = 5,
        actionType: String? = null,
        buttons: List<Map<String, Any?>> = emptyList()
    ): Map<String, Any?> = mapOf(
        Definitions.NOTIFICATION_CONTENT to mapOf(
            Definitions.NOTIFICATION_ID to id,
            Definitions.NOTIFICATION_CHANNEL_KEY to "ch",
            Definitions.NOTIFICATION_TITLE to "T",
            Definitions.NOTIFICATION_ACTION_TYPE to actionType
        ),
        Definitions.NOTIFICATION_BUTTONS to buttons
    )

    private fun tapIntent(model: Map<String, Any?>): Intent =
        Intent(Definitions.SELECT_NOTIFICATION)
            .putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))

    private fun buttonIntent(model: Map<String, Any?>, key: String?): Intent =
        Intent(Definitions.NOTIFICATION_BUTTON_ACTION_PREFIX + "_" + key)
            .putExtra(Definitions.NOTIFICATION_JSON, JsonUtils.getInstance().toJson(model))
            .apply { if (key != null) putExtra(Definitions.NOTIFICATION_BUTTON_KEY_PRESSED, key) }

    private fun events(): List<MethodCall> {
        idle()
        return messenger.sent.toList()
    }

    @Test fun aColdStartTapIsTheInitialAction() {
        call("initialize", emptyMap<String, Any?>())
        val intent = tapIntent(notificationModel(id = 5))
        val activity = Robolectric.buildActivity(Activity::class.java, intent).setup().get()
        plugin.onAttachedToActivity(activityBinding(activity))

        val sent = events()
        assertEquals(Definitions.EVENT_DEFAULT_ACTION, sent.single().method)
        @Suppress("UNCHECKED_CAST")
        val args = sent.single().arguments as Map<String, Any?>
        assertEquals("Terminated", args[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
        assertEquals("Default", args[Definitions.NOTIFICATION_ACTION_TYPE])

        // The intent is consumed.
        assertNull(activity.intent.action)
        assertNull(activity.intent.getStringExtra(Definitions.NOTIFICATION_JSON))

        // getInitialAction answers it; removeFromEvents forgets it.
        val captor = org.mockito.ArgumentCaptor.forClass(Any::class.java)
        val first = call("getInitialAction", false)
        Mockito.verify(first).success(captor.capture())
        @Suppress("UNCHECKED_CAST")
        assertEquals(5, (captor.value as Map<String, Any?>)[Definitions.NOTIFICATION_ID])
        val second = call("getInitialAction", true)
        Mockito.verify(second).success(Mockito.notNull())
        Mockito.verify(call("getInitialAction", true)).success(null)
    }

    @Test fun withoutALaunchTapThereIsNoInitialAction() {
        val activity = Robolectric.buildActivity(Activity::class.java, Intent(Intent.ACTION_MAIN)).setup().get()
        plugin.onAttachedToActivity(activityBinding(activity))
        Mockito.verify(call("getInitialAction")).success(null)
        // An unrelated new intent, and one without an action, are ignored.
        assertFalse(plugin.onNewIntent(Intent("other")))
        assertFalse(plugin.onNewIntent(Intent()))
        // A tap intent without its model is ignored too.
        assertFalse(plugin.onNewIntent(Intent(Definitions.SELECT_NOTIFICATION)))
        assertTrue(events().isEmpty())
    }

    @Test fun aTapWhileRunningIsAForegroundAction() {
        call("initialize", emptyMap<String, Any?>())
        assertFalse(plugin.onNewIntent(tapIntent(notificationModel(id = 6))))
        @Suppress("UNCHECKED_CAST")
        val args = events().single().arguments as Map<String, Any?>
        assertEquals("Foreground", args[Definitions.NOTIFICATION_ACTION_LIFECYCLE])
        // Not a launch: no initial action.
        Mockito.verify(call("getInitialAction")).success(null)
        assertTrue(calls.isEmpty())
    }

    @Test fun aDismissActionTapDismissesAndEmitsTheDismissEvent() {
        call("initialize", emptyMap<String, Any?>())
        plugin.onNewIntent(tapIntent(notificationModel(id = 7, actionType = "DismissAction")))
        assertEquals(Definitions.EVENT_NOTIFICATION_DISMISSED, events().single().method)
        assertEquals(listOf("dismiss:7"), calls)
    }

    @Test fun aForegroundButtonCarriesItsKeyAndReply() {
        call("initialize", emptyMap<String, Any?>())
        val model = notificationModel(
            id = 8,
            buttons = listOf(
                mapOf(
                    Definitions.NOTIFICATION_BUTTON_KEY to "reply",
                    Definitions.NOTIFICATION_ACTION_TYPE to "Default"
                )
            )
        )
        val intent = buttonIntent(model, "reply")
        RemoteInput.addResultsToIntent(
            arrayOf(RemoteInput.Builder(Definitions.NOTIFICATION_BUTTON_KEY_INPUT).build()),
            intent,
            Bundle().apply { putCharSequence(Definitions.NOTIFICATION_BUTTON_KEY_INPUT, "hi there") }
        )
        plugin.onNewIntent(intent)

        val event = events().single()
        assertEquals(Definitions.EVENT_DEFAULT_ACTION, event.method)
        @Suppress("UNCHECKED_CAST")
        val args = event.arguments as Map<String, Any?>
        assertEquals("reply", args[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertEquals("hi there", args[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
        assertEquals("Default", args[Definitions.NOTIFICATION_ACTION_TYPE])
        // Auto-dismissible by default.
        assertEquals(listOf("dismiss:8"), calls)
    }

    @Test fun aKeepOnTopButtonWithoutKeyKeepsTheNotification() {
        call("initialize", emptyMap<String, Any?>())
        val model = notificationModel(
            id = 9,
            buttons = listOf(mapOf(Definitions.NOTIFICATION_BUTTON_KEY to "k", Definitions.NOTIFICATION_ACTION_TYPE to "KeepOnTop"))
        )
        plugin.onNewIntent(buttonIntent(model, null))
        @Suppress("UNCHECKED_CAST")
        val args = events().single().arguments as Map<String, Any?>
        assertEquals("", args[Definitions.NOTIFICATION_BUTTON_KEY_PRESSED])
        assertNull(args[Definitions.NOTIFICATION_BUTTON_KEY_INPUT])
        // No button matched the empty key: a default action, auto-dismissed.
        assertEquals("Default", args[Definitions.NOTIFICATION_ACTION_TYPE])
        assertEquals(listOf("dismiss:9"), calls)
    }

    @Test fun aDismissActionButtonEmitsTheDismissEventOnce() {
        call("initialize", emptyMap<String, Any?>())
        val model = notificationModel(
            id = 10,
            buttons = listOf(mapOf(Definitions.NOTIFICATION_BUTTON_KEY to "x", Definitions.NOTIFICATION_ACTION_TYPE to "DismissAction"))
        )
        plugin.onNewIntent(buttonIntent(model, "x"))
        val event = events().single()
        assertEquals(Definitions.EVENT_NOTIFICATION_DISMISSED, event.method)
        // Dismissed by the auto-dismiss only, not a second time.
        assertEquals(listOf("dismiss:10"), calls)
    }

    @Test fun theRequestAnswersWhenTheActivityIsBackInFront() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val controller: ActivityController<Activity> =
            Robolectric.buildActivity(Activity::class.java).setup()
        val activity = controller.get()
        val binding = activityBinding(activity)
        plugin.onAttachedToActivity(binding)
        Mockito.verify(binding).addRequestPermissionsResultListener(plugin)
        Mockito.verify(binding).addOnNewIntentListener(plugin)

        val result = call("requestNotifications", mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert")))
        assertEquals(
            listOf(Manifest.permission.POST_NOTIFICATIONS),
            shadowOf(activity).lastRequestedPermission.requestedPermissions.toList()
        )
        Mockito.verify(result, Mockito.never()).success(Mockito.any())

        // The user allowed it and the app is back in front.
        shadowOf(manager()).setNotificationsEnabled(true)
        controller.pause().resume()
        idle()
        Mockito.verify(result).success(emptyList<String>())
    }

    @Test fun anotherActivityResumingDoesNotAnswer() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val activity = Robolectric.buildActivity(Activity::class.java).setup().get()
        plugin.onAttachedToActivity(activityBinding(activity))
        val result = call("requestNotifications", mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert")))

        // Another activity's whole lifecycle runs: not ours.
        Robolectric.buildActivity(Activity::class.java).setup().pause().stop()
            .saveInstanceState(Bundle()).destroy()
        idle()
        Mockito.verify(result, Mockito.never()).success(Mockito.any())
        PermissionManager.onDialogResult(PermissionManager.REQUEST_CODE)
        idle()
        Mockito.verify(result).success(listOf("Alert"))
    }

    @Test fun detachedActivitiesStopWatchingAndReattachedOnesWatchAgain() {
        shadowOf(manager()).setNotificationsEnabled(false)
        val controller = Robolectric.buildActivity(Activity::class.java).setup()
        plugin.onAttachedToActivity(activityBinding(controller.get()))
        plugin.onDetachedFromActivityForConfigChanges()

        // Detached: the request has no Activity, so it opens the settings page
        // (none here: it answers right away with what is missing).
        val detached = call("requestNotifications", mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert")))
        Mockito.verify(detached).success(listOf("Alert"))
        assertNull(shadowOf(controller.get()).lastRequestedPermission)

        val again = Robolectric.buildActivity(Activity::class.java).setup()
        val binding = activityBinding(again.get())
        plugin.onReattachedToActivityForConfigChanges(binding)
        Mockito.verify(binding).addRequestPermissionsResultListener(plugin)
        Mockito.verify(binding).addOnNewIntentListener(plugin)
        val result = call("requestNotifications", mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert")))
        assertNotNull(shadowOf(again.get()).lastRequestedPermission)
        shadowOf(manager()).setNotificationsEnabled(true)
        again.pause().resume()
        idle()
        Mockito.verify(result).success(emptyList<String>())

        plugin.onDetachedFromActivity()
        val afterDetach = call("requestNotifications", mapOf(Definitions.NOTIFICATION_PERMISSIONS to listOf("Alert")))
        Mockito.verify(afterDetach).success(emptyList<String>())
    }
}
