import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import 'token_storage.dart';

final appPreferencesProvider = Provider<AppPreferences>((ref) {
  return SecureAppPreferences(ref.watch(secureStorageProvider));
});

abstract class AppPreferences {
  Future<bool> hasSeenLocationPermissionPrompt();

  Future<void> markLocationPermissionPromptSeen();
}

class SecureAppPreferences implements AppPreferences {
  const SecureAppPreferences(this._storage);

  static const _locationPermissionPromptSeenKey =
      'location_permission_prompt_seen';

  final FlutterSecureStorage _storage;

  @override
  Future<bool> hasSeenLocationPermissionPrompt() async {
    final value = await _storage.read(key: _locationPermissionPromptSeenKey);
    return value == 'true';
  }

  @override
  Future<void> markLocationPermissionPromptSeen() {
    return _storage.write(key: _locationPermissionPromptSeenKey, value: 'true');
  }
}
