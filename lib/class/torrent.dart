import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:path/path.dart' as pathlib;

import '/interface/download_item.dart';
import '/interface/resumeable.dart';
import '/services/storage.dart';
import '/services/torrent_mgr.dart';
import '/utils/connectivity.dart';
import 'item.dart';
import 'torrent_file.dart';

class Torrent extends DownloadItem implements Resumeable, Comparable<Torrent> {
  List<TorrentFile> _files = [];

  String infoHash;
  Pointer<Void> torrentPtr;
  int size, bytesDownloadedInitial;
  Timer? _updateTimer;
  late DateTime _startTime;
  DateTime? _downloadedTime;

  @override
  bool isPaused = false;

  Torrent(
      {required super.name,
      required super.progress,
      required super.bytesDownloaded,
      required this.infoHash,
      required this.size,
      required this.torrentPtr,
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
      torrent.files.add(TorrentFile.fromJson(file)..parent = torrent);
    }
    return torrent;
  }
  factory Torrent.placeholder(Item item) {
    return Torrent(
        name: 'Downloading metadata...: ${item.nameCleaned}',
        infoHash: 'placeholder:${item.nameCleaned.hashCode}',
        size: 0,
        torrentPtr: nullptr,
        progress: 0,
        bytesDownloaded: 0,
        bytesDownloadedInitial: 0);
  }

  @override
  String get displayName =>
      isMultiFile ? '$nameCleaned (${files.length} files)' : name;

  DateTime get downloadedTime => _downloadedTime ??=
      FileStat.statSync(pathlib.join(gTorrentManager.savePath, name)).modified;

  double get etaSecs => progress == 0
      ? double.infinity
      : (DateTime.now().difference(_startTime).inSeconds *
              (1 - progress) /
              progress)
          .toDouble();

  @override
  List<TorrentFile> get files => _files;

  @override
  int get hashCode => infoHash.hashCode;

  @override
  bool get isMultiFile => files.length > 1;

  @override
  bool get isPlaceholder => infoHash.startsWith('placeholder:');

  @override
  String get videoPath => pathlib.join(gTorrentManager.savePath, name);

  @override
  bool operator ==(Object other) {
    if (other is Torrent) {
      return infoHash == other.infoHash;
    }
    return false;
  }

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
    Storage.removeKey('cover-$infoHash');
  }

  @override
  void pause() {
    gTorrentManager.pauseTorrent(this);
  }

  @override
  void resume() {
    gTorrentManager.resumeTorrent(this);
  }

  void startSelfUpdate() {
    _startTime = DateTime.now();
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (_) async {
      if (progress == 1.0 && bytesDownloaded != 0) {
        stopSelfUpdate();
        return;
      }

      if (!isPaused) {
        // pause torrent if limited connectivity, resume when connected
        if (await isLimitedConnectivity()) {
          gTorrentManager.pauseTorrent(this);
          stopSelfUpdate();
          late StreamSubscription sub;
          sub = Connectivity().onConnectivityChanged.listen((event) async {
            if (!await isLimitedConnectivity()) {
              gTorrentManager.resumeTorrent(this);
              startSelfUpdate();
              sub.cancel();
            }
          });
        }

        Torrent tNewer = gTorrentManager.getTorrentInfo(this);
        if (progress != tNewer.progress) {
          progress = tNewer.progress;
          bytesDownloaded = tNewer.bytesDownloaded;
          _downloadedTime = DateTime.now();
          _files = tNewer._files;
          updateNotifier.notifyListeners();
        }
      }
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
    _files = other.files;
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
    return json
        .map<Torrent>((e) => Torrent.fromJson(e))
        .toList(growable: false);
  }
}
