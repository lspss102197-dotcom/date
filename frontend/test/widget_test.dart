import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import 'package:frontend/app/app.dart';
import 'package:frontend/core/config/app_config.dart';
import 'package:frontend/core/storage/app_preferences.dart';
import 'package:frontend/features/auth/auth_repository.dart';
import 'package:frontend/features/trips/current_location_provider.dart';
import 'package:frontend/features/trips/trip_repository.dart';

void main() {
  testWidgets('shows login first and opens map after auth', (tester) async {
    await _pumpApp(tester);

    expect(find.text('EcoCommute'), findsOneWidget);
    expect(find.text('Google Map'), findsNothing);

    await tester.enterText(find.byType(TextFormField).at(0), 'demo-user');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.ensureVisible(find.byType(FilledButton).first);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.text('5.552, 98.556'), findsOneWidget);
  });

  testWidgets('does not request location permission before auth', (
    tester,
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
    tester,
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

    await tester.enterText(find.byType(TextFormField).at(0), 'demo-user');
    await tester.enterText(find.byType(TextFormField).at(1), 'secret123');
    await tester.ensureVisible(find.byType(FilledButton).first);
    await tester.tap(find.byType(FilledButton).first);
    await tester.pumpAndSettle();

    expect(find.text('Google Map'), findsOneWidget);
    expect(locationService.requestAccessCount, 1);
    expect(preferences.hasMarkedPromptSeen, isTrue);
  });

  testWidgets('shows map when an existing session is valid', (tester) async {
    await _pumpApp(
      tester,
      authRepository: FakeAuthRepository(restoredUser: _fakeUser()),
    );

    expect(find.text('Google Map'), findsOneWidget);
    expect(find.byType(TextFormField), findsNothing);
  });

  testWidgets('shows overview dashboard inside the draggable sheet', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(800, 1200);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await _pumpApp(
      tester,
      authRepository: FakeAuthRepository(restoredUser: _fakeUser()),
    );

    final sheet = tester.widget<DraggableScrollableSheet>(
      find.byType(DraggableScrollableSheet),
    );
    expect(sheet.snap, isTrue);
    expect(sheet.initialChildSize, 0.075);
    expect(sheet.minChildSize, 0.075);
    expect(sheet.maxChildSize, 0.91);
    expect(sheet.snapSizes, [0.075, 0.91]);
    expect(find.byType(CustomPaint), findsWidgets);
    expect(find.text('總覽'), findsNothing);
    expect(find.text('總減碳量'), findsNothing);

    await tester.dragFrom(const Offset(400, 1140), const Offset(0, -500));
    await tester.pumpAndSettle();

    expect(find.text('總覽'), findsOneWidget);
    expect(find.text('總減碳量'), findsOneWidget);
    expect(find.text('12.5'), findsOneWidget);
    expect(find.text('相當於種了 0 棵樹'), findsOneWidget);
    expect(find.text('低碳移動總距離'), findsOneWidget);
    expect(find.text('34'), findsOneWidget);
    expect(find.text('搭乘大眾運輸'), findsOneWidget);
    expect(find.text('2'), findsOneWidget);
  });

  testWidgets('starts and ends a trip from the map action button', (
    tester,
  ) async {
    final tripRepository = FakeTripRepository();

    await _pumpApp(
      tester,
      authRepository: FakeAuthRepository(restoredUser: _fakeUser()),
      tripRepository: tripRepository,
    );

    expect(find.byIcon(Icons.history), findsOneWidget);
    expect(find.byIcon(Icons.more_horiz), findsOneWidget);

    final map = tester.widget<GoogleMap>(find.byType(GoogleMap));
    expect(map.scrollGesturesEnabled, isFalse);
    expect(map.zoomGesturesEnabled, isFalse);
    expect(map.rotateGesturesEnabled, isFalse);
    expect(map.tiltGesturesEnabled, isFalse);

    final leftControls = tester.widget<Positioned>(
      find.ancestor(
        of: find.byIcon(Icons.history),
        matching: find.byType(Positioned),
      ),
    );
    expect(leftControls.left, 24);
    expect(leftControls.bottom, 86);

    final tripControl = tester.widget<Positioned>(
      find.ancestor(
        of: find.byKey(const ValueKey('trip-action-button')),
        matching: find.byType(Positioned),
      ),
    );
    expect(tripControl.right, 24);
    expect(tripControl.bottom, leftControls.bottom);

    await tester.tap(find.byKey(const ValueKey('trip-action-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tripRepository.startTripCount, 1);
    expect(tripRepository.uploadedPoints, isNotEmpty);

    await tester.tap(find.byKey(const ValueKey('trip-action-button')));
    await tester.pumpAndSettle();

    expect(tripRepository.endedTrips, hasLength(1));
    expect(find.byType(AlertDialog), findsOneWidget);
  });
}

Future<void> _pumpApp(
  WidgetTester tester, {
  FakeAuthRepository? authRepository,
  FakeAppPreferences? preferences,
  FakeLocationService? locationService,
  FakeTripRepository? tripRepository,
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
        appConfigProvider.overrideWithValue(
          const AppConfig(
            apiBaseUrl: 'http://127.0.0.1:8000',
            googleMapsAndroidApiKey: '',
            googleMapsIosApiKey: '',
            googleMapsWebApiKey: '',
            gpsIntervalSeconds: 10,
            gpsDistanceMeters: 20,
          ),
        ),
        tripRepositoryProvider.overrideWithValue(
          tripRepository ?? FakeTripRepository(),
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
    return _fakeUser(username: username);
  }

  @override
  Future<UserAccount> register({
    required String username,
    required String email,
    required String password,
  }) async {
    return _fakeUser(username: username, email: email);
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

  @override
  Future<Position> getCurrentPosition() async => _fakePosition();

  @override
  Stream<Position> watchPosition({required int distanceFilter}) {
    return Stream.value(_fakeSecondPosition());
  }
}

class FakeTripRepository implements TripRepository {
  int startTripCount = 0;
  int listTripsCount = 0;
  final List<FakeGpsPointsUpload> uploadedPoints = [];
  final List<FakeTripEnd> endedTrips = [];

  @override
  Future<TripStartResult> startTrip() async {
    startTripCount += 1;
    return TripStartResult(
      tripId: 42,
      startedAt: DateTime(2026, 6, 8, 12),
      message: 'started',
    );
  }

  @override
  Future<List<TripResult>> listTrips({int limit = 100, int offset = 0}) async {
    listTripsCount += 1;
    return [
      TripResult(
        id: 1,
        distanceKm: 10.2,
        durationSeconds: 900,
        transportType: 'mrt',
        carbonEmission: 0.2,
        carbonSaved: 4.5,
        startedAt: DateTime(2026, 6, 9, 8),
      ),
      TripResult(
        id: 2,
        distanceKm: 24,
        durationSeconds: 1200,
        transportType: 'bus',
        carbonEmission: 0.3,
        carbonSaved: 8,
        startedAt: DateTime(2026, 6, 8, 8),
      ),
    ];
  }

  @override
  Future<void> uploadGpsPoints({
    required int tripId,
    required List<GpsPointInput> points,
  }) async {
    uploadedPoints.add(FakeGpsPointsUpload(tripId: tripId, points: points));
  }

  @override
  Future<TripResult> endTrip({
    required int tripId,
    required DateTime endedAt,
    required String transportType,
  }) async {
    endedTrips.add(
      FakeTripEnd(
        tripId: tripId,
        endedAt: endedAt,
        transportType: transportType,
      ),
    );
    return const TripResult(
      id: 42,
      distanceKm: 3.21,
      durationSeconds: 725,
      transportType: 'mrt',
      carbonEmission: 0.016,
      carbonSaved: 0.456,
    );
  }
}

class FakeGpsPointsUpload {
  const FakeGpsPointsUpload({required this.tripId, required this.points});

  final int tripId;
  final List<GpsPointInput> points;
}

class FakeTripEnd {
  const FakeTripEnd({
    required this.tripId,
    required this.endedAt,
    required this.transportType,
  });

  final int tripId;
  final DateTime endedAt;
  final String transportType;
}

UserAccount _fakeUser({
  String username = 'demo-user',
  String email = 'demo@example.com',
}) {
  return UserAccount(
    id: 1,
    username: username,
    email: email,
    visualState: 'normal',
  );
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

Position _fakeSecondPosition() {
  return Position(
    latitude: 5.553,
    longitude: 98.557,
    timestamp: DateTime(2026, 5, 29, 0, 0, 10),
    accuracy: 0,
    altitude: 0,
    altitudeAccuracy: 0,
    heading: 0,
    headingAccuracy: 0,
    speed: 0,
    speedAccuracy: 0,
  );
}
