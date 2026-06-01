import 'package:flutter/foundation.dart';
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
    required this.googleMapsWebApiKey,
    required this.gpsIntervalSeconds,
    required this.gpsDistanceMeters,
  });

  final String apiBaseUrl;
  final String googleMapsAndroidApiKey;
  final String googleMapsIosApiKey;
  final String googleMapsWebApiKey;
  final int gpsIntervalSeconds;
  final int gpsDistanceMeters;

  factory AppConfig.fromEnvironment() {
    final apiBaseUrl = dotenv.get(
      'API_BASE_URL',
      fallback: 'http://127.0.0.1:8000',
    );

    return AppConfig(
      apiBaseUrl: resolveApiBaseUrl(apiBaseUrl),
      googleMapsAndroidApiKey: dotenv.get(
        'GOOGLE_MAPS_ANDROID_API_KEY',
        fallback: '',
      ),
      googleMapsIosApiKey: dotenv.get('GOOGLE_MAPS_IOS_API_KEY', fallback: ''),
      googleMapsWebApiKey: dotenv.get('GOOGLE_MAPS_WEB_API_KEY', fallback: ''),
      gpsIntervalSeconds: dotenv.getInt('GPS_INTERVAL_SECONDS', fallback: 10),
      gpsDistanceMeters: dotenv.getInt('GPS_DISTANCE_METERS', fallback: 20),
    );
  }

  static String resolveApiBaseUrl(
    String rawBaseUrl, {
    TargetPlatform? platform,
    bool isWeb = kIsWeb,
  }) {
    final uri = Uri.tryParse(rawBaseUrl);
    if (uri == null || !uri.hasAuthority) {
      return rawBaseUrl;
    }

    final targetPlatform = platform ?? defaultTargetPlatform;
    final isAndroidLocalhost =
        !isWeb &&
        targetPlatform == TargetPlatform.android &&
        (uri.host == '127.0.0.1' || uri.host == 'localhost');

    if (!isAndroidLocalhost) {
      return rawBaseUrl;
    }

    return uri.replace(host: '10.0.2.2').toString();
  }
}
