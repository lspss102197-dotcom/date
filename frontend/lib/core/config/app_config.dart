import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final appConfigProvider = Provider<AppConfig>((ref) {
  return AppConfig.fromEnvironment();
});

class AppConfig {
  const AppConfig({
    required this.apiBaseUrl,
    required this.googleMapsAndroidApiKey,
    required this.googleMapsIosApiKey,
    required this.gpsIntervalSeconds,
    required this.gpsDistanceMeters,
  });

  final String apiBaseUrl;
  final String googleMapsAndroidApiKey;
  final String googleMapsIosApiKey;
  final int gpsIntervalSeconds;
  final int gpsDistanceMeters;

  factory AppConfig.fromEnvironment() {
    return AppConfig(
      apiBaseUrl: dotenv.get('API_BASE_URL', fallback: 'http://127.0.0.1:8000'),
      googleMapsAndroidApiKey: dotenv.get(
        'GOOGLE_MAPS_ANDROID_API_KEY',
        fallback: '',
      ),
      googleMapsIosApiKey: dotenv.get('GOOGLE_MAPS_IOS_API_KEY', fallback: ''),
      gpsIntervalSeconds: dotenv.getInt('GPS_INTERVAL_SECONDS', fallback: 10),
      gpsDistanceMeters: dotenv.getInt('GPS_DISTANCE_METERS', fallback: 20),
    );
  }
}
