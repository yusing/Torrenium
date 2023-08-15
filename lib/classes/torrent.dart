import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:path/path.dart' as pathlib;

import '../services/storage.dart';
import '../services/torrent.dart';
import '../utils/ext_icons.dart';
import '../utils/string.dart';
import 'download_item.dart';
import 'item.dart';
import 'torrent_file.dart';

class Torrent extends DownloadItem implements Comparable<Torrent> {
  String name, infoHash;
  List<TorrentFile> files = [];
  Pointer<Void> torrentPtr;
  int size, bytesDownloaded, bytesDownloadedInitial;
  bool paused = false;
  num progress;
  ValueNotifier<void> stateNotifier = ValueNotifier(null);
  Timer? _updateTimer;
  late DateTime _startTime;
  DateTime? _downloadedTime;

  Torrent(
      {required this.name,
      required this.infoHash,
      required this.size,
      required this.torrentPtr,
      required this.progress,
      required this.bytesDownloaded,
      required this.bytesDownloadedInitial});
  factory Torrent.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json == null || json.isEmpty) {
      return Torrent(
          name: '',
          infoHash: '',
          size: 0,
          torrentPtr: nullptr,
          progress: 0,
          bytesDownloaded: 0,
          bytesDownloadedInitial: 0);
    }
    final torrent = Torrent(
      name: json['name'],
      infoHash: json['info_hash'],
      size: json['size'],
      torrentPtr: Pointer<Void>.fromAddress(json['ptr']),
      progress: json['progress'],
      bytesDownloaded:
          json['bytes_downloaded'] ?? json['progress'] * json['size'],
      bytesDownloadedInitial:
          json['bytes_downloaded'] ?? json['progress'] * json['size'],
    );
    final fp = torrent.fullPath;
    for (final file in json['files']) {
      torrent.files.add(TorrentFile.fromJson(file));
    }
    return torrent;
  }
  factory Torrent.placeholder(Item item) {
    return Torrent(
        name: 'Downloading metadata... ${item.name}',
        infoHash: item.name,
        size: 0,
        torrentPtr: nullptr,
        progress: 0,
        bytesDownloaded: 0,
        bytesDownloadedInitial: 0);
  }
  String get animeNameKey => 'animeName:${name.sha256Hash}';

  @override
  String get displayName => Storage.getString(animeNameKey) ?? name;

  DateTime get downloadedTime => _downloadedTime ??=
      FileStat.statSync(pathlib.join(gTorrentManager.savePath, name)).modified;

  double get etaSecs => progress == 0
      ? double.infinity
      : (DateTime.now().difference(_startTime).inSeconds *
              (1 - progress) /
              progress)
          .toDouble();

  @override
  String get fullPath => pathlib.join(gTorrentManager.savePath, name);

  IconData get icon => getPathIcon(fullPath);

  bool get isComplete => progress == 1.0;

  bool get isMultiFile => files.length > 1;

  bool get isPlaceholder => infoHash == 'placeholder';

  @override
  int compareTo(Torrent other) {
    // list folders first then sort by downloaded time
    if (files.length > 1 && other.files.length == 1) {
      return -1;
    } else if (files.length == 1 && other.files.length > 1) {
      return 1;
    } else if (watchProgress < other.watchProgress) {
      return 1;
    } else if (watchProgress > other.watchProgress) {
      return -1;
    } else {
      return other.downloadedTime.compareTo(downloadedTime); // descending
    }
  }

  @override
  void delete() {
    gTorrentManager.deleteTorrent(this);
  }

  Future<void> setDisplayName(String displayName) async =>
      await Storage.setStringIfNotExists(animeNameKey,
          displayName.trim().replaceAll('【', '[').replaceAll('】', ']'));

  void startSelfUpdate() {
    _startTime = DateTime.now();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (progress == 1.0 && bytesDownloaded != 0) {
        return;
      }
      if (!paused) {
        Torrent tNewer = gTorrentManager.getTorrentInfo(this);
        if (progress != tNewer.progress) {
          progress = tNewer.progress;
          bytesDownloaded = tNewer.bytesDownloaded;
          _downloadedTime = DateTime.now();
          for (int i = 0; i < files.length; i++) {
            assert(files[i].name == tNewer.files[i].name);
            files[i] = tNewer.files[i];
          }
        }
      }
      stateNotifier.notifyListeners();
    });
  }

  void stopSelfUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void updateDetail(Torrent other) {
    name = other.name;
    infoHash = other.infoHash;
    size = other.size;
    files = other.files;
    torrentPtr = other.torrentPtr;
    bytesDownloadedInitial = other.bytesDownloadedInitial;
    progress = other.progress;
    bytesDownloaded = other.bytesDownloaded;
  }

  static List<Torrent> listFromJson(String jsonStr) {
    final json = jsonDecode(jsonStr);
    if (json == null) {
      return [];
    }
    final torrents = <Torrent>[];
    for (final torrent in json) {
      torrents.add(Torrent.fromJson(torrent));
    }
    return torrents;
  }
}
