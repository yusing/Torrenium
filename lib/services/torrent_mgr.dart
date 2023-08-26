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
import '/interface/download_item.dart';
import '/main.dart' show kIsDesktop;
import 'go_torrent.dart';
import 'storage.dart';
import 'subscription.dart';

final go = GoTorrentBindings(_dylib);

final DynamicLibrary _dylib = () {
  if (Platform.isMacOS || Platform.isIOS) {
    return DynamicLibrary.open('go_torrent.dylib');
  }
  if (Platform.isAndroid || Platform.isLinux) {
    return DynamicLibrary.open('libgo_torrent.so');
  }
  if (Platform.isWindows) {
    return DynamicLibrary.open('go_torrent.dll');
  }
  throw UnsupportedError('Unknown platform: ${Platform.operatingSystem}');
}();

TorrentManager get gTorrentManager => TorrentManager.instance;

class TorrentManager {
  static late final TorrentManager instance;
  static final recvPort = ReceivePort()..listen(_addTorrent);
  final updateNotifier = ValueNotifier(null);

  late var _torrentList = <Torrent>[];
  final placeholders = <Torrent>[];

  late String saveDir;

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
        'torrent': jsonDecode.cStringCall(url.startsWith('magnet:')
            ? go.AddMagnet.dartStringCall(url)
            : go.AddTorrent.dartStringCall(url)),
        'infoHash': message[1],
        'coverUrl': message[2],
      });
    }, [recvPort.sendPort, placeholder.infoHash, placeholder.coverUrl]);
  }

  DownloadItem? findItem(String nameHash) {
    for (final torrent in _torrentList) {
      if (torrent.isMultiFile) {
        for (final file in torrent.files) {
          if (file.nameHash == nameHash) {
            return file;
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
    late final Directory docDir;
    if (Platform.isAndroid) {
      docDir = await getApplicationSupportDirectory();
    } else if (Platform.isIOS) {
      docDir = await getLibraryDirectory();
    } else {
      docDir = await getDownloadsDirectory() ??
          await getApplicationDocumentsDirectory();
    }
    Logger().d('docDir: ${docDir.path}');

    if (!Storage.hasKey('savePath')) {
      Storage.setString('savePath', pathlib.join(docDir.path, 'Torrenium'));
    }
    instance.saveDir = Storage.getString('savePath')!;

    if (kIsDesktop) {
      final dataPath = pathlib.join(instance.saveDir, 'data');
      Logger().d('savePath: ${instance.saveDir}');
      // create save path if it doesn't exist
      await Directory(dataPath).create(recursive: true).catchError((e) {
        throw Exception(e);
      });
    } else {
      await Directory(instance.saveDir).create().catchError((e) {
        throw Exception(e);
      });
    }

    final initClientIsolate = ReceivePort();
    await Isolate.spawn((message) {
      go.InitTorrentClient.dartStringCall(message.last as String);
      (message.first as SendPort)
          .send(go.GetTorrentList().cast<Utf8>().toDartString());
    }, [initClientIsolate.sendPort, instance.saveDir]);

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

extension DartStringTCallback<T> on T Function(String) {
  T cStringCall(Pointer<Char> cStr) {
    assert(cStr != nullptr);
    T result = this(cStr.cast<Utf8>().toDartString());
    go.FreeCString(cStr);
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
