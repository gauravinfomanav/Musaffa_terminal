class AuthUser {
  final String id;
  final String email;
  final String name;
  final String status;
  final bool? registered;
  final String? createdAt;
  final String? lastLoginAt;
  final Map<String, dynamic>? features;

  const AuthUser({
    required this.id,
    required this.email,
    required this.name,
    required this.status,
    this.registered,
    this.createdAt,
    this.lastLoginAt,
    this.features,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic>? features;
    final rawFeatures = json['features'];
    if (rawFeatures is Map<String, dynamic>) {
      features = rawFeatures;
    } else if (rawFeatures is Map) {
      features = Map<String, dynamic>.from(rawFeatures);
    }

    return AuthUser(
      id: json['id']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      registered: json['registered'] is bool
          ? json['registered'] as bool
          : null,
      createdAt: json['created_at']?.toString(),
      lastLoginAt: json['last_login_at']?.toString(),
      features: features,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'status': status,
      'registered': registered,
      'created_at': createdAt,
      'last_login_at': lastLoginAt,
      if (features != null) 'features': features,
    };
  }
}

class LoginResult {
  final AuthUser user;
  final String token;
  final String? expiresAt;

  const LoginResult({
    required this.user,
    required this.token,
    this.expiresAt,
  });

  factory LoginResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    return LoginResult(
      user: AuthUser.fromJson(
        data['user'] as Map<String, dynamic>? ?? {},
      ),
      token: data['token']?.toString() ?? '',
      expiresAt: data['expires_at']?.toString(),
    );
  }
}

class RegisterResult {
  final AuthUser user;
  final String message;

  const RegisterResult({
    required this.user,
    required this.message,
  });

  factory RegisterResult.fromJson(Map<String, dynamic> json) {
    return RegisterResult(
      user: AuthUser.fromJson(
        json['data'] as Map<String, dynamic>? ?? {},
      ),
      message: json['message']?.toString() ??
          'Registration successful. You can now login.',
    );
  }
}

class EmailCheckResult {
  final bool exists;
  final bool registered;
  final String? status;
  final bool domainAllowed;

  const EmailCheckResult({
    required this.exists,
    required this.registered,
    this.status,
    this.domainAllowed = false,
  });

  /// Null status is allowed (e.g. domain self-serve before first register).
  /// Only an explicit non-active status blocks.
  bool get isActive {
    final value = status?.trim().toLowerCase();
    if (value == null || value.isEmpty) return true;
    return value == 'active';
  }

  /// Password step is allowed only when the account exists and is not blocked.
  bool get canEnterPassword => exists && isActive;

  factory EmailCheckResult.fromJson(Map<String, dynamic> json) {
    final data = json['data'] as Map<String, dynamic>? ?? {};
    final rawStatus = data['status']?.toString();
    return EmailCheckResult(
      exists: data['exists'] == true,
      registered: data['registered'] == true,
      status: (rawStatus == null || rawStatus.toLowerCase() == 'null')
          ? null
          : rawStatus,
      domainAllowed: data['domain_allowed'] == true,
    );
  }
}

class AuthException implements Exception {
  final String message;
  final int? statusCode;

  const AuthException(this.message, {this.statusCode});

  @override
  String toString() => message;
}
