import 'dart:io';

import 'package:json_annotation/json_annotation.dart';

import '/services/watch_history.dart';
import 'groupable.dart';

part 'download_item.g.dart';

@JsonSerializable()
class DownloadItem extends Groupable {
  @JsonKey(includeToJson: false, includeFromJson: false)
  int bytesDownloaded;
  @JsonKey(includeToJson: false, includeFromJson: false)
  num progress;
  @JsonKey(includeToJson: false, includeFromJson: false)
  bool deleted = false;

  DownloadItem(
      {required super.name,
      super.parent,
      this.bytesDownloaded = 0,
      this.progress = 0});

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  String? get audioTrackPath => null;

  String get displayName => nameCleaned;

  Map<String, String> get externalSubtitlePaths => {}; // TODO: test
  String? get externalSubtitltFontPath => null; // TODO: test

  List<DownloadItem> get files => throw UnimplementedError();
  // IconData get icon => getPathIcon(videoPath);
  bool get isComplete => progress == 1.0;
  bool get isMultiFile => false;
  bool get isPlaceholder => false;
  Duration get lastPosition => WatchHistory.getPosition(nameHash);

  String get videoPath => throw UnimplementedError();
  double get watchProgress => WatchHistory.getProgress(nameHash);

  void delete() {
    deleted = true;
    updateNotifier.notifyListeners();

    if (isMultiFile) {
      Directory(videoPath).deleteSync(recursive: true);
    } else {
      File(videoPath).deleteSync();
    }
  }

  @override
  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);

  Future<void> updateWatchPosition(Duration pos) async =>
      await WatchHistory.updatePosition(nameHash, pos);
}

extension SortHelper<T extends DownloadItem> on Map<String, List<T>> {
  List<MapEntry<String, List<T>>> sortedGroup() =>
      entries.toList(growable: false)
        ..sort((a, b) {
          if (a.value.length == 1 && a.value.first.isMultiFile) {
            return -1;
          }
          if (b.value.length == 1 && b.value.first.isMultiFile) {
            return 1;
          }
          return a.key.compareTo(b.key);
        });
}
