import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:ffi/ffi.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

import '/class/rss_item.dart';
import '/class/torrent.dart';
import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/main.dart' show kIsDesktop;
import '/utils/fs.dart';
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
  static final recvPort = ReceivePort()..listen(onMetadataLoaded);

  final placeholders = <Torrent>[];
  var ungrouped = <Torrent>[];

  late var torrentMap = <String, List<Torrent>>{
    'Downloading metadata...': placeholders,
    'Ungrouped': ungrouped,
  };

  late String saveDir;

  bool get isEmpty => torrentMap.entries.every((e) => e.value.isEmpty);

  void deleteTorrent(Torrent t) {
    assert(!t.isPlaceholder, 'Cannot delete placeholder torrent');
    t.stopSelfUpdate();
    go.DeleteTorrent(t.torrentPtr);
    removeFromMap(t);
    // WatchHistory.remove(t.nameHash);
    gSubscriptionManager.addExclusion(t.nameHash);
  }

  Future<void> downloadItem(RSSItem item) async {
    if (item.torrentUrl == null) {
      throw Exception('Item has no torrent url');
    }
    final url = item.torrentUrl!;
    final placeholder = Torrent.placeholder(item)..coverUrl = item.coverUrl;
    placeholders.add(placeholder);

    await Isolate.spawn((message) {
      // spawn in isolate to avoid blocking main thread
      (message.first as SendPort).send({
        'torrent': jsonDecode.cStringCall(url.startsWith('magnet:')
            ? go.AddMagnet.dartStringCall(url)
            : go.AddTorrent.dartStringCall(url)),
        'infoHash': message[1],
        'coverUrl': message[2],
      });
    }, [recvPort.sendPort, placeholder.infoHash, item.coverUrl]);
  }

  DownloadItem? findItem(String nameHash) {
    for (final group in torrentMap.values) {
      for (final torrent in group) {
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
    }

    return null;
  }

  void pauseTorrent(Torrent t) {
    t.stopSelfUpdate();
    t.isPaused = true;
    // t.updateNotifier.notifyListeners();
    go.PauseTorrent(t.torrentPtr);
  }

  void regroup() {
    torrentMap.remove('Downloading metadata...');
    final flattened = torrentMap.flatten();
    torrentMap = {
      'Downloading metadata...': placeholders,
      'Ungrouped': ungrouped..clear(),
      ...flattened.group(),
    };
  }

  void removeFromMap(Torrent t) {
    if (t.group == null || torrentMap[t.group]?.remove(t) != true) {
      if (!ungrouped.remove(t)) {
        Logger().e('Torrent ${t.name} not found in torrentMap or ungrouped');
      }
    }
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

    if (kIsDesktop) {
      instance.saveDir = kStorage.getString('savePath') ??
          pathlib.join(docDir.path, 'Torrenium');
      await pathlib.join(instance.saveDir, 'data').createDir();
    } else {
      instance.saveDir = pathlib.join(docDir.path, 'Torrenium');
      await instance.saveDir.createDir();
    }

    if (!await Directory(instance.saveDir).exists()) {
      await kStorage.remove('savePath');
      return await init();
    }

    Logger().d('savePath: ${instance.saveDir}');

    final initClientIsolate = ReceivePort();
    await Isolate.spawn((message) {
      go.InitTorrentClient.dartStringCall(message.last as String);
      (message.first as SendPort).send.cStringCall(go.GetTorrentList());
    }, [initClientIsolate.sendPort, instance.saveDir]);

    Logger().d('TorrentClient initialized');

    // load last session
    final session = Torrent.listFromJson(
        await initClientIsolate.firstWhere((e) => e is String));
    session
        .where((t) => !t.isComplete)
        .forEach((t) => go.DeleteMetadata(t.torrentPtr));
    instance.torrentMap
        .addAll(session.where((t) => !t.isComplete).toList().group());

    Logger().d('TorrentManager initialized');
  }

  static onMetadataLoaded(dynamic message) {
    instance.placeholders.removeWhere((t) => t.infoHash == message['infoHash']);
    instance.ungrouped.add(Torrent.fromJson(message['torrent'])
      ..startSelfUpdate()
      ..coverUrl = message['coverUrl']);
    if (instance.placeholders.isEmpty) {
      instance.regroup();
    }
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
