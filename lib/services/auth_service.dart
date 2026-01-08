import 'package:dio/dio.dart';

import '../models/auth.dart';
import 'api_client.dart';

class AuthService {
  AuthService({Dio? dio}) : _dio = dio ?? ApiClient().dio;

  final Dio _dio;

  Future<LoginResult> login(String email, String password) async {
    final response = await _dio.post('/auth/login', data: {
      'email': email,
      'password': password,
    });
    final data = response.data as Map<String, dynamic>;
    if (data.containsKey('user') && data.containsKey('tokens')) {
      return LoginResult(auth: AuthResponse.fromJson(data));
    }
    return LoginResult(challenge: LoginChallenge.fromJson(data));
  }

  Future<AuthResponse> verifyOtp(String pendingToken, String code) async {
    final response = await _dio.post('/auth/verify-otp', data: {
      'pending_token': pendingToken,
      'code': code,
    });
    return AuthResponse.fromJson(response.data as Map<String, dynamic>);
  }

  Future<UserProfile?> fetchProfile() async {
    try {
      final response = await _dio.get('/auth/me');
      return UserProfile.fromJson(response.data as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }
}

class LoginResult {
  final AuthResponse? auth;
  final LoginChallenge? challenge;

  LoginResult({this.auth, this.challenge});

  bool get hasAuth => auth != null;
  bool get requiresOtp => challenge != null && auth == null;
}
