import 'dart:async';
import 'dart:convert';
import 'dart:ffi';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;

import '/interface/download_item.dart';
import '/interface/resumeable.dart';
import '/services/storage.dart';
import '/services/subscription.dart';
import '/services/torrent_mgr.dart';
import '/utils/connectivity.dart';
import '/utils/string.dart';
import 'rss_item.dart';
import 'torrent_file.dart';

class Torrent extends DownloadItem implements Resumeable {
  static final watcherMap = <String, StreamSubscription>{};
  static final map = <String, Torrent>{};

  final List<TorrentFile> _files = [];
  String infoHash;
  Pointer<Void> torrentPtr;

  @override
  bool isPaused = false;

  factory Torrent.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json == null || json.isEmpty) {
      throw ArgumentError.value(json, 'json', 'json cannot be null or empty');
    }
    final infoHash = json['info_hash'];
    if (map.containsKey(infoHash)) {
      return map[infoHash]!..selfUpdate(json);
    }
    final torrent = map[infoHash] = Torrent._(
      name: json['name'],
      infoHash: infoHash,
      size: json['size'],
      torrentPtr: Pointer<Void>.fromAddress(json['ptr']),
      progress: json['progress'],
      bytesDownloaded:
          json['bytes_downloaded'] ?? json['progress'] * json['size'],
    );
    for (final file in json['files']) {
      torrent.files.add(TorrentFile.fromJson(file)..parent = torrent);
    }
    return torrent;
  }

  Torrent._(
      {required super.name,
      required super.progress,
      required super.size,
      required super.bytesDownloaded,
      required this.infoHash,
      required this.torrentPtr});

  @override
  String get displayName =>
      isMultiFile ? '$nameCleaned (${files.length} files)' : name;

  @override
  List<TorrentFile> get files => _files;

  @override
  String get fullPath => pathlib.join(gTorrentManager.saveDir, name);

  @override
  int get hashCode => infoHash.hashCode;

  @override
  bool get isMultiFile => files.length > 1;

  @override
  bool get isPlaceholder => this is TorrentPlaceHolder;

  @override
  bool operator ==(Object other) {
    if (other is Torrent) {
      return infoHash == other.infoHash;
    }
    return false;
  }

  @override
  Future<void> delete() async {
    stopSelfUpdate();
    if (!isPlaceholder) {
      go.DeleteTorrent(torrentPtr);
      gTorrentManager.removeFromMap(this);
      await gSubscriptionManager.addExclusion(id);
      await gStorage.remove(coverUrlKey);
    }
    assert(map.remove(infoHash) != null);
    Logger().d('Torrent $name deleted');
  }

  @override
  void pause() {
    stopSelfUpdate();
    isPaused = true;
    notifyListeners();
    go.PauseTorrent(torrentPtr);
  }

  @override
  void resume() {
    isPaused = false;
    torrentPtr =
        Pointer<Void>.fromAddress(go.ResumeTorrent.dartStringCall(infoHash));
    timeStarted = DateTime.now();
    progressInitial = progress;
    startSelfUpdate();
    notifyListeners();
  }

  void selfUpdate(Map tMap) {
    // TODO: maybe can get bytesDownloaded from FileStat.size?
    size = tMap['size'];
    bytesDownloaded =
        tMap['bytes_downloaded'] ?? tMap['progress'] * tMap['size'];
    torrentPtr = Pointer<Void>.fromAddress(tMap['ptr']);
    for (var i = 0; i < tMap['files'].length; i++) {
      files[i].selfUpdate(tMap['files'][i]);
    }
    progress = tMap['progress'];
  }

  void startSelfUpdate() {
    if (isPlaceholder) {
      return;
    }
    if (watcherMap.containsKey(infoHash)) {
      Logger().e(
          'Watcher already exists for $infoHash but startSelfUpdate() called');
      return;
    }
    final watcher = Stream.periodic(1.seconds);
    watcherMap[infoHash] = watcher.listen((event) async {
      if (isComplete) {
        Logger().d('Torrent $name complete, stopping self update');
        stopSelfUpdate();
        return;
      }

      if (!isPaused) {
        // pause torrent if limited connectivity, resume when connected
        if (await isLimitedConnectivity()) {
          pause();
          late StreamSubscription sub;
          sub = Connectivity().onConnectivityChanged.listen((event) async {
            if (!await isLimitedConnectivity()) {
              resume();
              sub.cancel();
            }
          });
        }
        Torrent.fromJson(jsonDecode.cStringCall(go.GetTorrentInfo(torrentPtr)));
      }
    }, cancelOnError: false);
  }

  void stopSelfUpdate() {
    final watcher = watcherMap.remove(infoHash);
    if (watcher == null) {
      Logger().e('Watcher not found for $infoHash but stopSelfUpdate() called');
      return;
    }
    watcher.cancel();
  }

  static List<Torrent> listFromJson(String jsonStr) {
    final List? json = jsonDecode(jsonStr);
    if (json == null) {
      return [];
    }
    return json.map<Torrent>((e) => Torrent.fromJson(e)).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}

class TorrentPlaceHolder extends Torrent {
  static final map = <String, TorrentPlaceHolder>{};

  TorrentPlaceHolder.create(RSSItem item)
      : super._(
            name: item.name,
            infoHash: item.name.b64,
            size: 0,
            torrentPtr: nullptr,
            progress: 0,
            bytesDownloaded: 0) {
    map[infoHash] = this;
  }
}
