package me.carda.android_awn_core

import android.content.Context

/**
 * Where an action goes when no app is listening (or when it must always run
 * in the background): the Flutter plugin installs an executor that runs the
 * app's action handler in a background isolate, as 0.12 did. The core stays
 * Flutter-free.
 */
object BackgroundActions {

    /**
     * Runs [action] (the action event's data) in the background and calls
     * `done` when it finished (or was dropped).
     */
    fun interface Executor {
        fun execute(context: Context, action: Map<String, Any?>, done: () -> Unit)
    }

    @Volatile
    var executor: Executor? = null

    fun execute(context: Context, action: Map<String, Any?>, done: () -> Unit) {
        val current = executor
        if (current == null) done() else current.execute(context, action, done)
    }
}
