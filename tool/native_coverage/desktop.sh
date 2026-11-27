#!/bin/sh
# C++ coverage of the portable desktop engines (Windows / Linux logic), built
# with clang's source-based coverage -> coverage/desktop/<package>.lcov
#
# Needs clang, cmake and llvm-profdata / llvm-cov (on macOS through xcrun; on
# Linux set LLVM_PROFDATA / LLVM_COV, e.g. llvm-profdata-18).
set -e
cd "$(dirname "$0")/../.."
ROOT="$PWD"
if command -v xcrun >/dev/null 2>&1; then
  PROFDATA="${LLVM_PROFDATA:-xcrun llvm-profdata}"; COV="${LLVM_COV:-xcrun llvm-cov}"
else
  PROFDATA="${LLVM_PROFDATA:-llvm-profdata}"; COV="${LLVM_COV:-llvm-cov}"
fi
mkdir -p coverage/desktop.raw
for tests in packages/*/desktop/*/tests; do
  name="$(basename "$(dirname "$tests")")"
  build="$ROOT/build/native_coverage/$name"
  CXX="${CXX:-clang++}" cmake -S "$tests" -B "$build" -DCMAKE_BUILD_TYPE=Debug \
    -DCMAKE_CXX_FLAGS="-fprofile-instr-generate -fcoverage-mapping" \
    -DCMAKE_EXE_LINKER_FLAGS="-fprofile-instr-generate"
  cmake --build "$build"
  exe="$(find "$build" -maxdepth 1 -type f -perm -u+x -name '*_tests' | head -1)"
  (cd "$build" && LLVM_PROFILE_FILE="$build/tests.profraw" "$exe")
  $PROFDATA merge -sparse "$build/tests.profraw" -o "$build/tests.profdata"
  $COV export -format=lcov -instr-profile "$build/tests.profdata" "$exe" \
    -ignore-filename-regex='(/tests/|/_deps/|^/usr/|googletest)' > "coverage/desktop.raw/$name.lcov"
done
# Each test binary also compiles the core: the hits of every run add up.
python3 tool/native_coverage/lcov_tools.py split desktop coverage/desktop.raw/*.lcov
rm -rf coverage/desktop.raw
