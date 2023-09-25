import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NavigatorStateExtension tests', () {
    testWidgets('pushNamedIfNotCurrent', (WidgetTester tester) async {
      final GlobalKey<NavigatorState> navigatorKey =
          GlobalKey<NavigatorState>();

      await tester.pumpWidget(MaterialApp(
        navigatorKey: navigatorKey,
        initialRoute: '/',
        routes: {
          '/': (context) => const Text('Home'),
          '/second': (context) => const Text('Second'),
        },
      ));

      // Should push the route if it's not the current route
      navigatorKey.currentState!.pushNamedIfNotCurrent('/second');
      await tester.pumpAndSettle();
      expect(find.text('Second'), findsOneWidget);

      // Should not push the route if it's the current route
      navigatorKey.currentState!.pushNamedIfNotCurrent('/second');
      await tester.pump();
      expect(find.text('Second'), findsOneWidget);
    });

    testWidgets('getCurrentPage', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const Text('Home'),
          '/second': (context) => const Text('Second'),
        },
      ));

      await tester.tap(find.text('Home'));
      await tester.pumpAndSettle();

      expect(
          Navigator.of(tester.element(find.text('Home')))
              .getCurrentPage('/')
              .settings
              .name,
          '/');
    });

    testWidgets('isCurrent', (WidgetTester tester) async {
      await tester.pumpWidget(MaterialApp(
        initialRoute: '/',
        routes: {
          '/': (context) => const Text('Home'),
          '/second': (context) => const Text('Second'),
        },
      ));

      expect(
          Navigator.of(tester.element(find.text('Home'))).isCurrent('/'), true);
      expect(
          Navigator.of(tester.element(find.text('Home'))).isCurrent('/second'),
          false);
    });
  });
}
