import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'package:ffi/ffi.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:torrenium/classes/item.dart';
import 'package:torrenium/utils/units.dart';
import 'torrent_binding.dart' as torrent_binding;
import 'package:shared_preferences/shared_preferences.dart';

class Torrent implements Comparable<Torrent> {
  Torrent(
      {required this.name,
      required this.infoHash,
      required this.size,
      required this.torrentPtr,
      required this.progress,
      required this.bytesDownloaded,
      required this.bytesDownloadedInitial});

  final String name;
  final String infoHash;
  final int size;
  final List<TorrentDownloadedFile> files = [];
  Pointer<Void> torrentPtr;
  int bytesDownloadedInitial;
  bool paused = false;
  num progress;
  int bytesDownloaded;
  ValueNotifier stateNotifier = ValueNotifier(false);
  Timer? _updateTimer;
  DateTime _startTime = DateTime.now();
  DateTime? _downloadedTime;

  bool get isComplete => progress == 1.0;
  bool get isMultiFile => files.length > 1;
  DateTime get downloadedTime {
    // lazy load
    _downloadedTime ??=
        FileStat.statSync(path.join(TorrentManager.savePath, name)).modified;
    return _downloadedTime!;
  }

  double get etaSecs {
    if (progress == 0) {
      return double.infinity;
    }
    return (DateTime.now().difference(_startTime).inSeconds *
            (1 - progress) /
            progress)
        .toDouble();
  }

  void startSelfUpdate() {
    _updateTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (progress == 1.0 && bytesDownloaded != 0) {
        return;
      }
      if (!paused) {
        // return; // Don't update if not in download page or torrent is paused
        Torrent tNewer = TorrentManager.getTorrentInfo(this);
        if (progress != tNewer.progress) {
          progress = tNewer.progress;
          bytesDownloaded = tNewer.bytesDownloaded;
          _downloadedTime = DateTime.now();
          for (int i = 0; i < files.length; i++) {
            assert(files[i].name == tNewer.files[i].name);
            files[i] = tNewer.files[i];
          }
        }
      }
      stateNotifier.value = !stateNotifier.value;
    });
  }

  void stopSelfUpdate() {
    _updateTimer?.cancel();
    _updateTimer = null;
  }

  void print() {
    Logger().i(
        "Torrent: name: $name\ninfoHash: $infoHash\nsize: ${size.humanReadableUnit}\nprogress: ${progress.percentageUnit}");
  }

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
      torrent.files.add(TorrentDownloadedFile.fromJson(file));
    }
    return torrent;
  }

  static List<Torrent> listFromJson(String jsonStr) {
    final json = jsonDecode(jsonStr);
    if (json == null) {
      return [];
    }
    final torrents = <Torrent>[];
    for (final torrent in json) {
      torrents.add(Torrent.fromJson(torrent));
    }
    return torrents;
  }

  @override
  int compareTo(Torrent other) {
    // list folders first then sort by downloaded time
    if (files.length > 1 && other.files.length == 1) {
      return -1;
    } else if (files.length == 1 && other.files.length > 1) {
      return 1;
    } else {
      return other.downloadedTime.compareTo(downloadedTime); // descending
    }
  }
}

class TorrentDownloadedFile {
  final String name;
  final int size;
  final String relativePath;
  int bytesDownloaded;
  num progress;

  TorrentDownloadedFile({
    required this.name,
    required this.size,
    required this.relativePath,
    required this.bytesDownloaded,
    required this.progress,
  });

  factory TorrentDownloadedFile.fromJson(dynamic json) {
    if (json is String) {
      json = jsonDecode(json);
    }
    if (json == null) {
      return TorrentDownloadedFile(
          name: '', size: 0, relativePath: '', bytesDownloaded: 0, progress: 0);
    }
    return TorrentDownloadedFile(
      name: json['name'],
      size: json['size'],
      relativePath: json['rel_path'],
      bytesDownloaded:
          json['bytes_downloaded'] ?? json['progress'] * json['size'],
      progress: json['progress'],
    );
  }
}

class TorrentManager {
  static final DynamicLibrary _dylib = DynamicLibrary.open('libtorrent_go.dll');
  static final _torrent = torrent_binding.TorrentGoBinding(_dylib);
  static late List<Torrent> torrentList;
  static late Directory docDir;
  static late String savePath;
  static late SharedPreferences prefs;

  static Future<bool> init() async {
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
    _torrent.InitTorrentClient.callWith(savePath);

    // load last session
    torrentList = Torrent.listFromJson.callWith(_torrent.GetTorrentList());
    torrentList.sort();
    for (final torrent in torrentList) {
      torrent.startSelfUpdate();
    }
    return true;
  }

  static Future<bool> selectSavePath() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a save path',
      initialDirectory: docDir.path,
      lockParentWindow: true,
    );
    if (selectedPath == null) {
      return false;
    }
    prefs.setString('savePath', selectedPath);
    return true;
  }

  static Torrent getTorrentInfo(Torrent t) {
    return Torrent.fromJson(
        jsonDecode.callWith(_torrent.GetTorrentInfo(t.torrentPtr)));
  }

  static void download(Item item,
      {required BuildContext context, bool pop = false}) {
    if (item.magnetUrl != null) {
      TorrentManager.addMagnet(item.magnetUrl!);
      if (pop) Navigator.pop(context);
    } else if (item.torrentUrl != null) {
      TorrentManager.addTorrent(item.torrentUrl!);
      if (pop) Navigator.pop(context);
    } else {
      Logger().w('Item has no magnet or torrent url');
      showMacosAlertDialog(
          context: context,
          builder: (context) {
            return MacosAlertDialog(
              title: const Text('Error'),
              message: const Text('No torrent link found'),
              appIcon: const SizedBox(), // TODO: replace this
              primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            );
          });
    }
  }

  static void addTorrent(String torrentUrl) {
    torrentList.add(Torrent.fromJson(
        jsonDecode.callWith(_torrent.AddTorrent.callWith(torrentUrl)))
      ..startSelfUpdate());
  }

  static void addMagnet(String magnetUrl) async {
    ReceivePort isolateToMain = ReceivePort();
    isolateToMain.listen((message) {
      torrentList.add(Torrent.fromJson(message)..startSelfUpdate());
    });
    await Isolate.spawn((message) {
      message.send(jsonDecode.callWith(_torrent.AddMagnet.callWith(magnetUrl)));
    }, isolateToMain.sendPort);
  }

  static void pauseTorrent(Torrent t) {
    t.stopSelfUpdate();
    t.paused = true;
    _torrent.PauseTorrent(t.torrentPtr);
  }

  static void resumeTorrent(Torrent t) {
    t.paused = false;
    t.torrentPtr =
        Pointer<Void>.fromAddress(_torrent.ResumeTorrent.callWith(t.infoHash));
    t.bytesDownloadedInitial = t.bytesDownloaded;
    t._startTime = DateTime.now();
    t.startSelfUpdate();
  }

  static void deleteTorrent(Torrent t) {
    t.stopSelfUpdate();
    _torrent.DeleteTorrent(t.torrentPtr);
    torrentList.remove(t);
  }
}

extension NativeStringTCallback<T> on T Function(Pointer<Char>) {
  T callWith(String s) {
    Pointer<Char> cStr = s.toNativeUtf8().cast<Char>();
    assert(cStr != nullptr);
    T result = this(cStr);
    calloc.free(cStr);
    return result;
  }
}

extension DartStringTCallback<T> on T Function(String) {
  T callWith(Pointer<Char> cStr) {
    assert(cStr != nullptr);
    T result = this(cStr.cast<Utf8>().toDartString());
    TorrentManager._torrent.FreeCString(cStr);
    return result;
  }
}
