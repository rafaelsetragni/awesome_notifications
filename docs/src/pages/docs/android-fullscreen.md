---
title: Full-Screen Notifications
# description: Quidem magni aut exercitationem maxime rerum eos.
---

To send notifications in full screen mode, even when it is locked, you can set the `fullScreenIntent` property to true.

Sometimes when your notification is displayed, your app is automatically triggered by the Android system, similar to when the user taps on it. That way, you can display your page in full screen and customize it as you like. There is no way to control when your full screen will be called.

To enable this property, you need to add the property `android:showOnLockScreen="true"` and the `USE_FULL_SCREEN_INTENT` permission to your `AndroidManifest.xml` file, inside the `Android/app/src/main/` folder

```xml
<!-- Android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">
<uses-permission android:name="android.permission.USE_FULL_SCREEN_INTENT" />
<application>
…
<activity
            android:name=".MainActivity"
            android:showOnLockScreen="true">
…
</activity>
…
</application>
</manifest>
```

On Android, for versions greater or equal than 11, you need to explicitly request the user consent to enable this feature. You can request the permission with `requestPermissionToSendNotifications`.
