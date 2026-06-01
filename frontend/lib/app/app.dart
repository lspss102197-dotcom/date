import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../features/auth/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/permissions/location_permission_prompt_host.dart';
import '../features/trips/current_location_provider.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Carbon Trip',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF1A73E8)),
        scaffoldBackgroundColor: Colors.white,
        inputDecorationTheme: const InputDecorationTheme(
          floatingLabelBehavior: FloatingLabelBehavior.auto,
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(96, 40),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      builder: (context, child) {
        return ColoredBox(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child ?? const SizedBox.shrink(),
        );
      },
      home: const LocationPermissionPromptHost(child: AuthGate()),
    );
  }
}

class AuthGate extends ConsumerStatefulWidget {
  const AuthGate({super.key});

  @override
  ConsumerState<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends ConsumerState<AuthGate> {
  bool _isAuthenticated = false;
  bool _isRestoringSession = true;

  @override
  void initState() {
    super.initState();
    _restoreSession();
  }

  @override
  Widget build(BuildContext context) {
    if (_isRestoringSession) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (_isAuthenticated) {
      return const MapHomePage();
    }

    return LoginScreen(
      onAuthenticated: () {
        setState(() {
          _isAuthenticated = true;
        });
      },
    );
  }

  Future<void> _restoreSession() async {
    UserAccount? user;
    try {
      user = await ref.read(authRepositoryProvider).restoreSession();
    } on Object {
      user = null;
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isAuthenticated = user != null;
      _isRestoringSession = false;
    });
  }
}

class MapHomePage extends ConsumerStatefulWidget {
  const MapHomePage({super.key});

  @override
  ConsumerState<MapHomePage> createState() => _MapHomePageState();
}

class _MapHomePageState extends ConsumerState<MapHomePage> {
  static const LatLng _taipeiMainStation = LatLng(25.0478, 121.5170);

  GoogleMapController? _mapController;

  @override
  Widget build(BuildContext context) {
    final positionState = ref.watch(currentPositionProvider);
    final currentPosition = positionState.value;
    final currentLatLng = currentPosition == null
        ? null
        : LatLng(currentPosition.latitude, currentPosition.longitude);

    ref.listen(currentPositionProvider, (previous, next) {
      final position = next.value;
      if (position == null) {
        return;
      }

      _mapController?.animateCamera(
        CameraUpdate.newLatLng(LatLng(position.latitude, position.longitude)),
      );
    });

    return Scaffold(
      appBar: const _MapAppBar(),
      body: Stack(
        children: [
          GoogleMap(
            initialCameraPosition: const CameraPosition(
              target: _taipeiMainStation,
              zoom: 14,
            ),
            markers: {
              if (currentLatLng != null)
                Marker(
                  markerId: const MarkerId('current_location'),
                  position: currentLatLng,
                ),
            },
            myLocationButtonEnabled: true,
            myLocationEnabled: currentPosition != null,
            onMapCreated: (controller) {
              _mapController = controller;

              if (currentLatLng != null) {
                controller.animateCamera(CameraUpdate.newLatLng(currentLatLng));
              }
            },
          ),
          Positioned(
            top: 12,
            right: 12,
            child: _CoordinateBadge(positionState: positionState),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _mapController?.dispose();
    super.dispose();
  }
}

class _CoordinateBadge extends StatelessWidget {
  const _CoordinateBadge({required this.positionState});

  final AsyncValue<Position> positionState;

  @override
  Widget build(BuildContext context) {
    final text = positionState.when(
      data: (position) => _formatCoordinate(position),
      error: (error, stackTrace) => '定位未啟用',
      loading: () => '定位中...',
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withValues(alpha: 0.92),
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 12,
            color: Color(0x33000000),
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Text(
          text,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            fontFeatures: const [FontFeature.tabularFigures()],
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }

  String _formatCoordinate(Position position) {
    return '${position.latitude.toStringAsFixed(3)}, '
        '${position.longitude.toStringAsFixed(3)}';
  }
}

class _MapAppBar extends StatelessWidget implements PreferredSizeWidget {
  const _MapAppBar();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(title: const Text('Google Map'));
  }
}
