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
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const LocationServiceDisabledException();
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const PermissionDeniedException('Location permission denied.');
    }

    if (permission == LocationPermission.deniedForever) {
      throw const PermissionDeniedException(
        'Location permission permanently denied.',
      );
    }
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
}
