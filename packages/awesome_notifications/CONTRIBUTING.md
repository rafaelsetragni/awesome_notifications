# Contributing to awesome_notifications

Thanks for helping make `awesome_notifications` better! We welcome pull requests for bug fixes, new features, docs, and examples. Please keep contributions aligned with the current architecture and prefer additive, backwards-compatible changes.

Key guidelines:
1. Keep platform-specific code inside the respective native folders (`android/`, `ios/`).
2. Add/adjust tests alongside code changes; ensure `flutter test` passes.
3. Follow [Effective Dart docs](https://dart.dev/guides/language/effective-dart/documentation) for public API comments.
4. Prefer small, focused PRs with clear rationale.

## Environment setup

```
flutter pub get
```

For running the example app:

```
cd example
flutter pub get
flutter run
```

On iOS, run `pod install` inside the `example/ios/` folder to sync native dependencies.

## Branch strategy

- `master`: ***release-only***; tracks published, stable versions. Do not open PRs against `master`.
- `development`: active work and integration branch. **All pull requests must target `development`**. PRs aimed at `master` will be rejected.

## Tests

- Run `flutter test` from the project root.
- Keep build and analysis clean; run `flutter analyze` before submitting.

## Issues

File bugs and feature requests in this repository. Include steps to reproduce, expected vs actual behavior, and environment details (Flutter/Dart versions, Android API level, iOS version). PRs are appreciated for well-scoped fixes and improvements.
