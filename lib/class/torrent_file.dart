import 'dart:convert';

import 'package:path/path.dart' as pathlib;

import '/interface/download_item.dart';
import '/services/torrent_mgr.dart';

class TorrentFile extends DownloadItem {
  final String relativePath;

  TorrentFile({
    required super.name,
    required super.size,
    required this.relativePath,
    required super.bytesDownloaded,
    required super.progress,
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

  @override
  String get displayName => name;

  @override
  bool get isMultiFile => false;

  @override
  bool get isPlaceholder => false;

  @override
  String get videoPath => pathlib.join(gTorrentManager.saveDir, relativePath);

  @override
  String toString() {
    // for debugging
    return group ?? nameCleanedNoNum;
  }
}
