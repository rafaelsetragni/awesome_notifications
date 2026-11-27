# Black-box compatibility suite (0.12 → 1.0)

The same tests run, unchanged, against the published `awesome_notifications`
0.12.1 and against the 1.0 monorepo packages. 0.12 is the reference: any
difference is a breaking change and must be fixed in 1.0, never in the
expectations.

| Folder | What it is |
|---|---|
| `suite/` | The tests and their expected results, written against a neutral `CompatApi`. It depends on neither library. |
| `app_v012/` | Host app with `awesome_notifications: 0.12.1` from pub.dev, plus its adapter in `integration_test/compat_test.dart`. |
| `app_v1/` | Host app with the monorepo packages (`path:`), plus its adapter. |

The tests only use what an app sees: return values, returned dates (wall
clock and the UTC flag), displayed events, and the scheduled list. Where 0.12
already behaved differently on Android and iOS, `p(android: …, ios: …)` keeps
each platform's own reference. 0.12 had no desktop code, so `app_v1` holds
macOS to the iOS reference (same Apple code) and Windows and Linux to the
Android one.

## Running

```bash
./run_compat.sh app_v012 <device-id>   # reference
./run_compat.sh app_v1   <device-id>   # must match
```

The script pins the device time zone to `America/Sao_Paulo`, so dates are
comparable across machines, and grants the notification permission:

- Android: `adb pm grant`.
- iOS simulator: `applesimutils` (`brew install applesimutils` from the
  `wix/brew` tap).
- macOS: only through the prompt; click Allow on the first run (it persists).
- Windows (`app_v1` only): the time zone can't be pinned per process; set it
  first with `tzutil /s "E. South America Standard Time"` (the suite checks
  the offset) and run the script from Git Bash with `windows` as the device.
- Linux (`app_v1` only): a notification server must be running in the session
  (any desktop has one; headless, e.g. in CI: `Xvfb`, `dbus-launch` and
  `dunst`). Linux has no notification permission to grant. Run with
  `TZ=America/Sao_Paulo` and `linux` as the device.

Both host apps bundle the same translation strings, used by the
`titleLocKey` / `bodyLocKey` tests:

- Android: `res/values*/strings.xml`.
- iOS / macOS: `Runner/*.lproj/Localizable.strings`.
- Windows / Linux: `awesome_notifications/strings/*.json` (Flutter assets).

## What Android shows (render_diff.sh)

The suite above only sees what Dart sees. `render_diff.sh` checks what Android
actually draws: both apps post the same raw notifications
(`suite/lib/render_cases.dart`, through `createNotificationFromJsonData`), and
the script diffs `dumpsys notification` (flags, priority, color, visibility,
group and its summary, ticker, timeout, chronometer, progress, the style's
extras, the channel). `render_normalize.py` drops what changes on every run
(addresses, times, uids, 0.12's random group summary ids).

```bash
./render_diff.sh <android-device-id>   # posts with both apps, then diffs
```

It ends with `RENDER MATCH` when 1.0 shows what 0.12 shows. Dumps are in
`build/render_<app>.txt`.

## Adding a case

1. Write the test in `suite/lib/awn_compat_suite.dart`.
2. Run it with `app_v012` on Android and iOS, and record what 0.12 really does.
3. Make `app_v1` pass.
