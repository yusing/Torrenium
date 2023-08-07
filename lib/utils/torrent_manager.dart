import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:torrenium/services/subscription.dart';

import '../classes/item.dart';
import '../classes/torrent.dart';
import 'torrent_binding.dart' as torrent_binding;

TorrentManager get gTorrentManager => TorrentManager.instance;

class TorrentManager {
  static late final TorrentManager instance;
  static final _isolateToMain = ReceivePort()
    ..listen((message) async {
      Torrent torrent = Torrent.fromJson(message['torrent'])..startSelfUpdate();
      gTorrentManager.torrentList.add(torrent);
      await torrent.setDisplayName(message['displayName']);
    });

  static final _dylib = Platform.isWindows
      ? DynamicLibrary.open('libtorrent_go.dll')
      : DynamicLibrary.executable();
  static final go = torrent_binding.TorrentGoBinding(_dylib);
  static bool isInitialized = false;

  late List<Torrent> torrentList;
  late Directory docDir;
  late String savePath;
  late SharedPreferences prefs;

  void deleteTorrent(Torrent t) {
    t.stopSelfUpdate();
    go.DeleteTorrent(t.torrentPtr);
    torrentList.remove(t);
  }

  Future<void> downloadItem(Item item) async {
    if (item.torrentUrl == null) {
      throw Exception('Item has no torrent url');
    }
    final url = item.torrentUrl!;
    await Isolate.spawn((message) {
      message.send({
        "torrent": jsonDecode.cStringCall(url.startsWith('magnet:')
            ? go.AddMagnet.dartStringCall(url)
            : go.AddTorrent.dartStringCall(url)),
        "displayName": item.name,
      });
    }, _isolateToMain.sendPort);
  }

  Torrent getTorrentInfo(Torrent t) {
    return Torrent.fromJson(
        jsonDecode.cStringCall(go.GetTorrentInfo(t.torrentPtr)));
  }

  Future<bool> initInstance() async {
    if (isInitialized) {
      return true;
    }
    prefs = await SharedPreferences.getInstance();
    docDir = await getDownloadsDirectory() ??
        await getApplicationDocumentsDirectory();

    if (!prefs.containsKey('savePath')) {
      return false;
    }
    savePath = prefs.getString('savePath')!;
    if (!await Directory(savePath).exists()) {
      try {
        await Directory(savePath).create(recursive: true);
      } catch (e) {
        Logger().e(e);
        return false;
      }
    }

    go.InitTorrentClient.dartStringCall(savePath);

    // load last session
    torrentList = Torrent.listFromJson.cStringCall(go.GetTorrentList());
    torrentList.sort();
    for (final torrent in torrentList) {
      torrent.startSelfUpdate();
    }
    isInitialized = true;

    Logger().i('TorrentManager initialized');
    await SubscriptionManager.initInstance();
    return true;
  }

  void pauseTorrent(Torrent t) {
    t.stopSelfUpdate();
    t.paused = true;
    go.PauseTorrent(t.torrentPtr);
  }

  void resumeTorrent(Torrent t) {
    t.paused = false;
    t.torrentPtr =
        Pointer<Void>.fromAddress(go.ResumeTorrent.dartStringCall(t.infoHash));
    t.bytesDownloadedInitial = t.bytesDownloaded;
    t.startSelfUpdate();
  }

  static Future<bool> init() async {
    if (!TorrentManager.isInitialized) {
      instance = TorrentManager();
      return await instance.initInstance();
    }
    return true;
  }
}

extension DartStringTCallback<T> on T Function(String) {
  T cStringCall(Pointer<Char> cStr) {
    assert(cStr != nullptr);
    T result = this(cStr.cast<Utf8>().toDartString());
    TorrentManager.go.FreeCString(cStr);
    return result;
  }
}

extension NativeStringTCallback<T> on T Function(Pointer<Char>) {
  T dartStringCall(String s) {
    Pointer<Char> cStr = s.toNativeUtf8().cast<Char>();
    assert(cStr != nullptr);
    T result = this(cStr);
    calloc.free(cStr);
    return result;
  }
}
