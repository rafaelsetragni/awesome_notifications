---
title: 🔆 Wake Up Screen Notifications
# description: Quidem magni aut exercitationem maxime rerum eos.
---

To send notifications that wake up the device screen even when it is locked, you can set the `wakeUpScreen` property to true.
To enable this property on Android, you need to add the `WAKE_LOCK` permission and the property `android:turnScreenOn` into your `AndroidManifest.xml` file, inside the `Android/app/src/main/` folder.

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
   package="com.example">

   <uses-permission android:name="android.permission.WAKE_LOCK" />

   <application
        android:name="io.flutter.app.FlutterApplication"
        android:icon="@mipmap/ic_launcher"
        android:label="Awesome Notifications for Flutter">
        <activity
            android:name=".MainActivity"
            android:configChanges="orientation|keyboardHidden|keyboard|screenSize|smallestScreenSize|locale|layoutDirection|fontScale|screenLayout|density|uiMode"
            android:hardwareAccelerated="true"
            android:launchMode="singleTop"
            android:theme="@style/LaunchTheme"
            android:turnScreenOn="true"
            android:windowSoftInputMode="adjustResize">
            …
        </activity>
            …
   </application>
</manifest>
```
