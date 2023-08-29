import 'dart:collection';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

import '/interface/download_item.dart';
import '/interface/groupable.dart';
import 'storage.dart';
import 'torrent_mgr.dart';

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
  static WatchHistories histories = get();

  static Future<void> add(WatchHistoryEntry entry) async {
    histories.map.remove(entry.id);
    histories.map[entry.id] = entry;
    await update();
  }

  static WatchHistories get() {
    final json = kStorage.getString(_key);
    if (json == null) return WatchHistories.empty();
    try {
      return WatchHistories.fromJson(jsonDecode(json));
    } catch (e) {
      debugPrint(e.toString());
      return WatchHistories.empty();
    }
  }

  static Duration getDuration(String id) {
    return Duration(seconds: histories.map[id]?.duration ?? 0);
  }

  static int getIndex(String id) {
    return histories.map[id]?.position ?? 0;
  }

  static Duration getPosition(String id) {
    return Duration(seconds: getIndex(id));
  }

  static double getProgress(String id) {
    final duration = getDuration(id);
    if (duration == Duration.zero) {
      return 0;
    }
    final position = getPosition(id);
    return position.inSeconds / duration.inSeconds;
  }

  static bool has(String id) {
    return histories.map.containsKey(id);
  }

  static Future<void> remove(String id) async {
    histories.map.remove(id);
    await update();
  }

  static Future<void> update() async {
    await kStorage.setString(_key, jsonEncode(histories));
    notifier.notifyListeners();
  }

  static Future<void> updateDuration(String id, Duration duration) async {
    histories.map[id]?.duration = duration.inSeconds;
    await update();
  }

  /* Image */
  static Future<void> updateIndex(String id, int index) async {
    histories.map[id]?.position = index;
    await update();
  }

  static Future<void> updatePosition(String id, Duration position) async {
    if (position == Duration.zero) {
      return;
    }
    await updateIndex(id, position.inSeconds);
  }
}

@JsonSerializable()
class WatchHistoryEntry extends DownloadItem {
  @JsonKey(defaultValue: null)
  String? path;
  @JsonKey(defaultValue: null)
  String? audioPath;
  int? duration; // video/music duration in seconds, or index for image
  int? position; // video/music position in seconds, or pages for images

  WatchHistoryEntry({
    required super.name,
    this.path,
    this.audioPath,
    this.duration,
    this.position,
  });

  factory WatchHistoryEntry.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoryEntryFromJson(json);

  @override
  String? get audioTrackPath => audioPath;

  @override
  bool get isComplete => true;

  @override
  bool get isMultiFile => false;

  @override
  bool get isPlaceholder => false;

  @override
  double get progress {
    if (duration == null || duration == 0) {
      return 0;
    }
    if (position == null) {
      return 0;
    }
    return position! / duration!;
  }

  @override
  String get videoPath => path ?? gTorrentManager.findItem(id)?.videoPath ?? '';

  @override
  Map<String, dynamic> toJson() => _$WatchHistoryEntryToJson(this);
}

enum WatchHistoryEntryType { video, image, audio, all }
