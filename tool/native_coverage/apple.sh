#!/bin/sh
# Swift coverage of the Apple engines (iOS / macOS logic built by the root
# Package.swift) -> coverage/apple/<package>.lcov
set -e
cd "$(dirname "$0")/../.."
swift test --enable-code-coverage
BIN="$(swift build --show-bin-path)"
PROFILE="$BIN/codecov/default.profdata"
set --
for bundle in "$BIN"/*.xctest; do
  name="$(basename "$bundle" .xctest)"
  if [ -f "$bundle/Contents/MacOS/$name" ]; then exe="$bundle/Contents/MacOS/$name"; else exe="$bundle"; fi
  if [ $# -eq 0 ]; then set -- "$exe"; else set -- "$@" -object "$exe"; fi
done
mkdir -p coverage
xcrun llvm-cov export -format=lcov -instr-profile "$PROFILE" "$@" \
  -ignore-filename-regex='(\.build|/Tests/)' > coverage/apple.raw.lcov
python3 tool/native_coverage/lcov_tools.py split apple coverage/apple.raw.lcov
rm coverage/apple.raw.lcov
