import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:integration_test/integration_test.dart';

import 'package:frontend/app/app.dart';
import 'package:frontend/core/storage/app_preferences.dart';
import 'package:frontend/features/auth/auth_repository.dart';
import 'package:frontend/features/trips/current_location_provider.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Android registration opens the map', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          authRepositoryProvider.overrideWithValue(FakeAuthRepository()),
          appPreferencesProvider.overrideWithValue(
            FakeAppPreferences(hasSeenPrompt: true),
          ),
          currentLocationServiceProvider.overrideWithValue(
            const FakeLocationService(status: LocationAccessStatus.ready),
          ),
          currentPositionProvider.overrideWith(
            (ref) => Stream.value(_fakePosition()),
          ),
        ],
        child: const MyApp(),
      ),
    );
    await tester.pumpAndSettle();

    final registerLink = find.widgetWithText(TextButton, '點我註冊');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    await tester.enterText(
      find.widgetWithText(TextFormField, '請輸入帳號'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '請輸入 Email'),
      'demo@example.com',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '設定密碼'),
      'secret123',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '再次輸入密碼'),
      'secret123',
    );
    final submitButton = find.widgetWithText(FilledButton, '註冊');
    await tester.ensureVisible(submitButton);
    await tester.tap(submitButton);
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
  });
}

class FakeAuthRepository implements AuthRepository {
  @override
  Future<UserAccount?> restoreSession() async => null;

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

  @override
  Future<bool> hasSeenLocationPermissionPrompt() async => hasSeenPrompt;

  @override
  Future<void> markLocationPermissionPromptSeen() async {
    hasSeenPrompt = true;
  }
}

class FakeLocationService extends CurrentLocationService {
  const FakeLocationService({required this.status});

  final LocationAccessStatus status;

  @override
  Future<LocationAccessStatus> checkAccessStatus() async => status;

  @override
  Future<LocationAccessStatus> requestAccess() async => status;

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
