import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:torrenium/classes/download_item.dart';
import 'package:torrenium/services/torrent.dart';

import 'storage.dart';

part 'watch_history.g.dart';

List<String> watchHistoryEntryTypeStringKey = [
  'anime',
  'comics',
  'music',
  'all',
];

class WatchHistories {
  LinkedHashMap<String, WatchHistoryEntry> map;

  WatchHistories(this.map);

  factory WatchHistories.empty() {
    return WatchHistories(LinkedHashMap<String, WatchHistoryEntry>());
  }

  factory WatchHistories.fromJson(Map<String, dynamic> json) =>
      WatchHistories(LinkedHashMap.from(json.map((key, value) => MapEntry(
          key, WatchHistoryEntry.fromJson(value as Map<String, dynamic>)))));

  int get length => map.length;

  WatchHistoryEntry? operator [](String key) => map[key];
  WatchHistoryEntry elementAt(int index) => map.values.elementAt(index);

  Map<String, dynamic> toJson() =>
      map.map((key, value) => MapEntry(key, value.toJson()));
}

class WatchHistory {
  static const _key = 'watch_histories';

  static ValueNotifier notifier = ValueNotifier(null);
  static WatchHistories list = get();

  static Future<void> add(WatchHistoryEntry entry) async {
    list.map.remove(entry.nameHash);
    list.map[entry.nameHash] = entry;
    await update();
  }

  static WatchHistories get() {
    final json = Storage.getString(_key);
    if (json == null) return WatchHistories.empty();
    try {
      return WatchHistories.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint(e.toString());
      return WatchHistories.empty();
    }
  }

  static Duration getDuration(String nameHash) {
    return Duration(seconds: list.map[nameHash]?.duration ?? 0);
  }

  static int getIndex(String nameHash) {
    return list.map[nameHash]?.position ?? 0;
  }

  static Duration getPosition(String nameHash) {
    return Duration(seconds: getIndex(nameHash));
  }

  static double getProgress(String nameHash) {
    final duration = getDuration(nameHash);
    if (duration == Duration.zero) {
      return 0;
    }
    final position = getPosition(nameHash);
    return position.inSeconds / duration.inSeconds;
  }

  static Future<void> remove(String nameHash) async {
    list.map.remove(nameHash);
    await update();
  }

  static Future<void> update() async {
    await Storage.setString(_key, jsonEncode(list));
    notifier.notifyListeners();
  }

  static Future<void> updateDuration(String nameHash, Duration duration) async {
    list.map[nameHash]?.duration = duration.inSeconds;
    await update();
  }

  /* Image */
  static Future<void> updateIndex(String nameHash, int index) async {
    list.map[nameHash]?.position = index;
    await update();
  }

  static Future<void> updatePosition(String nameHash, Duration position) async {
    if (position == Duration.zero) {
      return;
    }
    await updateIndex(nameHash, position.inSeconds);
  }
}

@JsonSerializable()
class WatchHistoryEntry {
  final String nameHash;
  String title;
  int? duration; // vnameHasheo/music duration in seconds, or index for image
  int? position; // vnameHasheo/music position in seconds, or pages for images

  WatchHistoryEntry(
      {required this.nameHash,
      required this.title,
      this.duration,
      this.position});

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryEntryFromJson(json);
  Map<String, dynamic> toJson() => _$WatchHistoryEntryToJson(this);

  double get progress {
    if (duration == null || duration == 0) {
      return 0;
    }
    if (position == null) {
      return 0;
    }
    return position! / duration!;
  }

  DownloadItem get item {
    // find any torrent with this nameHash
    // otherwise search for all multi-file torrents and return the file with the nameHash

    return gTorrentManager.torrentList
        .cast()
        .firstWhere((t) => t.nameHash == nameHash, orElse: () {
      final torrent = gTorrentManager.torrentList.firstWhere(
          (t) => t.isMultiFile && t.files.any((f) => f.nameHash == nameHash),
          orElse: () => throw Exception('Torrent not found'));
      return torrent.files.firstWhere((f) => f.nameHash == nameHash);
    });
  }
}

enum WatchHistoryEntryType { vnameHasheo, image, audio, all }
