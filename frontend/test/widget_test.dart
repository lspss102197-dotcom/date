// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import 'package:frontend/app/app.dart';
import 'package:frontend/features/trips/current_location_provider.dart';

void main() {
  testWidgets('Shows login first and opens map after auth', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPositionProvider.overrideWith(
            (ref) => Stream.value(_fakePosition()),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    expect(find.text('登入'), findsOneWidget);
    expect(find.text('電子郵件'), findsOneWidget);
    expect(find.text('密碼'), findsOneWidget);
    expect(find.text('Google Map'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, '電子郵件'),
      'demo@example.com',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '密碼'), 'secret1');
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pump();
    await tester.pump();

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });

  testWidgets('Opens map after registration', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentPositionProvider.overrideWith(
            (ref) => Stream.value(_fakePosition()),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pump();

    await tester.tap(find.widgetWithText(TextButton, '建立帳戶'));
    await tester.pumpAndSettle();

    await tester.enterText(find.widgetWithText(TextFormField, '姓名'), '測試使用者');
    await tester.enterText(
      find.widgetWithText(TextFormField, '電子郵件'),
      'demo@example.com',
    );
    await tester.enterText(find.widgetWithText(TextFormField, '密碼'), 'secret1');
    await tester.enterText(
      find.widgetWithText(TextFormField, '確認密碼'),
      'secret1',
    );
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });
}

Position _fakePosition() {
  return Position(
    latitude: 5.552,
    longitude: 98.556,
    timestamp: DateTime(2026, 5, 29),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
