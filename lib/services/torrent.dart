import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

import '../classes/item.dart';
import '../classes/torrent.dart';
import 'storage.dart';
import '../utils/ffi.dart';
import '../utils/torrent_binding.dart' as torrent_binding;

TorrentManager get gTorrentManager => TorrentManager.instance;

class TorrentManager {
  static late final TorrentManager instance;
  static final _isolateToMain = ReceivePort()
    ..listen((message) async {
      final torrent = instance.torrentList.firstWhere(
          (t) => t.infoHash == message['displayName'],
          orElse: () => throw Exception('Torrent not found'));
      torrent.updateDetail(Torrent.fromJson(message['torrent']));
      torrent.startSelfUpdate();
      await torrent.setDisplayName(message['displayName']);
    });

  static final _dylib = Platform.isWindows
      ? DynamicLibrary.open('libtorrent_go.dll')
      : Platform.isLinux || Platform.isAndroid
          ? DynamicLibrary.open('libtorrent_go.so')
          : DynamicLibrary.executable();
  static final go = torrent_binding.TorrentGoBinding(_dylib);

  var torrentList = <Torrent>[];
  late final Directory docDir;
  late String savePath;

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
    final placeholder = Torrent.placeholder(item);
    torrentList.add(placeholder);
    await Isolate.spawn((message) {
      message.send({
        "torrent": jsonDecode.cStringCall(url.startsWith('magnet:')
            ? go.AddMagnet.dartStringCall(url)
            : go.AddTorrent.dartStringCall(url)),
        "displayName": item.name
      });
    }, _isolateToMain.sendPort);
  }

  Torrent getTorrentInfo(Torrent t) =>
      Torrent.fromJson(jsonDecode.cStringCall(go.GetTorrentInfo(t.torrentPtr)));

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

  static Future<void> init() async {
    instance = TorrentManager();
    if (Platform.isAndroid) {
      instance.docDir = await getApplicationSupportDirectory();
    } else {
      instance.docDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    Logger().d('docDir: ${instance.docDir.path}');

    if (!Storage.hasKey('savePath')) {
      Storage.setString(
          'savePath', pathlib.join(instance.docDir.path, 'Torrenium'));
    }
    instance.savePath = Storage.getString('savePath')!;
    Logger().d('savePath: ${instance.savePath}');
    // create save path if it doesn't exist
    await Directory(instance.savePath).create(recursive: true).catchError((e) {
      Logger().e(e);
      throw Exception('Failed to create save path');
    });

    go.InitTorrentClient.dartStringCall(instance.savePath);
    Logger().d('TorrentClient initialized');

    // load last session
    instance.torrentList = Torrent.listFromJson.cStringCall(go.GetTorrentList())
      ..sort()
      ..forEach((t) => t.startSelfUpdate());

    Logger().d('TorrentManager initialized');
  }
}
