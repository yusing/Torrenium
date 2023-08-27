import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;

import '/interface/download_item.dart';
import '/interface/resumeable.dart';
import '/services/storage.dart';
import '/services/torrent_mgr.dart';
import '/utils/connectivity.dart';
import 'rss_item.dart';
import 'torrent_file.dart';

class Torrent extends DownloadItem implements Resumeable {
  static final updateTimerMap = <String, Timer>{};

  final List<TorrentFile> _files = [];
  String infoHash;
  Pointer<Void> torrentPtr;
  int bytesDownloadedInitial;
  DateTime? _downloadedTime;

  @override
  bool isPaused = false;

  Torrent._(
      {required super.name,
      required super.progress,
      required super.size,
      required super.bytesDownloaded,
      required this.infoHash,
      required this.torrentPtr,
      required this.bytesDownloadedInitial});

  factory Torrent.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json == null || json.isEmpty) {
      throw ArgumentError.value(json, 'json', 'json cannot be null or empty');
    }
    final torrent = Torrent._(
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

  factory Torrent.placeholder(RSSItem item) {
    return Torrent._(
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

  DateTime get downloadedTime =>
      _downloadedTime ??= FileStat.statSync(videoPath).modified;

  @override
  List<TorrentFile> get files => _files;

  @override
  int get hashCode => infoHash.hashCode;

  @override
  bool get isMultiFile => files.length > 1;

  @override
  bool get isPlaceholder => infoHash.startsWith('placeholder:');

  @override
  String get videoPath => pathlib.join(gTorrentManager.saveDir, name);

  @override
  bool operator ==(Object other) {
    if (other is Torrent) {
      return infoHash == other.infoHash;
    }
    return false;
  }

  @override
  Future<void> delete() async {
    gTorrentManager.deleteTorrent(this);
    await Storage.removeKey('cover-$infoHash');
  }

  @override
  void pause() {
    gTorrentManager.pauseTorrent(this);
  }

  @override
  void resume() {
    gTorrentManager.resumeTorrent(this);
  }

  void selfUpdate() {
    final Map tMap = jsonDecode.cStringCall(go.GetTorrentInfo(torrentPtr));
    progress = tMap['progress'];
    size = tMap['size'];
    bytesDownloaded =
        tMap['bytes_downloaded'] ?? tMap['progress'] * tMap['size'];
    _downloadedTime = DateTime.now();
  }

  void startSelfUpdate() {
    if (isPlaceholder) {
      return;
    }
    if (updateTimerMap.containsKey(infoHash)) {
      Logger()
          .e('Timer already exists for $infoHash but startSelfUpdate() called');
      return;
    }
    updateTimerMap[infoHash] =
        Timer.periodic(const Duration(seconds: 1), (_) async {
      if (isComplete && bytesDownloaded > 0) {
        assert(bytesDownloaded == size, '$bytesDownloaded != $size');
        Logger().d('Torrent $name complete, stopping self update');
        gTorrentManager.removeFromMap(this);
        go.DeleteMetadata(torrentPtr);
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

        selfUpdate();
      }
    });
  }

  void stopSelfUpdate() {
    final timer = updateTimerMap.remove(infoHash);
    if (timer == null) {
      Logger().e('Timer not found for $infoHash but stopSelfUpdate() called');
      return;
    }
    timer.cancel();
  }

  // TODO: remove below
  // void updateDetail(Torrent other) {
  //   name = other.name;
  //   infoHash = other.infoHash;
  //   size = other.size;
  //   _files = other.files;
  //   torrentPtr = other.torrentPtr;
  //   bytesDownloadedInitial = other.bytesDownloadedInitial;
  //   progress = other.progress;
  //   bytesDownloaded = other.bytesDownloaded;
  // }

  static List<Torrent> listFromJson(String jsonStr) {
    final List? json = jsonDecode(jsonStr);
    if (json == null) {
      return [];
    }
    return json.map<Torrent>((e) => Torrent.fromJson(e)).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
