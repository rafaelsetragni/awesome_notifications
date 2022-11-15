---
title: Initial Setup
description: Quidem magni aut exercitationem maxime rerum eos.
---

Is required the minimum android SDK to 21 (Android 5.0 Lollipop) and Java compiled SDK Version to 33 (Android 13).

You can change the `minSdkVersion` to 21 and the `compileSdkVersion` and `targetSdkVersion` to 33, inside the file `build.gradle`, located inside "android/app/" folder.

---

```gradle
// android/app/build.gradle
android {
    compileSdkVersion 33

    defaultConfig {
        minSdkVersion 21
        targetSdkVersion 33
        …
    }
    …
}
```

Also, to turn your app fully compatible with Android 13 (SDK 33), you need to add the attribute `android:exported="true"` to any `<activity>`, `<activity-alias>`, `<service>`, or `<receiver>` components that have `<intent-filter>` declared inside in the app’s AndroidManifest.xml file, and that's turns required for every other flutter packages that you're using.

```xml
<!-- android/app/src/main/AndroidManifest.xml -->
<manifest xmlns:android="http://schemas.android.com/apk/res/android"
    package="com.example.myapp">
   <application>
        ...
        <activity
            android:name=".MainActivity"
            ...
            android:exported="true">
                ...
        </activity>
        ...
    </application>
</manifest>
```
