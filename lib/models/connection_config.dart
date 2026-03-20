/// Stores daemon connection parameters.
class ConnectionConfig {
  final String host;
  final int port;
  final String token;
  final bool useTls;

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

  ConnectionConfig copyWith({
    String? host,
    int? port,
    String? token,
    bool? useTls,
    String? repoId,
    String? repoPath,
    String? repoName,
    DateTime? expiresAt,
  }) => ConnectionConfig(
    host: host ?? this.host,
    port: port ?? this.port,
    token: token ?? this.token,
    useTls: useTls ?? this.useTls,
    repoId: repoId ?? this.repoId,
    repoPath: repoPath ?? this.repoPath,
    repoName: repoName ?? this.repoName,
    expiresAt: expiresAt ?? this.expiresAt,
  );
}
