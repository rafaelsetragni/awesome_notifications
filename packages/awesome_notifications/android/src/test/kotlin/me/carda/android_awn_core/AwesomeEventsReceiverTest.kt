package me.carda.android_awn_core

import org.junit.Assert.assertEquals
import org.junit.Test

/** The lifecycle-event broadcaster used to push events to the Flutter plugin. */
class AwesomeEventsReceiverTest {

    private class Recorder : AwesomeEventListener {
        val events = mutableListOf<Pair<String, Map<String, Any?>>>()
        override fun onNewAwesomeEvent(eventType: String, content: Map<String, Any?>) {
            events.add(eventType to content)
        }
    }

    @Test fun deliversToSubscribers() {
        val recorder = Recorder()
        AwesomeEventsReceiver.subscribe(recorder)
        try {
            AwesomeEventsReceiver.notifyAwesomeEvent("created", mapOf("id" to 1))
            assertEquals(1, recorder.events.size)
            assertEquals("created", recorder.events[0].first)
            assertEquals(mapOf("id" to 1), recorder.events[0].second)
        } finally {
            AwesomeEventsReceiver.unsubscribe(recorder)
        }
    }

    @Test fun stopsAfterUnsubscribe() {
        val recorder = Recorder()
        AwesomeEventsReceiver.subscribe(recorder)
        AwesomeEventsReceiver.unsubscribe(recorder)
        AwesomeEventsReceiver.notifyAwesomeEvent("displayed", emptyMap())
        assertEquals(0, recorder.events.size)
    }

    @Test fun duplicateSubscribeDeliversOnce() {
        val recorder = Recorder()
        AwesomeEventsReceiver.subscribe(recorder)
        AwesomeEventsReceiver.subscribe(recorder)
        try {
            AwesomeEventsReceiver.notifyAwesomeEvent("evt", emptyMap())
            assertEquals(1, recorder.events.size)
        } finally {
            AwesomeEventsReceiver.unsubscribe(recorder)
        }
    }
}
