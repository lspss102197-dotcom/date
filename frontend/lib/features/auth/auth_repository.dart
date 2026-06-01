import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/network/api_client.dart';
import '../../core/storage/token_storage.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return DioAuthRepository(
    ref.watch(apiClientProvider),
    ref.watch(tokenStorageProvider),
  );
});

abstract class AuthRepository {
  Future<UserAccount?> restoreSession();

  Future<UserAccount> login({
    required String username,
    required String password,
  });

  Future<UserAccount> register({
    required String username,
    required String email,
    required String password,
  });
}

class DioAuthRepository implements AuthRepository {
  const DioAuthRepository(this._apiClient, this._tokenStorage);

  final ApiClient _apiClient;
  final TokenStorage _tokenStorage;

  @override
  Future<UserAccount?> restoreSession() async {
    final token = await _tokenStorage.readAccessToken();
    if (token == null || token.isEmpty) {
      return null;
    }

    return UserAccount.restored();
  }

  @override
  Future<UserAccount> login({
    required String username,
    required String password,
  }) async {
    try {
      final response = await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/login',
        data: {'username': username.trim(), 'password': password},
      );
      final token = response.data?['access_token'] as String?;

      if (token == null || token.isEmpty) {
        throw const AuthException('登入回應缺少 token');
      }

      await _tokenStorage.saveAccessToken(token);
      return me();
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  @override
  Future<UserAccount> register({
    required String username,
    required String email,
    required String password,
  }) async {
    try {
      await _apiClient.post<Map<String, dynamic>>(
        '/api/auth/register',
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
        },
      );

      return login(username: username, password: password);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }

  Future<UserAccount> me() async {
    try {
      final response = await _apiClient.get<Map<String, dynamic>>(
        '/api/auth/me',
      );
      final data = response.data;

      if (data == null) {
        throw const AuthException('無法讀取使用者資料');
      }

      return UserAccount.fromJson(data);
    } on DioException catch (error) {
      throw AuthException.fromDio(error);
    }
  }
}

class UserAccount {
  const UserAccount({
    required this.id,
    required this.username,
    required this.email,
    required this.visualState,
  });

  final int id;
  final String username;
  final String email;
  final String visualState;

  factory UserAccount.restored() {
    return const UserAccount(
      id: 0,
      username: '',
      email: '',
      visualState: 'normal',
    );
  }

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as int,
      username: json['username'] as String,
      email: json['email'] as String,
      visualState: json['visual_state'] as String? ?? 'normal',
    );
  }
}

class AuthException implements Exception {
  const AuthException(this.message);

  final String message;

  factory AuthException.fromDio(DioException error) {
    final responseData = error.response?.data;

    if (responseData is Map<String, dynamic>) {
      final detail = responseData['detail'];
      if (detail is String && detail.isNotEmpty) {
        return AuthException(detail);
      }
    }

    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return const AuthException('無法連線到伺服器，請稍後再試');
    }

    return const AuthException('帳號服務暫時無法使用');
  }

  @override
  String toString() => message;
}
