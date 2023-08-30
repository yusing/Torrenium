import 'dart:convert';

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

typedef WatchHistories = Map<String, WatchHistoryEntry>;

class WatchHistory {
  static final _container = ContainerListener<String>('watch_histories');
  static WatchHistories? _histories;

  static WatchHistories get histories => _histories ??= Map.fromIterables(
      WatchHistory._container.keys,
      WatchHistory._container.value.map((e) => WatchHistoryEntry.fromJson(e)));

  static ContainerListener<String> get notifier => _container;

  static Future<void> add(WatchHistoryEntry entry) async {
    histories[entry.id] = entry;
    await _container.write(entry.id, jsonEncode(entry.toJson()));
  }

  static Duration getDuration(String id) {
    return Duration(seconds: histories[id]?.duration ?? 0);
  }

  static int getIndex(String id) {
    return histories[id]?.position ?? 0;
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
    return histories.containsKey(id);
  }

  static Future<void> remove(String id) async {
    histories.remove(id);
    await _container.remove(id);
  }

  static Future<void> updateDuration(String id, Duration duration) async {
    histories[id]?.duration = duration.inSeconds;
    await updateHistory(id);
  }

  static Future<void> updateHistory(String id) async {
    await _container.write(id, jsonEncode(histories[id]?.toJson()));
  }

  /* Image */
  static Future<void> updateIndex(String id, int index) async {
    histories[id]?.position = index;
    await updateHistory(id);
  }

  static Future<void> updatePosition(String id, Duration position) async {
    if (position == Duration.zero) {
      return;
    }
    await updateIndex(id, position.inSeconds);
  }
}

@JsonSerializable()
class WatchHistoryEntry extends DownloadItem
    implements Comparable<WatchHistoryEntry> {
  @JsonKey(defaultValue: null)
  String? path;
  @JsonKey(defaultValue: null)
  String? audioPath;
  int? duration; // video/music duration in seconds, or index for image
  int? position; // video/music position in seconds, or pages for images
  int lastWatchedTimestamp = DateTime.now().millisecondsSinceEpoch;

  WatchHistoryEntry(
      {required super.name,
      this.path,
      this.audioPath,
      this.duration,
      this.position});

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
  int compareTo(WatchHistoryEntry other) {
    return lastWatchedTimestamp.compareTo(other.lastWatchedTimestamp);
  }

  @override
  Map<String, dynamic> toJson() => _$WatchHistoryEntryToJson(this);
}

enum WatchHistoryEntryType { video, image, audio, all }
