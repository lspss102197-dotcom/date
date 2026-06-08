<<<<<<< Updated upstream
=======
import 'dart:async';

import 'package:flutter/foundation.dart';
>>>>>>> Stashed changes
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../core/config/app_config.dart';
import '../features/auth/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/permissions/location_permission_prompt_host.dart';
import '../features/trips/current_location_provider.dart';
import '../features/trips/trip_repository.dart';

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
  static const double _overviewZoom = 20;
  static const String _defaultTransportType = 'mrt';

  GoogleMapController? _mapController;
<<<<<<< Updated upstream
=======
  late final Future<void> _mapInitialization = _initializeGoogleMapsAndroid();
  Timer? _gpsTimer;
  StreamSubscription<Position>? _gpsSubscription;
  TripStartResult? _activeTrip;
  final List<LatLng> _tripRoutePoints = [];
  bool _isTripStarted = false;
  bool _isStartingTrip = false;
  bool _isEndingTrip = false;
>>>>>>> Stashed changes

  @override
  Widget build(BuildContext context) {
    final positionState = ref.watch(currentPositionProvider);
    final locationAccessState = ref.watch(locationAccessStatusProvider);
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
        CameraUpdate.newCameraPosition(
          CameraPosition(
            target: LatLng(position.latitude, position.longitude),
            zoom: _overviewZoom,
          ),
        ),
      );
    });

    return Scaffold(
      appBar: const _MapAppBar(),
<<<<<<< Updated upstream
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
=======
      body: FutureBuilder<void>(
        future: _mapInitialization,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }

          return Stack(
            children: [
              GoogleMap(
                initialCameraPosition: const CameraPosition(
                  target: _taipeiMainStation,
                  zoom: _overviewZoom,
                ),
                markers: {
                  if (currentLatLng != null)
                    Marker(
                      markerId: const MarkerId('current_location'),
                      position: currentLatLng,
                    ),
                },
                polylines: {
                  if (_tripRoutePoints.length >= 2)
                    Polyline(
                      polylineId: const PolylineId('active_trip_route'),
                      points: _tripRoutePoints,
                      color: const Color(0xFF1A73E8),
                      width: 6,
                    ),
                },
                myLocationButtonEnabled: true,
                myLocationEnabled: currentPosition != null,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                onMapCreated: (controller) {
                  _mapController = controller;

                  if (currentLatLng != null) {
                    controller.animateCamera(
                      CameraUpdate.newCameraPosition(
                        CameraPosition(
                          target: currentLatLng,
                          zoom: _overviewZoom,
                        ),
                      ),
                    );
                  }
                },
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _LocationAccessBadge(statusState: locationAccessState),
              ),
              Positioned(
                top: 12,
                right: 12,
                child: _CoordinateBadge(positionState: positionState),
              ),
              _OverviewSheet(),
              Positioned(
                left: 24,
                bottom: 126,
                child: SafeArea(
                  minimum: const EdgeInsets.only(left: 4, bottom: 4),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      _HomeCircleButton(
                        icon: Icons.history,
                        tooltip: '旅程紀錄',
                        onPressed: () {},
                      ),
                      const SizedBox(height: 14),
                      _HomeCircleButton(
                        icon: Icons.more_horiz,
                        tooltip: '更多',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 126,
                child: SafeArea(
                  minimum: const EdgeInsets.only(right: 4, bottom: 4),
                  child: _TripStartButton(
                    isStarted: _isTripStarted,
                    isBusy: _isStartingTrip || _isEndingTrip,
                    onPressed: _isTripStarted ? _endTrip : _toggleTripStarted,
                  ),
                ),
              ),
            ],
          );
        },
>>>>>>> Stashed changes
      ),
    );
  }

  @override
  void dispose() {
    _gpsTimer?.cancel();
    _gpsSubscription?.cancel();
    _mapController?.dispose();
    super.dispose();
  }

  Future<void> _toggleTripStarted() async {
    if (_isStartingTrip) {
      return;
    }

    setState(() {
      _isStartingTrip = true;
    });

    try {
      final trip = await ref.read(tripRepositoryProvider).startTrip();

      if (!mounted) {
        return;
      }

      setState(() {
        _activeTrip = trip;
        _tripRoutePoints.clear();
        _isTripStarted = true;
      });
      await _startTripTracking(trip);
    } on TripException catch (error) {
      if (!mounted) {
        return;
      }

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(error.message)));
    } finally {
      if (mounted) {
        setState(() {
          _isStartingTrip = false;
        });
      }
    }
  }

  Future<void> _startTripTracking(TripStartResult trip) async {
    final config = ref.read(appConfigProvider);
    final locationService = ref.read(currentLocationServiceProvider);

    _gpsTimer?.cancel();
    await _gpsSubscription?.cancel();

    try {
      final currentPosition = await locationService.getCurrentPosition();
      await _uploadTripPosition(trip.tripId, currentPosition);
    } on Object {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('旅程已開始，但目前無法取得 GPS 點')));
      }
    }

    _gpsTimer = Timer.periodic(Duration(seconds: config.gpsIntervalSeconds), (
      _,
    ) async {
      try {
        final position = await locationService.getCurrentPosition();
        await _uploadTripPosition(trip.tripId, position);
      } on Object {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('GPS 點上傳失敗，稍後會繼續嘗試')));
        }
      }
    });

    _gpsSubscription = locationService
        .watchPosition(distanceFilter: config.gpsDistanceMeters)
        .listen((position) async {
          try {
            await _uploadTripPosition(trip.tripId, position);
          } on Object {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('GPS 點上傳失敗，稍後會繼續嘗試')),
              );
            }
          }
        });
  }

  Future<void> _endTrip() async {
    if (_isEndingTrip) {
      return;
    }

    final trip = _activeTrip;
    if (trip == null) {
      _stopTripTracking();
      return;
    }

    setState(() {
      _isEndingTrip = true;
    });

    try {
      final result = await ref
          .read(tripRepositoryProvider)
          .endTrip(
            tripId: trip.tripId,
            endedAt: DateTime.now().toUtc(),
            transportType: _defaultTransportType,
          );
      _stopTripTracking();
      if (mounted) {
        setState(() {
          _isEndingTrip = false;
        });
        await showDialog<void>(
          context: context,
          builder: (context) => _TripResultDialog(result: result),
        );
      }
    } on TripException catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(error.message)));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isEndingTrip = false;
        });
      }
    }
  }

  void _stopTripTracking() {
    _gpsTimer?.cancel();
    _gpsTimer = null;
    _gpsSubscription?.cancel();
    _gpsSubscription = null;

    if (!mounted) {
      return;
    }

    setState(() {
      _activeTrip = null;
      _tripRoutePoints.clear();
      _isTripStarted = false;
    });
  }

  Future<void> _uploadTripPosition(int tripId, Position position) {
    _addTripRoutePoint(position);
    return ref
        .read(tripRepositoryProvider)
        .uploadGpsPoints(tripId: tripId, points: [_gpsPointFrom(position)]);
  }

  void _addTripRoutePoint(Position position) {
    if (!mounted) {
      return;
    }

    final point = LatLng(position.latitude, position.longitude);
    final lastPoint = _tripRoutePoints.isEmpty ? null : _tripRoutePoints.last;
    if (lastPoint == point) {
      return;
    }

    setState(() {
      _tripRoutePoints.add(point);
    });
  }

  GpsPointInput _gpsPointFrom(Position position) {
    return GpsPointInput(
      latitude: position.latitude,
      longitude: position.longitude,
      speed: position.speed < 0 ? null : position.speed,
      recordedAt: position.timestamp,
    );
  }
}

class _TripResultDialog extends StatelessWidget {
  const _TripResultDialog({required this.result});

  final TripResult result;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('本次旅程結果'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _TripResultRow(
            label: '減少碳排',
            value: '${result.carbonSaved.toStringAsFixed(3)} kg CO2',
          ),
          _TripResultRow(
            label: '旅程時間',
            value: _formatDuration(result.durationSeconds),
          ),
          _TripResultRow(
            label: '旅程距離',
            value: '${result.distanceKm.toStringAsFixed(3)} km',
          ),
          _TripResultRow(
            label: '交通工具',
            value: _formatTransportType(result.transportType),
          ),
          _TripResultRow(
            label: '本次碳排',
            value: '${result.carbonEmission.toStringAsFixed(3)} kg CO2',
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('完成'),
        ),
      ],
    );
  }

  String _formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds.remainder(60);
    if (minutes == 0) {
      return '$remainingSeconds 秒';
    }
    return '$minutes 分 $remainingSeconds 秒';
  }

  String _formatTransportType(String? transportType) {
    return switch (transportType) {
      'mrt' => '捷運',
      'bus' => '公車',
      'walk' => '步行',
      'bike' => '自行車',
      'motorcycle' => '機車',
      null || '' => '未指定',
      _ => transportType,
    };
  }
}

class _TripResultRow extends StatelessWidget {
  const _TripResultRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFF5F6F6B),
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(width: 24),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(
                color: Color(0xFF10201D),
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HomeCircleButton extends StatelessWidget {
  const _HomeCircleButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: const Color(0xEEF7FAF9),
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: const Color(0x33000000),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox.square(
            dimension: 72,
            child: Icon(icon, color: const Color(0xFF24312F), size: 34),
          ),
        ),
      ),
    );
  }
}

class _OverviewSheet extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.11,
      minChildSize: 0.08,
      maxChildSize: 0.86,
      snap: true,
      snapSizes: const [0.11, 0.86],
      builder: (context, scrollController) {
        return DecoratedBox(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            boxShadow: [
              BoxShadow(
                blurRadius: 18,
                color: Color(0x26000000),
                offset: Offset(0, -6),
              ),
            ],
          ),
          child: ListView(
            controller: scrollController,
            padding: EdgeInsets.zero,
            children: const [
              SizedBox(height: 14),
              Center(child: _OverviewSheetHandle()),
              SizedBox(height: 48),
            ],
          ),
        );
      },
    );
  }
}

class _OverviewSheetHandle extends StatelessWidget {
  const _OverviewSheetHandle();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE0E0E0),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const SizedBox(width: 72, height: 7),
    );
  }
}

class _LocationAccessBadge extends StatelessWidget {
  const _LocationAccessBadge({required this.statusState});

  final AsyncValue<LocationAccessStatus> statusState;

  @override
  Widget build(BuildContext context) {
    final config = statusState.when(
      data: _LocationAccessBadgeConfig.forStatus,
      error: (error, stackTrace) => const _LocationAccessBadgeConfig(
        label: '權限狀態異常',
        icon: Icons.error_outline,
        foreground: Color(0xFF842029),
        background: Color(0xFFFFF1F0),
      ),
      loading: () => const _LocationAccessBadgeConfig(
        label: '檢查權限中',
        icon: Icons.location_searching,
        foreground: Color(0xFF43515A),
        background: Color(0xFFF3F7F6),
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: config.background,
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(config.icon, color: config.foreground, size: 22),
            const SizedBox(width: 8),
            Text(
              config.label,
              style: TextStyle(
                color: config.foreground,
                fontSize: 16,
                fontWeight: FontWeight.w800,
                height: 1.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LocationAccessBadgeConfig {
  const _LocationAccessBadgeConfig({
    required this.label,
    required this.icon,
    required this.foreground,
    required this.background,
  });

  final String label;
  final IconData icon;
  final Color foreground;
  final Color background;

  factory _LocationAccessBadgeConfig.forStatus(LocationAccessStatus status) {
    return switch (status) {
      LocationAccessStatus.ready => const _LocationAccessBadgeConfig(
        label: '權限已開啟',
        icon: Icons.check_circle_outline,
        foreground: Color(0xFF0F6B5C),
        background: Color(0xFFE8F7F1),
      ),
      LocationAccessStatus.serviceDisabled => const _LocationAccessBadgeConfig(
        label: '定位服務未開啟',
        icon: Icons.location_off_outlined,
        foreground: Color(0xFF875515),
        background: Color(0xFFFFF4DE),
      ),
      LocationAccessStatus.denied => const _LocationAccessBadgeConfig(
        label: '等待定位權限',
        icon: Icons.location_disabled_outlined,
        foreground: Color(0xFF875515),
        background: Color(0xFFFFF4DE),
      ),
      LocationAccessStatus.deniedForever => const _LocationAccessBadgeConfig(
        label: '定位權限已關閉',
        icon: Icons.error_outline,
        foreground: Color(0xFF842029),
        background: Color(0xFFFFF1F0),
      ),
    };
  }
}

class _TripStartButton extends StatelessWidget {
  const _TripStartButton({
    required this.isStarted,
    required this.isBusy,
    required this.onPressed,
  });

  final bool isStarted;
  final bool isBusy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final backgroundColor = isStarted
        ? const Color(0xFF0F5F53)
        : const Color(0xFF007967);

    return Semantics(
      button: true,
      toggled: isStarted,
      label: isStarted ? '結束旅程' : '開始旅程',
      child: Tooltip(
        message: isStarted ? '結束旅程' : '開始旅程',
        child: Material(
          color: backgroundColor,
          shape: const CircleBorder(),
          elevation: 8,
          shadowColor: const Color(0x66000000),
          child: InkWell(
            key: const ValueKey('trip-action-button'),
            customBorder: const CircleBorder(),
            onTap: isBusy ? null : onPressed,
            child: SizedBox.square(
              dimension: 80,
              child: Center(
                child: Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                      width: 2,
                    ),
                  ),
                  child: isBusy
                      ? const Padding(
                          padding: EdgeInsets.all(12),
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 3,
                          ),
                        )
                      : Icon(
                          isStarted
                              ? Icons.stop_rounded
                              : Icons.directions_walk,
                          color: Colors.white,
                          size: 30,
                        ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
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
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Text(
          text,
          style: const TextStyle(
            color: Color(0xFF263A37),
            fontSize: 16,
            fontWeight: FontWeight.w700,
            fontFeatures: [FontFeature.tabularFigures()],
            height: 1.2,
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
