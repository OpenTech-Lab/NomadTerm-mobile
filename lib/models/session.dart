/// Represents a single PTY session on the daemon.
class Session {
  final String id;
  final String cli;
  final String status;

  const Session({
    required this.id,
    required this.cli,
    required this.status,
  });

  bool get isRunning => status == 'running';

  factory Session.fromJson(Map<String, dynamic> json) => Session(
        id: json['id'] as String,
        cli: json['cli'] as String,
        status: json['status'] as String,
      );

  @override
  String toString() => 'Session(id: $id, cli: $cli, status: $status)';
}
