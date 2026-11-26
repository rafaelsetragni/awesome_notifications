package me.carda.awesome_notifications

import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.junit.Test
import org.mockito.Mockito

/*
 * This demonstrates a simple unit test of the Kotlin portion of this plugin's implementation.
 *
 * Once you have built the plugin's example app, you can run these tests from the command
 * line by running `./gradlew testDebugUnitTest` in the `example/android/` directory, or
 * you can run them directly from IDEs that support JUnit such as Android Studio.
 */

class AwesomeNotificationsPluginTest {
    @Test
    fun onMethodCall_getPlatformVersion_returnsExpectedValue() {
        val plugin = AwesomeNotificationsPlugin()

        val call = MethodCall("getPlatformVersion", null)
        val mockResult: MethodChannel.Result = Mockito.mock(MethodChannel.Result::class.java)
        plugin.onMethodCall(call, mockResult)

        Mockito.verify(mockResult).success("Android " + android.os.Build.VERSION.RELEASE)
    }
}

/** The `getPermissionStatuses` method channel contract (0.12.1). */
@org.junit.runner.RunWith(org.robolectric.RobolectricTestRunner::class)
@org.robolectric.annotation.Config(sdk = [34])
class GetPermissionStatusesTest {

    private val context: android.content.Context =
        androidx.test.core.app.ApplicationProvider.getApplicationContext()

    private fun plugin(): AwesomeNotificationsPlugin {
        val plugin = AwesomeNotificationsPlugin()
        val field = AwesomeNotificationsPlugin::class.java.getDeclaredField("core")
        field.isAccessible = true
        field.set(plugin, me.carda.android_awn_core.AwesomeNotifications(context))
        return plugin
    }

    private fun call(arguments: Any?): MethodChannel.Result {
        val result = Mockito.mock(MethodChannel.Result::class.java)
        plugin().onMethodCall(MethodCall("getPermissionStatuses", arguments), result)
        return result
    }

    @Test fun missingArguments() {
        Mockito.verify(call(null)).error("MISSING_ARGUMENTS", "Arguments are missing", "arguments.required")
    }

    @Test fun anEmptyPermissionList() {
        Mockito.verify(call(mapOf("channelKey" to null, "permissions" to emptyList<String>())))
            .error("INVALID_ARGUMENTS", "Permission list is required", "arguments.required.permissionList")
        Mockito.verify(call(mapOf("channelKey" to null)))
            .error("INVALID_ARGUMENTS", "Permission list is required", "arguments.required.permissionList")
    }

    @Test fun anUnknownChannel() {
        Mockito.verify(call(mapOf("channelKey" to "nope", "permissions" to listOf("Alert"))))
            .error("INVALID_ARGUMENTS", "Channel nope does not exist.", "arguments.invalid.channel.key")
    }

    @Test fun answersAMapOfStatuses() {
        val result = call(mapOf("channelKey" to null, "permissions" to listOf("Alert", "Provisional")))
        Mockito.verify(result).success(mapOf("Alert" to "granted", "Provisional" to "notSupported"))
    }
}
