/// Stores daemon connection parameters.
class ConnectionConfig {
  final String host;
  final int port;
  final String token;
  final bool useTls;

  const ConnectionConfig({
    required this.host,
    required this.port,
    required this.token,
    this.useTls = false,
  });

  String get wsUrl =>
      '${useTls ? 'wss' : 'ws'}://$host:$port/ws';

  ConnectionConfig copyWith({
    String? host,
    int? port,
    String? token,
    bool? useTls,
  }) =>
      ConnectionConfig(
        host: host ?? this.host,
        port: port ?? this.port,
        token: token ?? this.token,
        useTls: useTls ?? this.useTls,
      );
}
