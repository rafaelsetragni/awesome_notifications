#!/bin/sh
# Runs the current package's tests with coverage and prints its line coverage.
# Invoked per package by the Melos `coverage` script (cwd = the package dir).
set -e
flutter test --coverage
awk -F: '
  /^LF:/ { lf += $2 }
  /^LH:/ { lh += $2 }
  END { if (lf > 0) printf "  -> %.1f%% line coverage (%d/%d)\n", lh / lf * 100, lh, lf }
' coverage/lcov.info
