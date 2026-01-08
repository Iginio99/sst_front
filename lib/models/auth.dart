class AuthTokens {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final String tokenType;

  AuthTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.tokenType,
  });

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: (json['expires_in'] as num).toInt(),
      tokenType: json['token_type']?.toString() ?? 'bearer',
    );
  }
}

class UserProfile {
  final int id;
  final String email;
  final String name;
  final List<String> roles;
  final List<String> permissions;

  UserProfile({
    required this.id,
    required this.email,
    required this.name,
    required this.roles,
    required this.permissions,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      email: json['email'] as String,
      name: json['name'] as String,
      roles: List<String>.from(json['roles'] ?? []),
      permissions: List<String>.from(json['permissions'] ?? []),
    );
  }
}

class AuthResponse {
  final UserProfile user;
  final AuthTokens tokens;

  AuthResponse({required this.user, required this.tokens});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: UserProfile.fromJson(json['user'] as Map<String, dynamic>),
      tokens: AuthTokens.fromJson(json['tokens'] as Map<String, dynamic>),
    );
  }
}

class UserSummary {
  final int id;
  final String name;
  final String email;
  final List<String> roles;

  UserSummary({
    required this.id,
    required this.name,
    required this.email,
    required this.roles,
  });

  factory UserSummary.fromJson(Map<String, dynamic> json) {
    return UserSummary(
      id: json['id'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      roles: List<String>.from(json['roles'] ?? []),
    );
  }
}

  class LoginChallenge {
    final String pendingToken;
    final int otpExpiresIn;
    final String maskedEmail;

    LoginChallenge({
      required this.pendingToken,
      required this.otpExpiresIn,
      required this.maskedEmail,
    });

    factory LoginChallenge.fromJson(Map<String, dynamic> json) {
      return LoginChallenge(
        pendingToken: json['pending_token'] as String,
        otpExpiresIn: (json['otp_expires_in'] as num).toInt(),
        maskedEmail: json['masked_email'] as String,
      );
    }
  }
