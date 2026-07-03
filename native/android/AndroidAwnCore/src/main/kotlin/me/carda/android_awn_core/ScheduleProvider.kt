package me.carda.android_awn_core

import android.content.Context

/**
 * Decorator seam for scheduling a notification's delivery (AlarmManager) without
 * the core depending on the scheduling feature.
 *
 * On Android there is no native calendar/interval trigger: a scheduled
 * notification must be registered with AlarmManager and posted later by a
 * receiver. The scheduling decorator registers an implementation via
 * [AwesomeNotifications.scheduleProvider]; in the bare core it is null and a
 * notification carrying a `schedule` is simply posted immediately.
 */
interface ScheduleProvider {
    /**
     * Schedules [model] (which may carry a `schedule` map) for later delivery.
     * Returns true when it was scheduled — the core then does NOT post it now.
     * Returns false to let the core post it immediately.
     */
    fun schedule(context: Context, model: Map<String, Any?>): Boolean
}
