import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter_android/google_maps_flutter_android.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:google_maps_flutter_platform_interface/google_maps_flutter_platform_interface.dart';

import '../core/config/app_config.dart';
import '../features/auth/auth_repository.dart';
import '../features/auth/login_screen.dart';
import '../features/permissions/location_permission_prompt_host.dart';
import '../features/trips/current_location_provider.dart';
import '../features/trips/trip_repository.dart';

final tripOverviewProvider = FutureProvider.autoDispose<TripOverviewData>((
  ref,
) async {
  final trips = await ref.watch(tripRepositoryProvider).listTrips();
  return TripOverviewData.fromTrips(trips);
});

class TripOverviewData {
  const TripOverviewData({
    required this.totalCarbonSavedKg,
    required this.totalDistanceKm,
    required this.publicTransitCount,
    required this.completedTripCount,
    required this.consecutiveLowCarbonDays,
    required this.weeklyDistances,
    required this.transportShares,
  });

  final double totalCarbonSavedKg;
  final double totalDistanceKm;
  final int publicTransitCount;
  final int completedTripCount;
  final int consecutiveLowCarbonDays;
  final List<double> weeklyDistances;
  final List<TransportShare> transportShares;

  int get treeEquivalentCount => (totalCarbonSavedKg / 42).round();

  int get level => (completedTripCount ~/ 10) + 1;

  static TripOverviewData fromTrips(List<TripResult> trips) {
    final completedTrips = trips
        .where((trip) => trip.durationSeconds > 0 || trip.distanceKm > 0)
        .toList();
    final totalDistanceKm = completedTrips.fold<double>(
      0,
      (total, trip) => total + trip.distanceKm,
    );
    final totalCarbonSavedKg = completedTrips.fold<double>(
      0,
      (total, trip) => total + trip.carbonSaved,
    );
    final publicTransitCount = completedTrips
        .where((trip) => _isPublicTransit(trip.transportType))
        .length;

    return TripOverviewData(
      totalCarbonSavedKg: totalCarbonSavedKg,
      totalDistanceKm: totalDistanceKm,
      publicTransitCount: publicTransitCount,
      completedTripCount: completedTrips.length,
      consecutiveLowCarbonDays: _calculateStreakDays(completedTrips),
      weeklyDistances: _calculateWeeklyDistances(completedTrips),
      transportShares: _calculateTransportShares(completedTrips),
    );
  }

  static bool _isPublicTransit(String? transportType) {
    return transportType == 'mrt' ||
        transportType == 'bus' ||
        transportType == 'train';
  }

  static int _calculateStreakDays(List<TripResult> trips) {
    final dates =
        trips
            .map((trip) => trip.startedAt?.toLocal())
            .whereType<DateTime>()
            .map((date) => DateTime(date.year, date.month, date.day))
            .toSet()
            .toList()
          ..sort((a, b) => b.compareTo(a));

    if (dates.isEmpty) {
      return 0;
    }

    var streak = 1;
    var expected = dates.first.subtract(const Duration(days: 1));
    for (final date in dates.skip(1)) {
      if (date == expected) {
        streak += 1;
        expected = expected.subtract(const Duration(days: 1));
      } else if (date.isBefore(expected)) {
        break;
      }
    }

    return streak;
  }

  static List<double> _calculateWeeklyDistances(List<TripResult> trips) {
    final distances = List<double>.filled(6, 0);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final firstDay = today.subtract(const Duration(days: 5));

    for (final trip in trips) {
      final startedAt = trip.startedAt?.toLocal();
      if (startedAt == null) {
        continue;
      }
      final tripDay = DateTime(startedAt.year, startedAt.month, startedAt.day);
      final index = tripDay.difference(firstDay).inDays;
      if (index >= 0 && index < distances.length) {
        distances[index] += trip.distanceKm;
      }
    }

    return distances;
  }

  static List<TransportShare> _calculateTransportShares(
    List<TripResult> trips,
  ) {
    final counts = <String, int>{};
    for (final trip in trips) {
      final label = TransportShare.labelFor(trip.transportType);
      counts[label] = (counts[label] ?? 0) + 1;
    }

    final total = counts.values.fold<int>(0, (sum, count) => sum + count);
    if (total == 0) {
      return const [];
    }

    final colors = <String, Color>{
      '捷運': const Color(0xFF007967),
      '公車': const Color(0xFF0B63CE),
      '火車': const Color(0xFF5E5CE6),
      '步行': const Color(0xFF20C7B2),
      '自行車': const Color(0xFFFF9F1C),
      '機車': const Color(0xFF8A5400),
      '其他': const Color(0xFF667085),
    };

    final shares =
        counts.entries
            .map(
              (entry) => TransportShare(
                label: entry.key,
                percent: entry.value / total,
                color: colors[entry.key] ?? colors['其他']!,
              ),
            )
            .toList()
          ..sort((a, b) => b.percent.compareTo(a.percent));

    return shares.take(3).toList();
  }
}

class TransportShare {
  const TransportShare({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final double percent;
  final Color color;

  static String labelFor(String? transportType) {
    return switch (transportType) {
      'mrt' => '捷運',
      'bus' => '公車',
      'train' => '火車',
      'walk' => '步行',
      'bike' => '自行車',
      'motorcycle' => '機車',
      _ => '其他',
    };
  }
}

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
      home: const AuthGate(),
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
      return const LocationPermissionPromptHost(child: MapHomePage());
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
      user = await ref
          .read(authRepositoryProvider)
          .restoreSession()
          .timeout(const Duration(seconds: 3), onTimeout: () => null);
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
  late final Future<void> _mapInitialization = _initializeGoogleMapsAndroid();
  Timer? _gpsTimer;
  StreamSubscription<Position>? _gpsSubscription;
  TripStartResult? _activeTrip;
  final List<LatLng> _tripRoutePoints = [];
  bool _isTripStarted = false;
  bool _isStartingTrip = false;
  bool _isEndingTrip = false;

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
                scrollGesturesEnabled: false,
                zoomControlsEnabled: false,
                zoomGesturesEnabled: false,
                rotateGesturesEnabled: false,
                tiltGesturesEnabled: false,
                mapToolbarEnabled: false,
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
                right: 12,
                child: _CoordinateBadge(positionState: positionState),
              ),
              Positioned(
                top: 12,
                left: 12,
                child: _LocationAccessBadge(statusState: locationAccessState),
              ),
              Positioned(
                left: 24,
                bottom: 86,
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
                        tooltip: '?皜?',
                        onPressed: () {},
                      ),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 24,
                bottom: 86,
                child: SafeArea(
                  minimum: const EdgeInsets.only(right: 4, bottom: 4),
                  child: _TripStartButton(
                    isStarted: _isTripStarted,
                    isBusy: _isStartingTrip || _isEndingTrip,
                    onPressed: _isTripStarted ? _endTrip : _toggleTripStarted,
                  ),
                ),
              ),
              _OverviewSheet(),
            ],
          );
        },
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
      ref.invalidate(tripOverviewProvider);
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
      title: const Text('?蟡暑????荒??'),
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

class _OverviewSheet extends ConsumerStatefulWidget {
  @override
  ConsumerState<_OverviewSheet> createState() => _OverviewSheetState();
}

class _OverviewSheetState extends ConsumerState<_OverviewSheet> {
  static const double _collapsedSize = 0.075;
  static const double _expandedSize = 0.91;
  static const double _expandThreshold = 0.30;

  final DraggableScrollableController _controller =
      DraggableScrollableController();
  bool _isAutoExpanding = false;
  bool _isExpanded = false;
  bool _showOverviewContent = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final overviewState = ref.watch(tripOverviewProvider);

    return NotificationListener<DraggableScrollableNotification>(
      onNotification: (notification) {
        if (notification.extent <= _collapsedSize + 0.02 &&
            (_isExpanded || _showOverviewContent)) {
          setState(() {
            _isExpanded = false;
            _showOverviewContent = false;
          });
        }

        if (notification.extent > _expandThreshold &&
            notification.extent < _expandedSize &&
            !_isExpanded &&
            !_isAutoExpanding) {
          _isAutoExpanding = true;
          setState(() {
            _isExpanded = true;
            _showOverviewContent = true;
          });
          _controller
              .animateTo(
                _expandedSize,
                duration: const Duration(milliseconds: 260),
                curve: Curves.easeOutCubic,
              )
              .whenComplete(() => _isAutoExpanding = false);
        }

        return false;
      },
      child: DraggableScrollableSheet(
        controller: _controller,
        initialChildSize: _collapsedSize,
        minChildSize: _collapsedSize,
        maxChildSize: _expandedSize,
        snap: true,
        snapSizes: const [_collapsedSize, _expandedSize],
        builder: (context, scrollController) {
          return DecoratedBox(
            decoration: const BoxDecoration(
              color: Color(0xFFFBFCFF),
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
              boxShadow: [
                BoxShadow(
                  blurRadius: 18,
                  color: Color(0x26000000),
                  offset: Offset(0, -6),
                ),
              ],
            ),
            child: CustomPaint(
              painter: _showOverviewContent
                  ? const _OverviewDotPainter()
                  : null,
              child: ListView(
                controller: scrollController,
                padding: _showOverviewContent
                    ? const EdgeInsets.fromLTRB(24, 14, 24, 32)
                    : const EdgeInsets.only(top: 12),
                children: [
                  if (!_showOverviewContent)
                    const Center(child: _OverviewSheetHandle())
                  else ...[
                    const Center(child: _OverviewSheetHandle()),
                    const SizedBox(height: 28),
                    const _OverviewHeader(),
                    const SizedBox(height: 28),
                    _OverviewDashboard(overviewState: overviewState),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OverviewDashboard extends StatelessWidget {
  const _OverviewDashboard({required this.overviewState});

  final AsyncValue<TripOverviewData> overviewState;

  @override
  Widget build(BuildContext context) {
    return overviewState.when(
      loading: () => const _OverviewStatusCard(
        icon: Icons.sync,
        title: '載入總覽資料中',
        message: '正在讀取後端旅程資料',
      ),
      error: (error, stackTrace) => const _OverviewStatusCard(
        icon: Icons.error_outline,
        title: '總覽資料讀取失敗',
        message: '請稍後再試',
      ),
      data: (overview) => Column(
        children: [
          _CarbonSavedCard(overview: overview),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: _OverviewSmallCard(
                  icon: Icons.local_florist_outlined,
                  iconColor: const Color(0xFF0B6BFF),
                  title: '環保小菜鳥',
                  value: 'Lv.${overview.level}',
                  subtitle: '${overview.completedTripCount} 趟低碳旅程',
                ),
              ),
              const SizedBox(width: 18),
              Expanded(
                child: _OverviewSmallCard(
                  icon: Icons.local_fire_department_outlined,
                  iconColor: const Color(0xFFFF9F1C),
                  title: '連續低碳通勤',
                  value: '${overview.consecutiveLowCarbonDays} 天',
                  subtitle: '',
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _TravelStatsCard(overview: overview),
          const SizedBox(height: 18),
          const _StepsCard(),
        ],
      ),
    );
  }
}

class _OverviewStatusCard extends StatelessWidget {
  const _OverviewStatusCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      child: Column(
        children: [
          Icon(icon, color: const Color(0xFF007967), size: 32),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: const TextStyle(
              color: Color(0xFF344054),
              fontSize: 14,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _OverviewHeader extends StatelessWidget {
  const _OverviewHeader();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          '總覽',
          style: TextStyle(
            color: Color(0xFF101828),
            fontSize: 32,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
        SizedBox(height: 12),
        Text(
          '檢視您的環保成就與通勤數據',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _CarbonSavedCard extends StatelessWidget {
  const _CarbonSavedCard({required this.overview});

  final TripOverviewData overview;

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.eco_outlined, color: Color(0xFF007967), size: 28),
              SizedBox(width: 12),
              Text(
                '總減碳量',
                style: TextStyle(
                  color: Color(0xFF24312F),
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          SizedBox(height: 26),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                overview.totalCarbonSavedKg.toStringAsFixed(1),
                style: const TextStyle(
                  color: Color(0xFF007967),
                  fontSize: 56,
                  fontWeight: FontWeight.w900,
                  height: 0.9,
                ),
              ),
              const SizedBox(width: 8),
              const Padding(
                padding: EdgeInsets.only(bottom: 4),
                child: Text(
                  'kg',
                  style: TextStyle(
                    color: Color(0xFF007967),
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _TreeEquivalentBadge(count: overview.treeEquivalentCount),
        ],
      ),
    );
  }
}

class _TreeEquivalentBadge extends StatelessWidget {
  const _TreeEquivalentBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE7EEFD),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFD0D9F2)),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          '相當於種了 $count 棵樹',
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _OverviewSmallCard extends StatelessWidget {
  const _OverviewSmallCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.value,
    required this.subtitle,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String value;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      child: Column(
        children: [
          DecoratedBox(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: iconColor.withValues(alpha: 0.08),
              border: Border.all(color: iconColor, width: 2),
            ),
            child: SizedBox.square(
              dimension: 74,
              child: Icon(icon, color: iconColor, size: 34),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Color(0xFF101828),
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: iconColor,
              fontSize: 24,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF344054),
                fontSize: 13,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TravelStatsCard extends StatelessWidget {
  const _TravelStatsCard({required this.overview});

  final TripOverviewData overview;

  @override
  Widget build(BuildContext context) {
    return _OverviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _MetricTitle(icon: Icons.route_outlined, title: '低碳移動總距離'),
          const SizedBox(height: 22),
          _MetricValue(
            value: overview.totalDistanceKm.toStringAsFixed(0),
            unit: 'km',
            color: const Color(0xFF0B63CE),
          ),
          const SizedBox(height: 28),
          _WeeklyBarChart(values: overview.weeklyDistances),
          const SizedBox(height: 32),
          const _MetricTitle(
            icon: Icons.directions_transit_filled_outlined,
            title: '搭乘大眾運輸',
            color: Color(0xFF8A5400),
          ),
          const SizedBox(height: 22),
          _MetricValue(
            value: overview.publicTransitCount.toString(),
            unit: '次',
            color: const Color(0xFF8A5400),
          ),
          const SizedBox(height: 22),
          _TransportShareBar(shares: overview.transportShares),
        ],
      ),
    );
  }
}

class _StepsCard extends StatelessWidget {
  const _StepsCard();

  @override
  Widget build(BuildContext context) {
    return const _OverviewCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _MetricTitle(
                icon: Icons.directions_walk,
                title: '隞甇交',
                color: Color(0xFF20C7B2),
              ),
              Spacer(),
              _GoalBadge(),
            ],
          ),
          SizedBox(height: 22),
          _MetricValue(value: '0', unit: '步', color: Color(0xFF101828)),
          SizedBox(height: 22),
          _ProgressBar(progress: 0),
          SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '0%',
              style: TextStyle(
                color: Color(0xFF007967),
                fontSize: 14,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricTitle extends StatelessWidget {
  const _MetricTitle({
    required this.icon,
    required this.title,
    this.color = const Color(0xFF0B63CE),
  });

  final IconData icon;
  final String title;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 17,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _MetricValue extends StatelessWidget {
  const _MetricValue({
    required this.value,
    required this.unit,
    required this.color,
  });

  final String value;
  final String unit;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 42,
            fontWeight: FontWeight.w900,
            height: 0.95,
          ),
        ),
        const SizedBox(width: 8),
        Padding(
          padding: const EdgeInsets.only(bottom: 3),
          child: Text(
            unit,
            style: const TextStyle(
              color: Color(0xFF24312F),
              fontSize: 19,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }
}

class _WeeklyBarChart extends StatelessWidget {
  const _WeeklyBarChart({required this.values});

  final List<double> values;

  static const List<String> _labels = ['一', '二', '三', '四', '五', '六'];

  @override
  Widget build(BuildContext context) {
    final maxValue = values.fold<double>(
      0,
      (max, value) => value > max ? value : max,
    );
    final normalizedValues = values.isEmpty
        ? List<double>.filled(_labels.length, 0)
        : values
              .map((value) => maxValue == 0 ? 0.08 : value / maxValue)
              .toList();

    return SizedBox(
      height: 128,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (var index = 0; index < _labels.length; index++) ...[
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  FractionallySizedBox(
                    widthFactor: 0.86,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        color: Color.lerp(
                          const Color(0xFF9FC0E9),
                          const Color(0xFF0B63CE),
                          index / (_labels.length - 1),
                        ),
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(3),
                        ),
                      ),
                      child: SizedBox(height: 94 * normalizedValues[index]),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _labels[index],
                    style: const TextStyle(
                      color: Color(0xFF344054),
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            if (index != _labels.length - 1) const SizedBox(width: 7),
          ],
        ],
      ),
    );
  }
}

class _TransportShareBar extends StatelessWidget {
  const _TransportShareBar({required this.shares});

  final List<TransportShare> shares;

  @override
  Widget build(BuildContext context) {
    final visibleShares = shares.isEmpty
        ? const [
            TransportShare(label: '無資料', percent: 1, color: Color(0xFFCBD5E1)),
          ]
        : shares;

    return Column(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.all(Radius.circular(999)),
          child: Row(
            children: [
              for (final share in visibleShares)
                Expanded(
                  flex: (share.percent * 100).round().clamp(1, 100),
                  child: ColoredBox(
                    color: share.color,
                    child: const SizedBox(height: 18),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        for (var index = 0; index < visibleShares.length; index++) ...[
          _TransportLegend(
            label: visibleShares[index].label,
            percent: '${(visibleShares[index].percent * 100).round()}%',
            color: visibleShares[index].color,
          ),
          if (index != visibleShares.length - 1) const SizedBox(height: 7),
        ],
      ],
    );
  }
}

class _TransportLegend extends StatelessWidget {
  const _TransportLegend({
    required this.label,
    required this.percent,
    required this.color,
  });

  final String label;
  final String percent;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        DecoratedBox(
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: const SizedBox.square(dimension: 9),
        ),
        const SizedBox(width: 8),
        Text(
          label,
          style: const TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          percent,
          style: const TextStyle(
            color: Color(0xFF101828),
            fontSize: 14,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}

class _GoalBadge extends StatelessWidget {
  const _GoalBadge();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFFE9EEF8),
        borderRadius: BorderRadius.circular(8),
      ),
      child: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Text(
          '???: 10,000',
          style: TextStyle(
            color: Color(0xFF344054),
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({required this.progress});

  final double progress;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: 14,
        child: Row(
          children: [
            Expanded(
              flex: (progress * 100).round(),
              child: const ColoredBox(color: Color(0xFF007967)),
            ),
            Expanded(
              flex: ((1 - progress) * 100).round(),
              child: const ColoredBox(color: Color(0xFFE5ECF7)),
            ),
          ],
        ),
      ),
    );
  }
}

class _OverviewCard extends StatelessWidget {
  const _OverviewCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: const [
          BoxShadow(
            blurRadius: 18,
            color: Color(0x12000000),
            offset: Offset(0, 8),
          ),
        ],
      ),
      child: Padding(padding: const EdgeInsets.all(26), child: child),
    );
  }
}

class _OverviewDotPainter extends CustomPainter {
  const _OverviewDotPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFD8E4FF)
      ..style = PaintingStyle.fill;

    for (double y = 18; y < size.height; y += 24) {
      for (double x = 12; x < size.width; x += 24) {
        canvas.drawCircle(Offset(x, y), 1.1, paint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
      label: isStarted ? '蝯???' : '????',
      child: Tooltip(
        message: isStarted ? '蝯???' : '????',
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

Future<void> _initializeGoogleMapsAndroid() async {
  if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
    return;
  }

  final mapsImplementation = GoogleMapsFlutterPlatform.instance;
  if (mapsImplementation is GoogleMapsFlutterAndroid) {
    mapsImplementation.useAndroidViewSurface = true;
    await mapsImplementation.initializeWithRenderer(AndroidMapRenderer.latest);
  }
}

class _CoordinateBadge extends StatelessWidget {
  const _CoordinateBadge({required this.positionState});

  final AsyncValue<Position> positionState;

  @override
  Widget build(BuildContext context) {
    final text = positionState.when(
      data: (position) => _formatCoordinate(position),
      error: (error, stackTrace) => '?堊垢??剜??',
      loading: () => '?堊垢???..',
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
