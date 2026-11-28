#!/bin/sh
# Swift coverage of the Apple engines (iOS / macOS logic built by the root
# Package.swift) -> coverage/apple/<package>.lcov
set -e
cd "$(dirname "$0")/../.."
# A failing test still exports what ran (the job fails at the end), so the
# coverage reaches Codecov whatever the outcome.
status=0
# The schedule tests read the device's time zone as America/Sao_Paulo (the
# runners are on UTC).
TZ=America/Sao_Paulo swift test --enable-code-coverage || status=$?
BIN="$(swift build --show-bin-path)"
PROFILE="$BIN/codecov/default.profdata"
# swift test merges the raw profiles only when every test passed.
[ -f "$PROFILE" ] || xcrun llvm-profdata merge -sparse "$BIN"/codecov/*.profraw -o "$PROFILE"
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
exit $status
