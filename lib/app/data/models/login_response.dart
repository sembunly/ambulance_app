// ── Login response model ──────────────────────────────────────────────────
class LoginResponse {
  const LoginResponse({
    required this.token,
    required this.userId,
    required this.displayName,
    this.tokenType = '',
    this.accessTokenExpiresAt,
    this.refreshToken = '',
    this.refreshTokenExpiresAt,
    this.sessionId = '',
    this.username = '',
    this.authorities = const <String>[],
  });

  final String token;
  final String userId;
  final String displayName;
  final String tokenType;
  final DateTime? accessTokenExpiresAt;
  final String refreshToken;
  final DateTime? refreshTokenExpiresAt;
  final String sessionId;
  final String username;
  final List<String> authorities;

  String get accessToken => token;

  // ── API JSON parsing ─────────────────────────────────────────────────────
  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    final rawBody = json['body'];
    final body = rawBody is Map<String, dynamic> ? rawBody : json;
    final rawHeader = json['header'];
    final header = rawHeader is Map<String, dynamic>
        ? rawHeader
        : const <String, dynamic>{};
    final username = (body['username'] ?? '').toString();

    return LoginResponse(
      token:
          (body['accessToken'] ??
                  body['access_token'] ??
                  body['token'] ??
                  header['token'] ??
                  '')
              .toString(),
      userId: (body['userId'] ?? body['id'] ?? '').toString(),
      displayName:
          (body['displayName'] ??
                  body['name'] ??
                  (username.isEmpty ? 'Responder' : username))
              .toString(),
      tokenType: (body['tokenType'] ?? '').toString(),
      accessTokenExpiresAt: _parseDate(
        body['accessTokenExpiresAt'] ?? body['access_token_expires_at'],
      ),
      refreshToken: (body['refreshToken'] ?? body['refresh_token'] ?? '')
          .toString(),
      refreshTokenExpiresAt: _parseDate(
        body['refreshTokenExpiresAt'] ?? body['refresh_token_expires_at'],
      ),
      sessionId: (body['sessionId'] ?? '').toString(),
      username: username,
      authorities: _parseAuthorities(body['authorities']),
    );
  }

  // ── Stored session parsing ───────────────────────────────────────────────
  factory LoginResponse.fromStoredSession(
    Map<String, dynamic> json, {
    required String accessToken,
    required String refreshToken,
  }) {
    return LoginResponse(
      token: accessToken,
      refreshToken: refreshToken,
      userId: (json['userId'] ?? '').toString(),
      displayName: (json['displayName'] ?? '').toString(),
      tokenType: (json['tokenType'] ?? 'Bearer').toString(),
      accessTokenExpiresAt: _parseDate(json['accessTokenExpiresAt']),
      refreshTokenExpiresAt: _parseDate(json['refreshTokenExpiresAt']),
      sessionId: (json['sessionId'] ?? '').toString(),
      username: (json['username'] ?? '').toString(),
      authorities: _parseAuthorities(json['authorities']),
    );
  }

  // ── Stored session serialization ────────────────────────────────────────
  Map<String, dynamic> toStoredSessionJson() {
    return <String, dynamic>{
      'userId': userId,
      'displayName': displayName,
      'tokenType': tokenType,
      if (accessTokenExpiresAt != null)
        'accessTokenExpiresAt': accessTokenExpiresAt!.toUtc().toIso8601String(),
      if (refreshTokenExpiresAt != null)
        'refreshTokenExpiresAt': refreshTokenExpiresAt!
            .toUtc()
            .toIso8601String(),
      'sessionId': sessionId,
      'username': username,
      'authorities': authorities,
    };
  }

  // ── Copy helper ─────────────────────────────────────────────────────────
  LoginResponse copyWith({
    String? token,
    String? userId,
    String? displayName,
    String? tokenType,
    DateTime? accessTokenExpiresAt,
    String? refreshToken,
    DateTime? refreshTokenExpiresAt,
    String? sessionId,
    String? username,
    List<String>? authorities,
  }) {
    return LoginResponse(
      token: token ?? this.token,
      userId: userId ?? this.userId,
      displayName: displayName ?? this.displayName,
      tokenType: tokenType ?? this.tokenType,
      accessTokenExpiresAt: accessTokenExpiresAt ?? this.accessTokenExpiresAt,
      refreshToken: refreshToken ?? this.refreshToken,
      refreshTokenExpiresAt:
          refreshTokenExpiresAt ?? this.refreshTokenExpiresAt,
      sessionId: sessionId ?? this.sessionId,
      username: username ?? this.username,
      authorities: authorities ?? this.authorities,
    );
  }

  // ── Parsing helpers ─────────────────────────────────────────────────────
  static DateTime? _parseDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static List<String> _parseAuthorities(Object? value) {
    if (value is! List) return const <String>[];
    return List<String>.unmodifiable(value.map((item) => item.toString()));
  }
}
