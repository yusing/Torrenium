import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:json_annotation/json_annotation.dart';

import '/main.dart' show kIsDesktop;
import '/pages/video_player.dart';
import '/services/watch_history.dart';
import '/utils/file_types.dart';
import '/utils/fs.dart';
import '/widgets/adaptive.dart';
import 'groupable.dart';

part 'download_item.g.dart';

@JsonSerializable()
class DownloadItem extends Groupable {
  @JsonKey(includeToJson: false, includeFromJson: false)
  int bytesDownloaded, size;
  @JsonKey(includeToJson: false, includeFromJson: false)
  num progress;
  @JsonKey(includeToJson: false, includeFromJson: false)
  bool isHidden = false;
  @JsonKey(includeToJson: false, includeFromJson: false)
  DateTime startTime;

  DownloadItem(
      {required super.name,
      super.parent,
      this.progress = 0.0,
      this.bytesDownloaded = 0,
      this.size = 0})
      : startTime = DateTime.now();

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  String? get audioTrackPath => null;

  String get displayName =>
      isMultiFile ? '$nameCleaned (${files.length} items)' : nameCleaned;

  double get etaSecs => progress == 0
      ? double.infinity
      : (DateTime.now()
                  .difference((parent as DownloadItem?)?.startTime ?? startTime)
                  .inSeconds *
              (1 - progress) /
              progress)
          .toDouble();

  bool get exists => File(videoPath).existsSync();
  Map<String, String> get externalSubtitlePaths => {}; // TODO: test

  String? get externalSubtitltFontPath => null; // TODO: test
  List<DownloadItem> get files => throw UnimplementedError();
  // IconData get icon => getPathIcon(videoPath);
  bool get isComplete => progress == 1.0;
  bool get isMultiFile => false;
  bool get isPlaceholder => false;
  bool get isUrl => videoPath.startsWith('https://');
  Duration get lastPosition => WatchHistory.getPosition(id);

  double get watchProgress => WatchHistory.getProgress(id);

  Future<void> delete() async {
    isHidden = true;

    if (isMultiFile) {
      await videoPath.deleteDir();
    } else {
      await videoPath.deleteFile();
    }
  }

  Future<void> open() async {
    // TODO: handle for different file type
    if (!isUrl) {
      if (!(File(videoPath).existsSync())) {
        Get.snackbar('File not found', videoPath);
        return;
      }
      if (FileTypeExt.from(videoPath) != FileType.video) {
        Get.snackbar(
            'File type not supported', FileTypeExt.from(videoPath).name);
        return;
      }
    }

    await showVideoPlayer();
  }

  Future<void> showVideoPlayer() async {
    if (kIsDesktop) {
      await showAdaptivePopup(builder: (context) => VideoPlayerPage(this));
    } else {
      Get.to(() => CupertinoPageScaffold(
          navigationBar: CupertinoNavigationBar(
            middle: Text(
              name,
              overflow: TextOverflow.ellipsis,
              softWrap: true,
              maxLines: 2,
            ),
          ),
          child: SafeArea(child: VideoPlayerPage(this))));
    }
  }

  @override
  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);

  Future<void> updateWatchPosition(Duration pos) async =>
      await WatchHistory.updatePosition(id, pos);
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
