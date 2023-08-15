import '../services/watch_history.dart';
import '../utils/string.dart';

abstract class DownloadItem {
  String get displayName;
  String get fullPath;

  Duration get lastPosition => WatchHistory.getPosition(nameHash);
  String get nameHash => displayName.sha256Hash;
  double get watchProgress => WatchHistory.getProgress(nameHash);

  void delete();
  Future<void> updateWatchPosition(Duration pos) async =>
      await WatchHistory.updatePosition(nameHash, pos);
}
