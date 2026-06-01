import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/core/config/app_config.dart';

void main() {
  test('uses Android emulator host for localhost API URLs', () {
    expect(
      AppConfig.resolveApiBaseUrl(
        'http://127.0.0.1:8000',
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      'http://10.0.2.2:8000',
    );

    expect(
      AppConfig.resolveApiBaseUrl(
        'http://localhost:8000',
        platform: TargetPlatform.android,
        isWeb: false,
      ),
      'http://10.0.2.2:8000',
    );
  });

  test('keeps localhost API URLs unchanged outside Android native runtime', () {
    expect(
      AppConfig.resolveApiBaseUrl(
        'http://127.0.0.1:8000',
        platform: TargetPlatform.windows,
        isWeb: false,
      ),
      'http://127.0.0.1:8000',
    );

    expect(
      AppConfig.resolveApiBaseUrl(
        'http://127.0.0.1:8000',
        platform: TargetPlatform.android,
        isWeb: true,
      ),
      'http://127.0.0.1:8000',
    );
  });
}
