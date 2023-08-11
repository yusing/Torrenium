import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;
import 'package:torrenium/services/watch_history.dart';

import '../services/storage.dart';
import '../services/torrent.dart';
import '../utils/ext_icons.dart';
import '../utils/units.dart';
import 'item.dart';
import 'torrent_file.dart';

class Torrent implements Comparable<Torrent> {
  String name;
  String infoHash;
  int size;
  List<TorrentFile> files = [];
  Pointer<Void> torrentPtr;
  int bytesDownloadedInitial;
  bool paused = false;
  num progress;
  int bytesDownloaded;
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

  String get animeNameKey => 'animeName:$nameHash';

  String get displayName => Storage.getString(animeNameKey) ?? name;

  DateTime get downloadedTime => _downloadedTime ??=
      FileStat.statSync(pathlib.join(gTorrentManager.savePath, name)).modified;

  double get etaSecs => progress == 0
      ? double.infinity
      : (DateTime.now().difference(_startTime).inSeconds *
              (1 - progress) /
              progress)
          .toDouble();

  String get fullPath => pathlib.join(gTorrentManager.savePath, name);

  IconData get icon => getPathIcon(fullPath);

  bool get isComplete => progress == 1.0;

  bool get isMultiFile => files.length > 1;

  bool get isPlaceholder => infoHash == 'placeholder';

  Duration get lastPosition => WatchHistory.getPosition(nameHash);

  String get nameHash => sha256.convert(utf8.encode(name)).toString();

  double get watchProgress => WatchHistory.getProgress(nameHash);

  @override
  int compareTo(Torrent other) {
    // list folders first then sort by downloaded time
    if (files.length > 1 && other.files.length == 1) {
      return -1;
    } else if (files.length == 1 && other.files.length > 1) {
      return 1;
    } else {
      return other.downloadedTime.compareTo(downloadedTime); // descending
    }
  }

  void print() => Logger().i(
      "Torrent: name: $name\ninfoHash: $infoHash\nsize: ${size.humanReadableUnit}\nprogress: ${progress.percentageUnit}");

  Future<void> setDisplayName(String displayName) async =>
      await Storage.setStringIfNotExists(animeNameKey, displayName);

  void startSelfUpdate() {
    _startTime = DateTime.now();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (progress == 1.0 && bytesDownloaded != 0) {
        return;
      }
      if (!paused) {
        // return; // Don't update if not in download page or torrent is paused
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

  Future<void> updateWatchPosition(Duration pos) async {
    await WatchHistory.updatePosition(nameHash, pos);
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
