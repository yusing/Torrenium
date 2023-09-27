import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';

import '/main.dart' show kIsDesktop;
import '/pages/video_player.dart';
import '/services/watch_history.dart';
import '/widgets/adaptive.dart';

abstract mixin class Playable {
  String? get audioTrackPath => null;
  String get displayName;
  Map<String, String> get externalSubtitlePaths => {}; // TODO: test
  String? get externalSubtitltFontPath => null; // TODO: test
  String get fullPath;
  String get id;
  Duration get lastPosition => WatchHistory.getPosition(id);
  double get watchProgress => WatchHistory.getProgress(id);

  Future<void> delete() async => throw UnimplementedError();

  Future<void> showVideoPlayer() async {
    if (kIsDesktop) {
      await showAdaptivePopup(builder: (context) => VideoPlayerPage(this));
    } else {
      await Get.to(() => SafeArea(child: VideoPlayerPage(this)),
          preventDuplicates: false);
    }
  }

  Future<void> updateWatchPosition(Duration pos) async =>
      await WatchHistory.updatePosition(id, pos);
}
