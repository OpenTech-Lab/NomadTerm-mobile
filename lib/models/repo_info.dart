/// A repo entry received from the server via the [list_repos] WebSocket message.
class RepoInfo {
  final String id;
  final String name;
  final String path;

  const RepoInfo({required this.id, required this.name, required this.path});

  factory RepoInfo.fromJson(Map<String, dynamic> json) => RepoInfo(
        id: json['id'] as String,
        name: json['name'] as String,
        path: json['path'] as String,
      );
}
