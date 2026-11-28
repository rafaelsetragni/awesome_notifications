## 1.0.0-dev.1

* Depends on `awesome_notifications: ^1.0.0-dev.1`.
* The README images (banner and screenshots) load from a fixed commit, so they show on pub.dev.

## 1.0.0-dev

* Live activities package (in development).
* `LiveActivityLayout.versus`: a scoreboard layout (two sides with their images, the
  short text and the clock between them, the latest play below).
* `customLayout`: the app's own layout (an Android layout resource filled by view id; on
  iOS the app's own widget, reusing the package's public views).
* `androidLiveUpdate`: on Android 16+, a Live Update (default) or the package's own
  layout.
