#!/bin/bash
# Runs the black-box compat suite with one host app on one device.
#   ./run_compat.sh app_v012 <device-id>   # reference: awesome_notifications 0.12
#   ./run_compat.sh app_v1   <device-id>   # the 1.0 monorepo
# Both must pass with the SAME suite (compat_tests/suite).
set -u
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
APP=${1:?app_v012 or app_v1}
DEVICE=${2:?device id (flutter devices)}
DIR=$(cd "$(dirname "$0")/$APP" && pwd)
PACKAGE=me.carda.compat.$(grep '^name:' "$DIR/pubspec.yaml" | awk '{print $2}')

# Every device runs in the same time zone (see deviceTimeZone in the suite).
TIME_ZONE=America/Sao_Paulo
export SIMCTL_CHILD_TZ=$TIME_ZONE

# Android: grant the notification permission as soon as the app is installed
# (the suite waits for it instead of prompting).
if adb -s "$DEVICE" get-state >/dev/null 2>&1; then
  adb -s "$DEVICE" shell service call alarm 3 s16 "$TIME_ZONE" >/dev/null 2>&1
  adb -s "$DEVICE" uninstall "$PACKAGE" >/dev/null 2>&1
  (for _ in $(seq 1 300); do
     adb -s "$DEVICE" shell pm grant "$PACKAGE" android.permission.POST_NOTIFICATIONS >/dev/null 2>&1 && break
     sleep 1
   done) &
fi

# iOS simulator: install the app first, grant the notification permission
# with applesimutils (it restarts SpringBoard, so never while the test runs),
# then let flutter test reinstall over it (the permission survives updates).
if xcrun simctl list devices booted 2>/dev/null | grep -q "$DEVICE"; then
  BUNDLE=$(grep -m1 'PRODUCT_BUNDLE_IDENTIFIER = ' "$DIR/ios/Runner.xcodeproj/project.pbxproj" \
    | sed 's/.*= //; s/;//')
  xcrun simctl uninstall "$DEVICE" "$BUNDLE" >/dev/null 2>&1
  (cd "$DIR" && flutter build ios --simulator --debug -t integration_test/compat_test.dart >/dev/null) || exit 1
  xcrun simctl install "$DEVICE" "$DIR/build/ios/iphonesimulator/Runner.app" || exit 1
  applesimutils --byId "$DEVICE" --bundle "$BUNDLE" --setPermissions notifications=YES || exit 1
  sleep 5
fi

# macOS: the process inherits TZ; the first run shows the permission prompt
# (click Allow once, it persists for the app).
if [ "$DEVICE" = "macos" ]; then
  export TZ=$TIME_ZONE
fi

cd "$DIR" && flutter test integration_test/compat_test.dart -d "$DEVICE" -r expanded
