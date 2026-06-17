/// Hides sensitive notifications when the device is on lock screen
/// [Public]: Show this notification in its entirety on all lockscreens
/// [Private]: Show this notification on all lockscreens, but conceal sensitive or private information on secure lockscreens
/// [Secret]: Do not reveal any part of this notification on a secure lockscreen
enum NotificationPrivacy { Secret, Private, Public }
