import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';

import 'package:frontend/app/app.dart';
import 'package:frontend/features/trips/current_location_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android registration opens the map', (tester) async {
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
    await tester.pumpAndSettle();

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
