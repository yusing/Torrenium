import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_animate/flutter_animate.dart';
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
  static final _map = <String, Torrent>{};

  List<TorrentFile> _files = [];
  String infoHash;
  Pointer<Void> torrentPtr;
  int bytesDownloadedInitial;
  DateTime? _downloadedTime;

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
    if (_map.containsKey(infoHash)) {
      return _map[infoHash]!..selfUpdate(json);
    }
    final torrent = _map[infoHash] = Torrent._(
      name: json['name'],
      infoHash: infoHash,
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

  Torrent._(
      {required super.name,
      required super.progress,
      required super.size,
      required super.bytesDownloaded,
      required this.infoHash,
      required this.torrentPtr,
      required this.bytesDownloadedInitial});

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
    await kStorage.remove('cover-$infoHash');
    _map.remove(infoHash);
  }

  @override
  void pause() {
    gTorrentManager.pauseTorrent(this);
  }

  @override
  void resume() {
    gTorrentManager.resumeTorrent(this);
  }

  void selfUpdate(Map tMap) {
    progress = tMap['progress'];
    size = tMap['size'];
    bytesDownloaded =
        tMap['bytes_downloaded'] ?? tMap['progress'] * tMap['size'];
    torrentPtr = Pointer<Void>.fromAddress(tMap['ptr']);
    _downloadedTime = DateTime.now();
    _files = [
      for (final file in tMap['files'])
        TorrentFile.fromJson(file)..parent = this
    ];
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
    updateTimerMap[infoHash] = Timer.periodic(1.seconds, (_) async {
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

        Torrent.fromJson(jsonDecode.cStringCall(go.GetTorrentInfo(torrentPtr)));
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

  static List<Torrent> listFromJson(String jsonStr) {
    final List? json = jsonDecode(jsonStr);
    if (json == null) {
      return [];
    }
    return json.map<Torrent>((e) => Torrent.fromJson(e)).toList(growable: false)
      ..sort((a, b) => a.name.compareTo(b.name));
  }
}
