import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';

import 'package:collection/collection.dart';
import 'package:ffi/ffi.dart';
import 'package:flutter/widgets.dart';
import 'package:logger/logger.dart';
import 'package:path/path.dart' as pathlib;
import 'package:path_provider/path_provider.dart';

import '/class/torrent.dart';
import '/class/torrent_rss_item.dart';
import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/utils/fs.dart';
import 'go_torrent.dart';
import 'storage.dart';

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

  var ungrouped = <Torrent>[];

  final hideDownloaded = ValueNotifier(false);

  late final _torrentMap = <String, List<Torrent>>{
    'Ungrouped': ungrouped,
  };

  late String saveDir;

  late String dataDir;

  bool get isEmpty {
    return TorrentPlaceHolder.map.isEmpty &&
        _torrentMap.entries
            .every((e) => e.value.isEmpty || e.value.every((t) => t.isHidden));
  }

  Map<String, List<Torrent>> get torrentMap {
    return {
      ..._torrentMap,
      'Downloading metadata...:':
          List.unmodifiable(TorrentPlaceHolder.map.values)
    };
  }

  double get totalProgress {
    final inProgress =
        Torrent.map.values.where((e) => e.progress < 1).map((e) => e.progress);

    return inProgress.isEmpty
        ? 100
        : inProgress.average.clamp(0.0, 1.0) * 100.0;
  }

  Future<void> downloadItem(TorrentRSSItem item) async {
    if (item.torrentUrl == null) {
      throw Exception('Item has no torrent url');
    }
    final url = item.torrentUrl!;
    final placeholder = TorrentPlaceHolder.create(item)
      ..coverUrl = item.coverUrl;

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

  DownloadItem? findItem(String id) {
    for (final t in Torrent.map.values) {
      if (t.isMultiFile) {
        for (final file in t.files) {
          if (file.id == id) {
            return file;
          }
        }
      }
      if (t.id == id) {
        return t;
      }
    }

    return null;
  }

  void regroup() {
    _torrentMap.remove('Downloading metadata...');
    ungrouped.clear();
    _torrentMap.clear();
    _torrentMap['Ungrouped'] = ungrouped;
    _torrentMap.addAll(Torrent.map.values.toList(growable: false).group());
  }

  void removeFromMap(Torrent t) {
    assert(t is! TorrentPlaceHolder);

    if (t.group == null || torrentMap[t.group]?.remove(t) != true) {
      if (!ungrouped.remove(t)) {
        Logger().e('Torrent ${t.name} not found in torrentMap or ungrouped');
        return;
      }
    }

    if (torrentMap[t.group]?.isEmpty == true) {
      torrentMap.remove(t.group);
    }
  }

  void setDownloadedHidden(bool hideDownloaded) {
    for (var t in Torrent.map.values) {
      t.isHidden = t.isComplete && hideDownloaded;
      // Logger().d('${t.name} hidden? ${t.isHidden}');
    }
    this.hideDownloaded.value = hideDownloaded;
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

    instance.saveDir = pathlib.join(docDir.path, 'Torrenium');
    instance.dataDir = pathlib.join(instance.saveDir, 'data');
    await instance.saveDir.createDir();
    await instance.dataDir.createDir();

    if (!await Directory(instance.saveDir).exists()) {
      await gStorage.remove('savePath');
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
    instance.ungrouped.addAll(session..forEach((t) => t.startSelfUpdate()));
    if (instance.hideDownloaded.value) {
      instance.setDownloadedHidden(true);
    }
    instance.regroup();

    Logger().d('TorrentManager initialized');
  }

  static onMetadataLoaded(dynamic message) {
    TorrentPlaceHolder.map.remove(message['infoHash']);
    instance.ungrouped.add(Torrent.fromJson(message['torrent'])
      ..startSelfUpdate()
      ..coverUrl = message['coverUrl']);
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
