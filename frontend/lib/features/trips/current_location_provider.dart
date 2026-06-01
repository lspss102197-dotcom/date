import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../core/config/app_config.dart';

final currentLocationServiceProvider = Provider<CurrentLocationService>((ref) {
  return const CurrentLocationService();
});

final currentPositionProvider = StreamProvider.autoDispose<Position>((
  ref,
) async* {
  final config = ref.watch(appConfigProvider);
  final service = ref.watch(currentLocationServiceProvider);

  await service.ensurePermission();

  final currentPosition = await service.getCurrentPosition();
  yield currentPosition;

  yield* service.watchPosition(distanceFilter: config.gpsDistanceMeters);
});

class CurrentLocationService {
  const CurrentLocationService();

  Future<void> ensurePermission() async {
    final status = await requestAccess();
    if (status == LocationAccessStatus.ready) {
      return;
    }

    if (status == LocationAccessStatus.serviceDisabled) {
      throw const LocationServiceDisabledException();
    }

    if (status == LocationAccessStatus.denied) {
      throw const PermissionDeniedException('Location permission denied.');
    }

    throw const PermissionDeniedException(
      'Location permission permanently denied.',
    );
  }

  Future<LocationAccessStatus> checkAccessStatus() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessStatus.serviceDisabled;
    }

    return _statusForPermission(await Geolocator.checkPermission());
  }

  Future<LocationAccessStatus> requestAccess() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return LocationAccessStatus.serviceDisabled;
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    return _statusForPermission(permission);
  }

  Future<bool> openLocationSettings() {
    return Geolocator.openLocationSettings();
  }

  Future<bool> openAppSettings() {
    return Geolocator.openAppSettings();
  }

  Future<Position> getCurrentPosition() {
    return Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
    );
  }

  Stream<Position> watchPosition({required int distanceFilter}) {
    return Geolocator.getPositionStream(
      locationSettings: LocationSettings(
        accuracy: LocationAccuracy.high,
        distanceFilter: distanceFilter,
      ),
    );
  }

  LocationAccessStatus _statusForPermission(LocationPermission permission) {
    return switch (permission) {
      LocationPermission.always ||
      LocationPermission.whileInUse => LocationAccessStatus.ready,
      LocationPermission.denied => LocationAccessStatus.denied,
      LocationPermission.deniedForever => LocationAccessStatus.deniedForever,
      LocationPermission.unableToDetermine => LocationAccessStatus.denied,
    };
  }
}

enum LocationAccessStatus { ready, serviceDisabled, denied, deniedForever }
