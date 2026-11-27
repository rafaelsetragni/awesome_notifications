#!/bin/sh
# Kotlin coverage of the Android side (JaCoCo over the Robolectric / JVM unit
# tests) -> coverage/android/<package>.lcov
#
# Runs Gradle from each package's example app; needs JAVA_HOME (e.g. Android
# Studio's JBR) and the Flutter SDK. Pass package names to run only those.
set -e
cd "$(dirname "$0")/../.."
ROOT="$PWD"
packages="$*"
[ -n "$packages" ] || packages="$(cd packages && ls -d */ | tr -d /)"
for package in $packages; do
  [ -f "packages/$package/android/build.gradle.kts" ] || continue
  (cd "packages/$package/example" && flutter pub get >/dev/null)
  (cd "packages/$package/example/android" && ./gradlew ":$package:awnCoverageReport" --rerun-tasks -q)
  python3 tool/native_coverage/lcov_tools.py jacoco "$package" \
    "$ROOT/packages/$package/example/build/$package/reports/jacoco/awnCoverageReport/awnCoverageReport.xml"
done
