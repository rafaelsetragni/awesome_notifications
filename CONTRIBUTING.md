# Contributing to Awesome Notifications

Thanks for helping make Awesome Notifications better! We welcome pull requests for bug fixes, new features, docs, and examples. Please keep contributions aligned with the current architecture and prefer additive, backwards-compatible changes.

Key guidelines:
1. Packages are split by **feature**, never by platform: each package implements every platform it supports itself.
2. The core stays small; a new capability goes into an add-on package that decorates the core.
3. Add or adjust tests alongside code changes (see [Code coverage](#code-coverage)).
4. Follow [Effective Dart docs](https://dart.dev/guides/language/effective-dart/documentation) for public API comments.
5. Prefer small, focused PRs with clear rationale.

## Environment setup

The repository is a [Melos](https://melos.invertase.dev) monorepo on top of Dart pub workspaces. From the repository root:

```sh
dart pub get     # resolves the whole workspace at once
```

Each package has one example app:

```sh
cd packages/<package>/example
flutter run
```

iOS and macOS use Swift Package Manager; no `pod install` is needed.

## Branch strategy

- `master`: ***release-only***; tracks published, stable versions. Do not open PRs against `master`.
- `development`: active work and integration branch. **All pull requests must target `development`**. PRs aimed at `master` will be rejected.

## Tests

```sh
melos run analyze    # analyze every package
melos run test       # run every package's unit tests
```

Keep build and analysis clean before submitting.

## Code coverage

Every package must keep:
- its **Dart** code at **100%** line coverage (`flutter test`);
- each **native** platform at **90% or more**: Android (JaCoCo over the Robolectric/JVM tests), iOS / macOS (`swift test`) and the portable desktop engines of Windows / Linux (C++, clang coverage). The shared engines under `native/` count for the core.

CI uploads all of it to [Codecov](https://codecov.io/gh/rafaelsetragni/awesome_notifications) under one flag per package (see `codecov.yml`), so each package's badge combines its Dart and native code. To measure locally:

```sh
melos run coverage --no-select     # Dart: writes packages/<pkg>/coverage/lcov.info
tool/native_coverage/android.sh    # Android (needs JAVA_HOME)
tool/native_coverage/apple.sh      # iOS / macOS logic
tool/native_coverage/desktop.sh    # Windows / Linux engines (needs cmake + clang)
python3 tool/native_coverage/lcov_tools.py summary
```

A Dart line that can never run is marked with `// coverage:ignore-start` / `// coverage:ignore-end` and a comment saying why; anything else gets a test.

## Issues

File bugs and feature requests in this repository. Include steps to reproduce, expected vs actual behavior, and environment details (Flutter/Dart versions, Android API level, iOS version). PRs are appreciated for well-scoped fixes and improvements.
