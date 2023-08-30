import 'package:json_annotation/json_annotation.dart';

import '/interface/download_item.dart';
import '/interface/groupable.dart';
import 'storage.dart';
import 'torrent_mgr.dart';

part 'watch_history.g.dart';

typedef WatchHistories = Map<String, WatchHistoryEntry>;

class WatchHistory {
  static final _container = ContainerListener<WatchHistoryEntry>(
      'watch_histories',
      decoder: (e) => WatchHistoryEntry.fromJson(e),
      encoder: (e) => e.toJson());

  static WatchHistories? _histories;

  static WatchHistories get histories =>
      _histories ??= Map.fromEntries(_container.value);

  static ContainerListener<WatchHistoryEntry> get notifier => _container;

  static Future<void> add(WatchHistoryEntry entry) async {
    histories[entry.id] = entry;
    await _container.write(entry.id, entry);
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

  static Future<void> init() async {
    await _container.init();
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
    await _container.write(id, histories[id]!);
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
