// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:evn_battery_trading/main.dart';
import 'package:evn_battery_trading/core/router/app_router.dart';

void main() {
  testWidgets('EVN app builds', (WidgetTester tester) async {
    final testRouter = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) => const Scaffold(
            body: Text('Home'),
          ),
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [appRouterProvider.overrideWithValue(testRouter)],
        child: EVNBatteryApp(),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('Home'), findsOneWidget);
  });
}
