import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('NavigatorStateExtension navigates only when not current',
      (tester) async {
    final navKey = GlobalKey<NavigatorState>();
    await tester.pumpWidget(MaterialApp(
      navigatorKey: navKey,
      routes: {
        '/': (_) => const SizedBox.shrink(),
        '/page': (_) => const SizedBox.shrink(),
      },
    ));

    final navigator = navKey.currentState!;
    expect(navigator.isCurrent('/'), isTrue);
    expect(navigator.isCurrent('/page'), isFalse);

    // Not current yet → pushes.
    navigator.pushNamedIfNotCurrent('/page');
    await tester.pumpAndSettle();
    expect(navigator.isCurrent('/page'), isTrue);

    // Already current → no-op (branch coverage of the guard).
    navigator.pushNamedIfNotCurrent('/page');
    await tester.pumpAndSettle();

    expect(navigator.getCurrentPage('/page'), isA<Route>());
  });
}
