import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

import '/class/item.dart';
import '/class/torrent.dart';
import '/main.dart' show kIsDesktop;
import '/utils/ffi.dart';
import '/utils/torrent_binding.dart' as torrent_binding;
import 'storage.dart';
import 'subscription.dart';

TorrentManager get gTorrentManager => TorrentManager.instance;

class TorrentManager {
  static late final TorrentManager instance;
  static final recvPort = ReceivePort()..listen(_addTorrent);
  /* !Must be static otherwise invalid argument inside isolate */
  static final DynamicLibrary _dylib = Platform.isWindows
      ? DynamicLibrary.open('libtorrent_go.dll')
      : Platform.isLinux || Platform.isAndroid
          ? DynamicLibrary.open('libtorrent_go.so')
          : DynamicLibrary.open('libtorrent_go.dylib');
  static final torrent_binding.TorrentGoBinding go =
      torrent_binding.TorrentGoBinding(_dylib);
  final updateNotifier = ValueNotifier(null);

  late var _torrentList = <Torrent>[];
  final placeholders = <Torrent>[];

  late final Directory docDir;

  late String savePath;

  List<Torrent> get torrentList => placeholders + _torrentList;

  void deleteTorrent(Torrent t) {
    assert(!t.isPlaceholder, 'Cannot delete placeholder torrent');
    t.stopSelfUpdate();
    go.DeleteTorrent(t.torrentPtr);
    _torrentList.remove(t);
    // WatchHistory.remove(t.nameHash);
    gSubscriptionManager.addExclusion(t.nameHash);
    updateNotifier.notifyListeners();
  }

  Future<void> downloadItem(Item item) async {
    if (item.torrentUrl == null) {
      throw Exception('Item has no torrent url');
    }
    final url = item.torrentUrl!;
    final placeholder = Torrent.placeholder(item);
    placeholders.add(placeholder);
    updateNotifier.notifyListeners();

    await Isolate.spawn((message) {
      // spawn in isolate to avoid blocking main thread
      (message.first as SendPort).send({
        "torrent": jsonDecode.cStringCall(url.startsWith('magnet:')
            ? go.AddMagnet.dartStringCall(url)
            : go.AddTorrent.dartStringCall(url)),
        "infoHash": message[1],
        "coverUrl": message[2],
      });
    }, [recvPort.sendPort, placeholder.infoHash, placeholder.coverUrl]);
  }

  Torrent? findTorrent(String nameHash) {
    for (final torrent in _torrentList) {
      if (torrent.isMultiFile) {
        for (final file in torrent.files) {
          if (file.nameHash == nameHash) {
            return torrent;
          }
        }
      }
      if (torrent.nameHash == nameHash) {
        return torrent;
      }
    }

    return null;
  }

  Torrent getTorrentInfo(Torrent t) =>
      Torrent.fromJson(jsonDecode.cStringCall(go.GetTorrentInfo(t.torrentPtr)));

  void pauseTorrent(Torrent t) {
    t.stopSelfUpdate();
    t.isPaused = true;
    go.PauseTorrent(t.torrentPtr);
  }

  void resumeTorrent(Torrent t) {
    t.isPaused = false;
    t.torrentPtr =
        Pointer<Void>.fromAddress(go.ResumeTorrent.dartStringCall(t.infoHash));
    t.bytesDownloadedInitial = t.bytesDownloaded;
    t.startSelfUpdate();
  }

  static Future<void> init() async {
    instance = TorrentManager();
    if (Platform.isAndroid) {
      instance.docDir = await getApplicationSupportDirectory();
    } else if (Platform.isIOS) {
      instance.docDir = await getLibraryDirectory();
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

    if (kIsDesktop) {
      final dataPath = pathlib.join(instance.savePath, 'data');
      Logger().d('savePath: ${instance.savePath}');
      // create save path if it doesn't exist
      await Directory(dataPath).create(recursive: true).catchError((e) {
        Logger().e(e);
        throw Exception('Failed to create data path');
      });
    }

    final initClientIsolate = ReceivePort();
    await Isolate.spawn((message) {
      go.InitTorrentClient.dartStringCall(message.last as String);
      (message.first as SendPort)
          .send(go.GetTorrentList().cast<Utf8>().toDartString());
    }, [initClientIsolate.sendPort, instance.savePath]);

    Logger().d('TorrentClient initialized');

    // load last session
    instance._torrentList = Torrent.listFromJson(
        await initClientIsolate.firstWhere((element) => element is String))
      ..sort()
      ..forEach((t) => t.startSelfUpdate());

    Logger().d(
        'TorrentManager initialized ${instance._torrentList.length} torrents');
  }

  static _addTorrent(dynamic message) {
    instance.placeholders.firstWhere((t) => t.infoHash == message['infoHash'],
        orElse: () => throw Exception('Placeholder not found'))
      ..updateDetail(Torrent.fromJson(message['torrent']))
      ..startSelfUpdate()
      ..coverUrl = message['coverUrl'];
    instance.updateNotifier.notifyListeners();
  }
}
