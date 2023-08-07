import 'dart:convert';

class TorrentFile {
  final String name;
  final int size;
  final String relativePath;
  int bytesDownloaded;
  num progress;

  TorrentFile({
    required this.name,
    required this.size,
    required this.relativePath,
    required this.bytesDownloaded,
    required this.progress,
  });

  factory TorrentFile.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json == null) {
      return TorrentFile(
          name: '', size: 0, relativePath: '', bytesDownloaded: 0, progress: 0);
    }
    return TorrentFile(
      name: json['name'],
      size: json['size'],
      relativePath: json['rel_path'],
      bytesDownloaded:
          json['bytes_downloaded'] ?? json['progress'] * json['size'],
      progress: json['progress'],
    );
  }
}
