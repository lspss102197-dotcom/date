import 'package:flutter/widgets.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app/app.dart';
import 'core/config/app_config.dart';
import 'core/google_maps/google_maps_script_loader.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: '.env', isOptional: true);
  await loadGoogleMapsScript(
    apiKey: AppConfig.fromEnvironment().googleMapsWebApiKey,
  );

  runApp(const ProviderScope(child: MyApp()));
}
