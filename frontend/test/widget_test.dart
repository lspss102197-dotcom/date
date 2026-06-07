import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';

import 'package:frontend/app/app.dart';
import 'package:frontend/core/storage/app_preferences.dart';
import 'package:frontend/features/auth/auth_repository.dart';
import 'package:frontend/features/trips/current_location_provider.dart';

void main() {
  testWidgets('shows login first and opens map after auth', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('EcoCommute'), findsOneWidget);
    expect(find.text('請輸入帳號'), findsOneWidget);
    expect(find.text('請輸入密碼'), findsOneWidget);
    expect(find.byType(SingleChildScrollView), findsNothing);
    expect(find.text('Google Map'), findsNothing);

    await tester.enterText(
      find.widgetWithText(TextFormField, '請輸入帳號'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '請輸入密碼'),
      'secret123',
    );
    final loginButton = find.widgetWithText(FilledButton, '登入');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });

  testWidgets('opens map after registration', (WidgetTester tester) async {
    await _pumpApp(tester);

    final registerLink = find.widgetWithText(TextButton, '點我註冊');
    await tester.ensureVisible(registerLink);
    await tester.tap(registerLink);
    await tester.pumpAndSettle();

    expect(find.byType(SingleChildScrollView), findsNothing);

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
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });

  testWidgets('does not request location permission before auth', (
    WidgetTester tester,
  ) async {
    final preferences = FakeAppPreferences();
    final locationService = FakeLocationService(
      status: LocationAccessStatus.denied,
    );

    await _pumpApp(
      tester,
      preferences: preferences,
      locationService: locationService,
    );

    expect(find.text('EcoCommute'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
    expect(locationService.requestAccessCount, 0);
    expect(preferences.hasMarkedPromptSeen, isFalse);
  });

  testWidgets('requests location permission after auth opens the map', (
    WidgetTester tester,
  ) async {
    final preferences = FakeAppPreferences();
    final locationService = FakeLocationService(
      status: LocationAccessStatus.denied,
    );

    await _pumpApp(
      tester,
      preferences: preferences,
      locationService: locationService,
    );

    await tester.enterText(
      find.widgetWithText(TextFormField, '請輸入帳號'),
      'demo-user',
    );
    await tester.enterText(
      find.widgetWithText(TextFormField, '請輸入密碼'),
      'secret123',
    );
    final loginButton = find.widgetWithText(FilledButton, '登入');
    await tester.ensureVisible(loginButton);
    await tester.tap(loginButton);
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(locationService.requestAccessCount, 1);
    expect(preferences.hasMarkedPromptSeen, isTrue);
  });

  testWidgets('does not prompt when location permission is ready', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, preferences: FakeAppPreferences());

    expect(find.text('EcoCommute'), findsOneWidget);
    expect(find.byType(AlertDialog), findsNothing);
  });

  testWidgets(
    'shows settings action on map when location service is disabled',
    (WidgetTester tester) async {
      await _pumpApp(
        tester,
        authRepository: FakeAuthRepository(
          restoredUser: const UserAccount(
            id: 1,
            username: 'demo-user',
            email: 'demo@example.com',
            visualState: 'normal',
          ),
        ),
        locationService: FakeLocationService(
          status: LocationAccessStatus.serviceDisabled,
        ),
      );

      expect(find.text('Google Map'), findsOneWidget);
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.byType(FilledButton), findsWidgets);
    },
  );

  testWidgets('opens map when an existing session is valid', (
    WidgetTester tester,
  ) async {
    await _pumpApp(
      tester,
      authRepository: FakeAuthRepository(
        restoredUser: const UserAccount(
          id: 1,
          username: 'demo-user',
          email: 'demo@example.com',
          visualState: 'normal',
        ),
      ),
    );

    expect(find.text('EcoCommute'), findsNothing);
    expect(find.text('Google Map'), findsOneWidget);
  });

  testWidgets('returns to login when session restore fails', (
    WidgetTester tester,
  ) async {
    await _pumpApp(tester, authRepository: FakeAuthRepository());

    expect(find.text('EcoCommute'), findsOneWidget);
    expect(find.text('Google Map'), findsNothing);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? authRepository,
  FakeAppPreferences? preferences,
  FakeLocationService? locationService,
}) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        authRepositoryProvider.overrideWithValue(
          authRepository ?? FakeAuthRepository(),
        ),
        appPreferencesProvider.overrideWithValue(
          preferences ?? FakeAppPreferences(hasSeenPrompt: true),
        ),
        currentLocationServiceProvider.overrideWithValue(
          locationService ??
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
