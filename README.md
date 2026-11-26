# Awesome Notifications — Monorepo

![Awesome Notifications](assets/readme/awesome-notifications.jpg)

Monorepo for the **Awesome Notifications** plugin family, managed with
[Melos](https://melos.invertase.dev) on top of Dart pub workspaces.

Starting with **v1.0.0**, Awesome Notifications is split into a small **core** plus
opt-in **capability add-ons** that *decorate* the core — you depend only on what you use.

## Packages

| Package | Role |
|---|---|
| [`awesome_notifications`](packages/awesome_notifications) | **Core**: create / display / dismiss notifications, channels, images, action buttons, grouping, badge. |
| [`awesome_notifications_schedules`](packages/awesome_notifications_schedules) | **Decorator**: schedule notifications by time interval or calendar date, once or repeating. |
| [`awesome_notifications_localizations`](packages/awesome_notifications_localizations) | **Decorator**: show notifications in the user's language (per-language content + button labels). |
| [`awesome_notifications_fcm`](packages/awesome_notifications_fcm) | **Decorator**: Firebase Cloud Messaging — display pushes through the core, silent background data, FCM/APNs tokens, topics. |
| [`awesome_notifications_chat`](packages/awesome_notifications_chat) | **Decorator**: chat / communication notifications (Android conversations, iOS communication notifications). |
| [`awesome_notifications_media`](packages/awesome_notifications_media) | **Decorator**: the system's media controls (Android media notification, Now Playing, MPRIS, SMTC, Media Session). |
| [`awesome_notifications_calls`](packages/awesome_notifications_calls) | **Decorator**: the system's call UI (Android CallStyle + Telecom, iOS CallKit + VoIP pushes) and call notifications on desktop and Web. |
| [`awesome_notifications_live_activities`](packages/awesome_notifications_live_activities) | **Decorator**: live activities: iOS Live Activities (Lock Screen, Dynamic Island) with a widget it ships, Android 16 Live Updates, and progress notifications updated in place everywhere else. |

More capability add-ons (decorators of the core) are migrated in incrementally:
`_permissions` · `_foreground` · `_progress`.

## Working in the monorepo

```sh
dart pub get                     # resolve the whole workspace at once
melos run analyze                # analyze every package
melos run test                   # run unit tests
melos run coverage --no-select   # run tests with coverage + print each package's %
```

`melos run coverage` writes `packages/<pkg>/coverage/lcov.info` and prints each
package's line coverage. Add `--no-select` to run all packages without the
interactive package picker.
