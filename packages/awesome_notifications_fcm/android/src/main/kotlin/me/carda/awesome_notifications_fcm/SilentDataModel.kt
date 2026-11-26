package me.carda.awesome_notifications_fcm

import me.carda.android_awn_core.Definitions
import me.carda.android_awn_core.JsonUtils
import me.carda.android_awn_core.NotificationLifeCycle
import me.carda.android_awn_core.NotificationSource

/**
 * A silent (data-only) push, serialized to/from the map delivered to the Dart
 * `FcmSilentData`. Envelope fields (id / created date / source / lifecycle) are
 * pulled out; everything else is exposed under [data].
 */
class SilentDataModel {
    var id: Int? = null
    var data: MutableMap<String, String?> = mutableMapOf()
    var createdDate: String? = null
    var createdSource: NotificationSource = NotificationSource.Firebase
    var createdLifeCycle: NotificationLifeCycle = NotificationLifeCycle.Terminated

    fun fromData(remoteData: Map<String, String>): SilentDataModel {
        for ((key, value) in remoteData) {
            when (key) {
                Definitions.NOTIFICATION_ID -> id = value.toIntOrNull()
                Definitions.NOTIFICATION_CREATED_DATE -> createdDate = value
                Definitions.NOTIFICATION_CREATED_SOURCE ->
                    createdSource = NotificationSource.values()
                        .firstOrNull { it.name == value } ?: NotificationSource.Firebase
                Definitions.NOTIFICATION_CREATED_LIFECYCLE ->
                    createdLifeCycle = NotificationLifeCycle.values()
                        .firstOrNull { it.name == value } ?: NotificationLifeCycle.Terminated
                FcmDefinitions.FLAG_IS_SILENT_DATA,
                FcmDefinitions.SILENT_HANDLE -> { /* routing keys, not user data */ }
                else -> data[key] = value
            }
        }
        if (createdDate == null) createdDate = FcmDateUtils.nowUtc()
        return this
    }

    fun toMap(): Map<String, Any?> {
        val map = mutableMapOf<String, Any?>()
        map.putAll(data)
        map[Definitions.NOTIFICATION_ID] = id?.toString()
        map[Definitions.NOTIFICATION_CREATED_DATE] = createdDate
        map[Definitions.NOTIFICATION_CREATED_SOURCE] = createdSource.name
        map[Definitions.NOTIFICATION_CREATED_LIFECYCLE] = createdLifeCycle.name
        return map
    }

    fun toJson(): String = JsonUtils.getInstance().toJson(toMap())

    fun fromJson(json: String?): SilentDataModel {
        if (json.isNullOrBlank()) return this
        val map = JsonUtils.getInstance().fromJson(json)
        val flat = map.mapValues { it.value?.toString() }
        @Suppress("UNCHECKED_CAST")
        return fromData(flat.filterValues { it != null } as Map<String, String>)
    }
}
