/// Stores daemon connection parameters.
class ConnectionConfig {
  final String host;
  final int port;
  final String token;
  final bool useTls;

  /// SHA-256 fingerprint (colon-separated hex) for TLS certificate pinning.
  /// Populated from the `fp=` field in a `nomadterm://` QR code.
  final String? certFingerprint;

  /// Public IP from UPnP mapping (from `pub_host=` QR field), if available.
  final String? pubHost;

  /// External port from UPnP mapping (from `pub_port=` QR field), if available.
  final int? pubPort;

  /// Whether the public endpoint uses TLS (from `pub_tls=1` QR field).
  final bool pubTls;

  // Repo metadata (populated from nomadterm:// QR codes)
  final String repoId;
  final String repoPath;
  final String repoName;
  final DateTime? expiresAt;

  const ConnectionConfig({
    required this.host,
    required this.port,
    required this.token,
    this.useTls = false,
    this.certFingerprint,
    this.pubHost,
    this.pubPort,
    this.pubTls = false,
    this.repoId = '',
    this.repoPath = '',
    this.repoName = '',
    this.expiresAt,
  });

  String get wsUrl => Uri(
    scheme: useTls ? 'wss' : 'ws',
    host: host,
    port: port,
    path: '/ws',
    queryParameters: token.isNotEmpty ? {'token': token} : null,
  ).toString();

  /// Public URL using the UPnP endpoint, if available.
  /// Uses [pubTls] (not [useTls]) — the LAN and public endpoints may have
  /// different TLS settings.
  String? get publicWsUrl {
    if (pubHost == null || pubPort == null) return null;
    return Uri(
      scheme: pubTls ? 'wss' : 'ws',
      host: pubHost,
      port: pubPort,
      path: '/ws',
      queryParameters: token.isNotEmpty ? {'token': token} : null,
    ).toString();
  }

  ConnectionConfig copyWith({
    String? host,
    int? port,
    String? token,
    bool? useTls,
    String? certFingerprint,
    String? pubHost,
    int? pubPort,
    bool? pubTls,
    String? repoId,
    String? repoPath,
    String? repoName,
    DateTime? expiresAt,
  }) => ConnectionConfig(
    host: host ?? this.host,
    port: port ?? this.port,
    token: token ?? this.token,
    useTls: useTls ?? this.useTls,
    certFingerprint: certFingerprint ?? this.certFingerprint,
    pubHost: pubHost ?? this.pubHost,
    pubPort: pubPort ?? this.pubPort,
    pubTls: pubTls ?? this.pubTls,
    repoId: repoId ?? this.repoId,
    repoPath: repoPath ?? this.repoPath,
    repoName: repoName ?? this.repoName,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}
