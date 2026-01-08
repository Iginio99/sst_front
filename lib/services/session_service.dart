import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth.dart';
import '../utils/api_config.dart';

class SessionManager {
  SessionManager._();

  static final SessionManager instance = SessionManager._();

  final _storage = const FlutterSecureStorage();
  final ValueNotifier<UserProfile?> userNotifier = ValueNotifier<UserProfile?>(null);

  String? _accessToken;
  String? _refreshToken;
  bool _refreshing = false;
  bool isReady = false;

  String? get accessToken => _accessToken;
  String? get refreshToken => _refreshToken;
  UserProfile? get currentUser => userNotifier.value;

  Future<void> restoreSession() async {
    _accessToken = await _storage.read(key: 'access_token');
    _refreshToken = await _storage.read(key: 'refresh_token');
    final cachedUser = await _storage.read(key: 'user_profile');
    if (cachedUser != null) {
      userNotifier.value = UserProfile.fromJson(jsonDecode(cachedUser) as Map<String, dynamic>);
    }
    // Intentar refresh silencioso para validar vigencia
    if (_refreshToken != null) {
      await refreshTokens();
    }
    isReady = true;
  }

  Future<void> saveSession(AuthResponse auth) async {
    _accessToken = auth.tokens.accessToken;
    _refreshToken = auth.tokens.refreshToken;
    userNotifier.value = auth.user;

    await _storage.write(key: 'access_token', value: _accessToken);
    await _storage.write(key: 'refresh_token', value: _refreshToken);
    await _storage.write(key: 'user_profile', value: jsonEncode({
      'id': auth.user.id,
      'email': auth.user.email,
      'name': auth.user.name,
      'roles': auth.user.roles,
      'permissions': auth.user.permissions,
    }));
  }

  Future<void> clearSession() async {
    _accessToken = null;
    _refreshToken = null;
    userNotifier.value = null;
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
    await _storage.delete(key: 'user_profile');
  }

  Future<bool> refreshTokens({Dio? dio}) async {
    if (_refreshToken == null || _refreshing) return false;
    _refreshing = true;
    try {
      final client = dio ??
          Dio(BaseOptions(
            baseUrl: apiBaseUrl,
            responseType: ResponseType.json,
            contentType: 'application/json',
          ));
      final response = await client.post('/auth/refresh', data: {'refresh_token': _refreshToken});
      final auth = AuthResponse.fromJson(response.data as Map<String, dynamic>);
      await saveSession(auth);
      return true;
    } catch (_) {
      await clearSession();
      return false;
    } finally {
      _refreshing = false;
    }
  }

  bool hasPermission(String code) {
    return userNotifier.value?.permissions.contains(code) ?? false;
  }
}
