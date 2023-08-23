import 'dart:io';

import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';

import '/services/storage.dart';
import '/services/watch_history.dart';
import '/services/youtube.dart';
import '/utils/file_type_icons.dart';
import '/utils/string.dart';
import '/widgets/cached_image.dart';
import 'groupable.dart';

abstract class DownloadItem extends Groupable {
  @JsonKey(includeToJson: false, includeFromJson: false)
  int bytesDownloaded;
  @JsonKey(includeToJson: false, includeFromJson: false)
  num progress;
  @JsonKey(includeToJson: false, includeFromJson: false)
  String? _coverUrl;
  @JsonKey(includeToJson: false, includeFromJson: false)
  CachedImage? _coverImageWidget;

  DownloadItem(
      {required super.name, this.bytesDownloaded = 0, this.progress = 0});
  String? get audioTrackPath => null;
  String? get coverUrl => _coverUrl ??= Storage.getString('cover-$nameHash');

  set coverUrl(String? url) {
    if (url == null) {
      return;
    }
    _coverUrl = url;
    Storage.setStringIfNotExists('cover-$nameHash', url);
  }

  String get displayName => nameCleaned;
  Map<String, String> get externalSubtitlePaths => {}; // TODO: test

  String? get externalSubtitltFontPath => null; // TODO: test
  List<DownloadItem> get files => throw UnimplementedError();
  IconData get icon => getPathIcon(videoPath);
  bool get isComplete;
  bool get isMultiFile;
  bool get isPlaceholder;

  Duration get lastPosition => WatchHistory.getPosition(nameHash);
  String get nameHash => name.sha256Hash;
  String get videoPath;
  double get watchProgress => WatchHistory.getProgress(nameHash);

  CachedImage coverImageWidget() => _coverImageWidget ??= CachedImage(
        url: coverUrl,
        fallbackGetter: defaultCoverUrlFallback,
        height: 50,
        fit: BoxFit.contain,
      );

  Future<String?> defaultCoverUrlFallback() async {
    final coverUrl = await YouTube.search(title).then(
        (value) => value.isEmpty ? null : value.first.items.first.coverUrl);
    this.coverUrl ??= coverUrl;
    return coverUrl;
  }

  void delete() {
    if (isMultiFile) {
      Directory(videoPath).deleteSync(recursive: true);
    } else {
      File(videoPath).deleteSync();
    }
  }

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
