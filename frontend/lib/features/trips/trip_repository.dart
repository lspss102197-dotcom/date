import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';

final tripRepositoryProvider = Provider<TripRepository>((ref) {
  return DioTripRepository(ref.watch(apiClientProvider));
});

abstract class TripRepository {
  Future<TripStartResult> startTrip();

  Future<void> uploadGpsPoints({
    required int tripId,
    required List<GpsPointInput> points,
  });

  Future<TripResult> endTrip({
    required int tripId,
    required DateTime endedAt,
    required String transportType,
  });
}

class DioTripRepository implements TripRepository {
  const DioTripRepository(this._apiClient);

  final ApiClient _apiClient;

  @override
  Future<TripStartResult> startTrip() async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/trips/start',
        data: const <String, dynamic>{},
      );
      final data = response.data;

      if (data == null) {
        throw const TripException('無法開始旅程');
      }

      return TripStartResult.fromJson(data);
    } on DioException catch (error) {
      throw TripException.fromDio(error);
    }
  }

  @override
  Future<void> uploadGpsPoints({
    required int tripId,
    required List<GpsPointInput> points,
  }) async {
    if (points.isEmpty) {
      return;
    }

    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/trips/$tripId/points',
        data: {'points': points.map((point) => point.toJson()).toList()},
      );
    } on DioException catch (error) {
      throw TripException.fromDio(error);
    }
  }

  @override
  Future<TripResult> endTrip({
    required int tripId,
    required DateTime endedAt,
    required String transportType,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/trips/$tripId/end',
        data: {
          'ended_at': endedAt.toIso8601String(),
          'transport_type': transportType,
        },
      );
      final data = response.data;
      if (data == null) {
        throw const TripException('無法讀取旅程結果');
      }

      return TripResult.fromJson(data);
    } on DioException catch (error) {
      throw TripException.fromDio(error);
    }
  }
}

class GpsPointInput {
  const GpsPointInput({
    required this.latitude,
    required this.longitude,
    required this.recordedAt,
    this.speed,
  });

  final double latitude;
  final double longitude;
  final double? speed;
  final DateTime recordedAt;

  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'speed': speed,
      'recorded_at': recordedAt.toIso8601String(),
    };
  }
}

class TripStartResult {
  const TripStartResult({
    required this.tripId,
    required this.startedAt,
    required this.message,
  });

  final int tripId;
  final DateTime startedAt;
  final String message;

  factory TripStartResult.fromJson(Map<String, dynamic> json) {
    return TripStartResult(
      tripId: json['trip_id'] as int,
      startedAt: DateTime.parse(json['started_at'] as String),
      message: json['message'] as String? ?? '旅程已開始',
    );
  }
}

class TripResult {
  const TripResult({
    required this.id,
    required this.distanceKm,
    required this.durationSeconds,
    required this.transportType,
    required this.carbonEmission,
    required this.carbonSaved,
  });

  final int id;
  final double distanceKm;
  final int durationSeconds;
  final String? transportType;
  final double carbonEmission;
  final double carbonSaved;

  factory TripResult.fromJson(Map<String, dynamic> json) {
    return TripResult(
      id: json['id'] as int,
      distanceKm: _doubleFromJson(json['distance_km']),
      durationSeconds: json['duration_seconds'] as int? ?? 0,
      transportType: json['transport_type'] as String?,
      carbonEmission: _doubleFromJson(json['carbon_emission']),
      carbonSaved: _doubleFromJson(json['carbon_saved']),
    );
  }

  static double _doubleFromJson(Object? value) {
    if (value is int) {
      return value.toDouble();
    }
    if (value is double) {
      return value;
    }
    return 0;
  }
}

class TripException implements Exception {
  const TripException(this.message);

  final String message;

  factory TripException.fromDio(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      if (detail is String && detail.isNotEmpty) {
        return TripException(detail);
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const TripException('無法連線到伺服器，請稍後再試');
    }

    return const TripException('旅程開始失敗，請稍後再試');
  }

  @override
  String toString() => message;
}
