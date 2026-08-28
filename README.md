# Awesome Notifications — Monorepo

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

More capability add-ons (decorators of the core) are migrated in incrementally:
`_permissions` · `_foreground` · `_calls` · `_live_activities` ·
`_media` · `_progress` · `_chat`.

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
