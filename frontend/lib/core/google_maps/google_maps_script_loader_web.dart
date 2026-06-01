import 'dart:async';
import 'dart:js_interop';

import 'package:web/web.dart' as web;

Completer<void>? _loaderCompleter;

Future<void> loadGoogleMapsScript({required String apiKey}) {
  if (apiKey.isEmpty) {
    return Future<void>.value();
  }

  final existingScript = web.document.querySelector(
    'script[data-google-maps-api="true"]',
  );
  if (existingScript != null) {
    return Future<void>.value();
  }

  final activeLoader = _loaderCompleter;
  if (activeLoader != null) {
    return activeLoader.future;
  }

  final completer = Completer<void>();
  _loaderCompleter = completer;

  final script = web.HTMLScriptElement()
    ..async = true
    ..defer = true
    ..src = Uri.https('maps.googleapis.com', '/maps/api/js', {
      'key': apiKey,
    }).toString();

  script.setAttribute('data-google-maps-api', 'true');
  script.addEventListener(
    'load',
    ((web.Event event) {
      if (!completer.isCompleted) {
        completer.complete();
      }
    }).toJS,
  );
  script.addEventListener(
    'error',
    ((web.Event event) {
      if (!completer.isCompleted) {
        completer.completeError(
          StateError('Failed to load Google Maps JavaScript API.'),
        );
      }
    }).toJS,
  );

  web.document.head?.appendChild(script);

  return completer.future;
}
