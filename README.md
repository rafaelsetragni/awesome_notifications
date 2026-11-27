# Awesome Notifications — Monorepo

![Awesome Notifications](assets/readme/awesome-notifications-banner.jpg)

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](#)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](#)
[![Discord](https://img.shields.io/discord/888523488376279050.svg?style=for-the-badge&colorA=7289da&label=Chat%20on%20Discord)](https://discord.awesome-notifications.carda.me)

[![Open Source Love](https://badges.frapsoft.com/os/v1/open-source.svg?v=103)](#)
[![pub package](https://img.shields.io/pub/v/awesome_notifications.svg)](https://pub.dev/packages/awesome_notifications)
[![Full tests workflow](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml/badge.svg?branch=master)](https://github.com/rafaelsetragni/awesome_notifications/actions/workflows/dart.yml)
[![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg)](https://codecov.io/gh/rafaelsetragni/awesome_notifications)

Monorepo for the **Awesome Notifications** plugin family, managed with
[Melos](https://melos.invertase.dev) on top of Dart pub workspaces.

Starting with **v1.0.0**, Awesome Notifications is split into a small **core** plus
opt-in **capability add-ons** that *decorate* the core — you depend only on what you use.

## Packages

| Package | Role | Coverage |
|---|---|---|
| [`awesome_notifications`](packages/awesome_notifications) | **Core**: create / display / dismiss notifications, channels, images, action buttons, grouping, badge. | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_schedules`](packages/awesome_notifications_schedules) | **Decorator**: schedule notifications by time interval or calendar date, once or repeating. | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_schedules)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_localizations`](packages/awesome_notifications_localizations) | **Decorator**: show notifications in the user's language (per-language content + button labels). | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_localizations)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_fcm`](packages/awesome_notifications_fcm) | **Decorator**: Firebase Cloud Messaging — display pushes through the core, silent background data, FCM/APNs tokens, topics. | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_fcm)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_chat`](packages/awesome_notifications_chat) | **Decorator**: chat / communication notifications (Android conversations, iOS communication notifications). | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_chat)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_media`](packages/awesome_notifications_media) | **Decorator**: the system's media controls (Android media notification, Now Playing, MPRIS, SMTC, Media Session). | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_media)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_calls`](packages/awesome_notifications_calls) | **Decorator**: the system's call UI (Android CallStyle + Telecom, iOS CallKit + VoIP pushes) and call notifications on desktop and Web. | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_calls)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |
| [`awesome_notifications_live_activities`](packages/awesome_notifications_live_activities) | **Decorator**: live activities: iOS Live Activities (Lock Screen, Dynamic Island) with a widget it ships, Android 16 Live Updates, and progress notifications updated in place everywhere else. | [![codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications/branch/master/graph/badge.svg?flag=awesome_notifications_live_activities)](https://codecov.io/gh/rafaelsetragni/awesome_notifications/flags) |

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

Each package's coverage badge combines its **Dart** and **native** code: the Dart
layer (`flutter test`) is kept at **100%**, and every native platform at **90% or
more** — Android (JaCoCo over the Robolectric/JVM tests), iOS / macOS (`swift test`)
and the portable desktop engines of Windows / Linux (C++, clang coverage). The shared
engines under `native/` count for the core. CI uploads all of it to
[Codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications) under one flag
per package (see `codecov.yml`). To measure locally:

```sh
melos run coverage --no-select     # Dart
tool/native_coverage/android.sh    # Android (needs JAVA_HOME)
tool/native_coverage/apple.sh      # iOS / macOS logic
tool/native_coverage/desktop.sh    # Windows / Linux engines (needs cmake + clang)
python3 tool/native_coverage/lcov_tools.py summary
```

A Dart line that can never run is marked with `// coverage:ignore-start` /
`// coverage:ignore-end` and a comment saying why; anything else gets a test.
