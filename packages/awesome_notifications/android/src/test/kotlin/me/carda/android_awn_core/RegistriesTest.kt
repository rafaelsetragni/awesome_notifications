package me.carda.android_awn_core

import android.content.Context
import androidx.test.core.app.ApplicationProvider
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith
import org.robolectric.RobolectricTestRunner
import org.robolectric.annotation.Config

/** The builder decorator chain must compose in ascending priority order. */
class NotificationBuilderRegistryTest {

    @Before fun clean() = NotificationBuilderRegistry.clearForTest()
    @After fun reset() = NotificationBuilderRegistry.clearForTest()

    @Test fun composesInAscendingPriority() {
        val order = mutableListOf<Int>()
        // Register out of order; the fold must apply them low→high priority.
        NotificationBuilderRegistry.register(100) { inner -> order.add(100); inner }
        NotificationBuilderRegistry.register(10) { inner -> order.add(10); inner }
        NotificationBuilderRegistry.register(50) { inner -> order.add(50); inner }

        NotificationBuilderRegistry.makeBuilder()

        assertEquals(listOf(10, 50, 100), order)
    }

    @Test fun bareRegistryReturnsBaseBuilder() {
        assertNotNull(NotificationBuilderRegistry.makeBuilder())
    }
}

/** cancel* must fan out to every registered interceptor. */
@RunWith(RobolectricTestRunner::class)
@Config(sdk = [34])
class CancelInterceptorRegistryTest {

    private val context: Context = ApplicationProvider.getApplicationContext()

    private class Recorder : CancelInterceptor {
        val calls = mutableListOf<String>()
        override fun onCancel(context: Context, id: Int) { calls.add("cancel:$id") }
        override fun onCancelAll(context: Context) { calls.add("all") }
        override fun onCancelByChannelKey(context: Context, channelKey: String) {
            calls.add("channel:$channelKey")
        }
        override fun onCancelByGroupKey(context: Context, groupKey: String) {
            calls.add("group:$groupKey")
        }
    }

    @Test fun forwardsEveryCancelVariant() {
        val recorder = Recorder()
        CancelInterceptorRegistry.register(recorder)
        try {
            CancelInterceptorRegistry.onCancel(context, 7)
            CancelInterceptorRegistry.onCancelAll(context)
            CancelInterceptorRegistry.onCancelByChannelKey(context, "c")
            CancelInterceptorRegistry.onCancelByGroupKey(context, "g")
            assertEquals(listOf("cancel:7", "all", "channel:c", "group:g"), recorder.calls)
        } finally {
            CancelInterceptorRegistry.unregister(recorder)
        }
    }

    @Test fun registerIsIdempotent() {
        val recorder = Recorder()
        CancelInterceptorRegistry.register(recorder)
        CancelInterceptorRegistry.register(recorder)
        try {
            CancelInterceptorRegistry.onCancel(context, 1)
            assertEquals(1, recorder.calls.size) // delivered once, not twice
        } finally {
            CancelInterceptorRegistry.unregister(recorder)
        }
    }
}
