# Awesome Notifications — Monorepo

Monorepo for the **Awesome Notifications** plugin family, managed with
[Melos](https://melos.invertase.dev) on top of Dart pub workspaces.

Starting with **v1.0.0**, Awesome Notifications is split into a small **core** plus
opt-in **capability add-ons** that *decorate* the core — you depend only on what you use.

## Packages

| Package | Role |
|---|---|
| [`awesome_notifications`](packages/awesome_notifications) | **Core**: create / display / dismiss notifications, channels, images, action buttons, grouping, badge. |

Capability add-ons (decorators of the core) are migrated in incrementally:
`_fcm` (push) · `_permissions` · `_localization` · `_scheduler` · `_foreground` ·
`_calls` · `_live_activities` · `_media` · `_progress` · `_chat`.

## Working in the monorepo

```sh
dart pub get          # resolve the whole workspace at once
melos run analyze     # analyze every package
melos run test        # run unit tests
```
