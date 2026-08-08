// auth_session.dart — a signed-in Supabase session, as returned by
// Supabase Auth's REST API (/auth/v1/token, /auth/v1/signup). [accessToken]
// is the exact JWT string kola_server's SessionVerifier verifies (HS256
// against SUPABASE_JWT_SECRET — see kola_server/lib/src/services/auth/
// session_verifier.dart) and is what gets passed as the first real
// argument to every kola_client endpoint call.

class AuthSession {
  const AuthSession({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.userId,
    required this.email,
  });

  final String accessToken;
  final String refreshToken;

  /// When [accessToken] expires — used by AuthService to refresh
  /// proactively rather than waiting for a 401 from kola_server.
  final DateTime expiresAt;

  /// The Supabase user UUID (JWT's `sub` claim).
  final String userId;
  final String? email;

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  /// Parses Supabase Auth's token response shape:
  /// { access_token, refresh_token, expires_in, user: { id, email } }
  factory AuthSession.fromJson(Map<String, dynamic> json) {
    final expiresIn = json['expires_in'] as int? ?? 3600;
    final user = json['user'] as Map<String, dynamic>?;
    return AuthSession(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresAt: DateTime.now().add(Duration(seconds: expiresIn)),
      userId: user?['id'] as String? ?? '',
      email: user?['email'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'access_token': accessToken,
    'refresh_token': refreshToken,
    'expires_at': expiresAt.toIso8601String(),
    'user_id': userId,
    'email': email,
  };

  /// Restores a session persisted via [toJson] (LocalStorage) — a
  /// different shape from [fromJson] (Supabase's own wire format),
  /// since expiresAt is already an absolute instant here, not a
  /// relative expires_in seconds count.
  factory AuthSession.fromStorageJson(Map<String, dynamic> json) => AuthSession(
    accessToken: json['access_token'] as String,
    refreshToken: json['refresh_token'] as String,
    expiresAt: DateTime.parse(json['expires_at'] as String),
    userId: json['user_id'] as String,
    email: json['email'] as String?,
  );
}
