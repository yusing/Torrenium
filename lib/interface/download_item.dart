import 'package:json_annotation/json_annotation.dart';

import '/services/watch_history.dart';
import '/utils/fs.dart';
import 'groupable.dart';

part 'download_item.g.dart';

@JsonSerializable()
class DownloadItem extends Groupable {
  @JsonKey(includeToJson: false, includeFromJson: false)
  int bytesDownloaded, size;
  @JsonKey(includeToJson: false, includeFromJson: false)
  num progress;
  @JsonKey(includeToJson: false, includeFromJson: false)
  bool deleted = false;
  @JsonKey(includeToJson: false, includeFromJson: false)
  final DateTime _startTime;

  DownloadItem(
      {required super.name,
      super.parent,
      this.progress = 0.0,
      this.bytesDownloaded = 0,
      this.size = 0})
      : _startTime = DateTime.now();

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  String? get audioTrackPath => null;

  String get displayName => nameCleaned;

  double get etaSecs => progress == 0
      ? double.infinity
      : (DateTime.now().difference(_startTime).inSeconds *
              (1 - progress) /
              progress)
          .toDouble();

  Map<String, String> get externalSubtitlePaths => {}; // TODO: test
  String? get externalSubtitltFontPath => null; // TODO: test

  List<DownloadItem> get files => throw UnimplementedError();
  // IconData get icon => getPathIcon(videoPath);
  bool get isComplete => progress == 1.0;
  bool get isMultiFile => false;
  bool get isPlaceholder => false;
  Duration get lastPosition => WatchHistory.getPosition(nameHash);

  double get watchProgress => WatchHistory.getProgress(nameHash);

  Future<void> delete() async {
    deleted = true;

    if (isMultiFile) {
      await videoPath.deleteDir();
    } else {
      await videoPath.deleteFile();
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
