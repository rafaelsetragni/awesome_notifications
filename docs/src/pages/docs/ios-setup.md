---
title: Configuring iOS
# description: Quidem magni aut exercitationem maxime rerum eos.
---

To use Awesome Notifications and build your app correctly, you need to ensure to set some `build settings` options for your app targets. In your project view, click on _Runner -> Target Runner -> Build settings_...

![image](https://user-images.githubusercontent.com/40064496/194729267-6fbfc78c-8cba-422b-8af7-d7099f359adb.png)

... and set the following options:

In **Runner** Target:

- Build libraries for distribution => **NO**
- Only safe API extensions => **NO**
- iOS Deployment Target => **11** or greater

In **all** other Targets:

- Build libraries for distribution => **NO**
- Only safe API extensions => **YES**
