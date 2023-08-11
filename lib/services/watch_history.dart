import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';
import 'storage.dart';

part 'watch_history.g.dart';

enum WatchHistoryEntryType { vnameHasheo, image, audio, all }

List<String> watchHistoryEntryTypeStringKey = [
  'anime',
  'comics',
  'music',
  'all',
];

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
}

@JsonSerializable()
class WatchHistories {
  List<WatchHistoryEntry> value;

  WatchHistories(this.value);

  factory WatchHistories.empty() {
    return WatchHistories([]);
  }

  factory WatchHistories.fromJson(Map<String, dynamic> json) =>
      _$WatchHistoriesFromJson(json);
  Map<String, dynamic> toJson() => _$WatchHistoriesToJson(this);
}

class WatchHistory {
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

  static Future<void> update() async {
    await Storage.setString(_key, jsonEncode(history));
  }

  static Future<void> add(WatchHistoryEntry entry) async {
    final entryIndex =
        history.value.indexWhere((e) => e.nameHash == entry.nameHash);
    if (entryIndex != -1) {
      history.value.removeAt(entryIndex);
    }
    history.value.insert(0, entry);
    await update();
  }

  static Future<void> remove(String nameHash) async {
    history.value.removeWhere((e) => e.nameHash == nameHash);
    await update();
  }

  static Future<void> updateDuration(String nameHash, Duration duration) async {
    final entryIndex = history.value.indexWhere((e) => e.nameHash == nameHash);
    if (entryIndex == -1) {
      debugPrint('WatchHistory.updateDuration: entry not found');
      return;
    }
    history.value[entryIndex].duration = duration.inSeconds;
    await update();
  }

  static Duration getDuration(String nameHash) {
    final entryIndex = history.value.indexWhere((e) => e.nameHash == nameHash);
    if (entryIndex == -1) {
      debugPrint('WatchHistory.getDuration: entry not found');
      return Duration.zero;
    }
    return Duration(seconds: history.value[entryIndex].duration ?? 0);
  }

  /* Image */
  static Future<void> updateIndex(String nameHash, int index) async {
    final entryIndex = history.value.indexWhere((e) => e.nameHash == nameHash);
    if (entryIndex == -1) {
      debugPrint('WatchHistory.updateIndex $nameHash not found');
      return;
    }
    history.value[entryIndex].position = index;
    await update();
  }

  static int getIndex(String nameHash) {
    var index = history.value.indexWhere((e) => e.nameHash == nameHash);
    if (index == -1) {
      debugPrint('WatchHistory.getIndex $nameHash not found');
      return 0;
    }
    index = history.value[index].position ?? 0;
    return index;
  }

  static Future<void> updatePosition(String nameHash, Duration position) async {
    if (position == Duration.zero) {
      return;
    }
    await updateIndex(nameHash, position.inSeconds);
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

  static const _key = 'watch_histories';
  static WatchHistories history = get();
}
