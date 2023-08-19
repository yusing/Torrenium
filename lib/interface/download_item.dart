import 'package:flutter/widgets.dart';

import '../services/watch_history.dart';
import '../utils/file_type_icons.dart';
import '../utils/string.dart';
import 'groupable.dart';

abstract class DownloadItem extends Groupable {
  int bytesDownloaded;
  num progress;

  DownloadItem(
      {required super.name,
      required this.bytesDownloaded,
      required this.progress});

  String get displayName;
  List<DownloadItem> get files => throw UnimplementedError();
  String get fullPath;
  IconData get icon => getPathIcon(fullPath);
  bool get isComplete;
  bool get isMultiFile;
  bool get isPlaceholder;
  Duration get lastPosition => WatchHistory.getPosition(nameHash);

  String get nameHash => displayName.sha256Hash;
  double get watchProgress => WatchHistory.getProgress(nameHash);

  void delete();
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
