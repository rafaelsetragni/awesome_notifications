#!/bin/bash
# Compares what Android SHOWS for the same notifications posted by 0.12 and
# 1.0 (suite/lib/render_cases.dart), as read from `dumpsys notification`.
#   ./render_diff.sh <android-device-id>            # both apps, then the diff
#   ./render_diff.sh <android-device-id> app_v1     # only one app (reuses the other's dump)
# Dumps go to compat_tests/build/render_<app>.txt.
set -u
export PATH="$HOME/Library/Android/sdk/platform-tools:$PATH"
DEVICE=${1:?android device id}
HERE=$(cd "$(dirname "$0")" && pwd)
mkdir -p "$HERE/build"
APPS=${2:-"app_v012 app_v1"}

for APP in $APPS; do
  LOG="$HERE/build/render_$APP.log"
  OUT="$HERE/build/render_$APP.txt"
  PACKAGE=me.carda.compat.$(grep '^name:' "$HERE/$APP/pubspec.yaml" | awk '{print $2}')
  "$HERE/run_compat.sh" "$APP" "$DEVICE" render_test.dart >"$LOG" 2>&1 &
  RUN=$!
  for _ in $(seq 1 600); do
    grep -q AWN_RENDER_READY "$LOG" && break
    kill -0 $RUN 2>/dev/null || break
    sleep 1
  done
  if ! grep -q AWN_RENDER_READY "$LOG"; then
    echo "$APP: the cases never got posted (see $LOG)"; wait $RUN; exit 1
  fi
  adb -s "$DEVICE" shell dumpsys notification --noredact >"$HERE/build/render_$APP.raw"
  python3 -I "$HERE/render_normalize.py" "$PACKAGE" <"$HERE/build/render_$APP.raw" >"$OUT"
  wait $RUN
  grep '^render ' "$LOG" | sed 's/^/  /'
  echo "$APP: $(grep -c '^## ' "$OUT") notifications -> $OUT"
done

diff -u "$HERE/build/render_app_v012.txt" "$HERE/build/render_app_v1.txt" \
  && echo "RENDER MATCH: 1.0 shows what 0.12 shows"
