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
import 'package:frontend/core/storage/app_preferences.dart';
import 'package:frontend/features/auth/auth_repository.dart';
import 'package:frontend/features/trips/current_location_provider.dart';

void main() {
  testWidgets('Shows login first and opens map after auth', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appPreferencesProvider.overrideWithValue(
            FakeAppPreferences(hasSeenPrompt: true),
          ),
          currentLocationServiceProvider.overrideWithValue(
            FakeLocationService(status: LocationAccessStatus.ready),
          ),
          currentPositionProvider.overrideWith(
            (ref) => Stream.value(_fakePosition()),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登入'), findsOneWidget);
    expect(find.text('使用者名稱'), findsOneWidget);
    expect(find.text('密碼'), findsOneWidget);
    expect(find.text('Google Map'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, '使用者名稱'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '密碼'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });

  testWidgets('Opens map after registration', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appPreferencesProvider.overrideWithValue(
            FakeAppPreferences(hasSeenPrompt: true),
          ),
          currentLocationServiceProvider.overrideWithValue(
            FakeLocationService(status: LocationAccessStatus.ready),
          ),
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

    await tester.enterText(
      find.widgetWithText(TextFormField, '使用者名稱'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '電子郵件'),
      'demo@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '密碼'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '確認密碼'),
      'secret123',
    );
    await tester.tap(find.widgetWithText(FilledButton, '下一步'));
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });

  testWidgets('requests system location permission without custom prompt', (
    WidgetTester tester,
  ) async {
    final preferences = FakeAppPreferences();
    final locationService = FakeLocationService(
      status: LocationAccessStatus.denied,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appPreferencesProvider.overrideWithValue(preferences),
          currentLocationServiceProvider.overrideWithValue(locationService),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登入'), findsOneWidget);
    expect(find.text('允許定位權限'), findsNothing);
    expect(locationService.requestAccessCount, 1);
    expect(preferences.hasMarkedPromptSeen, isTrue);
  });

  testWidgets('does not prompt when location permission is ready', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appPreferencesProvider.overrideWithValue(FakeAppPreferences()),
          currentLocationServiceProvider.overrideWithValue(
            FakeLocationService(status: LocationAccessStatus.ready),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登入'), findsOneWidget);
    expect(find.text('定位已啟用'), findsNothing);
  });

  testWidgets('shows settings action when location service is disabled', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appPreferencesProvider.overrideWithValue(
            FakeAppPreferences(hasSeenPrompt: true),
          ),
          currentLocationServiceProvider.overrideWithValue(
            FakeLocationService(status: LocationAccessStatus.serviceDisabled),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登入'), findsOneWidget);
    expect(find.text('開啟定位服務'), findsOneWidget);
    expect(find.text('開啟設定'), findsOneWidget);
  });

  testWidgets('opens map when an existing token restores the session', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              restoredUser: const UserAccount(
                id: 1,
                username: 'demo-user',
                email: 'demo@example.com',
                visualState: 'normal',
              ),
            ),
          ),
          appPreferencesProvider.overrideWithValue(
            FakeAppPreferences(hasSeenPrompt: true),
          ),
          currentLocationServiceProvider.overrideWithValue(
            FakeLocationService(status: LocationAccessStatus.ready),
          ),
          currentPositionProvider.overrideWith(
            (ref) => Stream.value(_fakePosition()),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('登入'), findsNothing);
    expect(find.text('Google Map'), findsOneWidget);
  });
}

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({this.restoredUser});

  final UserAccount? restoredUser;

  @override
  Future<UserAccount?> restoreSession() async => restoredUser;

  @override
  Future<UserAccount> login({
    required String username,
    required String password,
  }) async {
    return _fakeUser(username);
  }

  @override
  Future<UserAccount> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _fakeUser(username, email: email);
  }

  UserAccount _fakeUser(String username, {String email = 'demo@example.com'}) {
    return UserAccount(
      id: 1,
      username: username,
      email: email,
      visualState: 'normal',
    );
  }
}

class FakeAppPreferences implements AppPreferences {
  FakeAppPreferences({this.hasSeenPrompt = false});

  bool hasSeenPrompt;
  bool hasMarkedPromptSeen = false;

  @override
  Future<bool> hasSeenLocationPermissionPrompt() async => hasSeenPrompt;

  @override
  Future<void> markLocationPermissionPromptSeen() async {
    hasSeenPrompt = true;
    hasMarkedPromptSeen = true;
  }
}

class FakeLocationService extends CurrentLocationService {
  FakeLocationService({
    required this.status,
    this.requestResult = LocationAccessStatus.ready,
  });

  final LocationAccessStatus status;
  final LocationAccessStatus requestResult;
  int requestAccessCount = 0;

  @override
  Future<LocationAccessStatus> checkAccessStatus() async => status;

  @override
  Future<LocationAccessStatus> requestAccess() async {
    requestAccessCount += 1;
    return requestResult;
  }

  @override
  Future<bool> openLocationSettings() async => true;

  @override
  Future<bool> openAppSettings() async => true;
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
