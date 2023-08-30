import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/interface/download_item.dart';
import '/services/watch_history.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';

class VideoPlayerPage extends StatefulWidget {
  final DownloadItem item;

  const VideoPlayerPage(this.item, {super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final controller = VideoController(Player(
      configuration: PlayerConfiguration(
          osc: true,
          title: widget.item.nameCleaned,
          logLevel: kDebugMode ? MPVLogLevel.debug : MPVLogLevel.error,
          ready: onReady,
          libass: true,
          bufferSize: 4 * 1024 * 1024,
          libassAndroidFont: item.externalSubtitltFontPath)));

  late final media = Media(widget.item.videoPath);

  late final StreamSubscription<void> positionSub;
  late final StreamSubscription<bool> playbackEndSub;

  DownloadItem get item => widget.item;

  Player get player => controller.player;

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller, // TODO: implement controls
    );
  }

  @override
  void dispose() {
    positionSub.cancel();
    playbackEndSub.cancel();
    player.stop().then((_) => player.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    player.open(media).then((_) async {
      if (item.audioTrackPath != null) {
        await player.setAudioTrack(
            AudioTrack.uri(item.audioTrackPath!, title: 'external audio'));
      }
      if (item.externalSubtitlePaths.isNotEmpty) {
        await player.setSubtitleTrack(SubtitleTrack.uri(
            item.externalSubtitlePaths.values.first,
            language: item.externalSubtitlePaths.keys.first,
            title: item.externalSubtitlePaths.keys.first));
      }
    });
  }

  Future<void> onReady() async {
    await player.stream.duration
        .firstWhere((d) => d.inSeconds > 0)
        .then((_) async {
      if (WatchHistory.has(item.id)) {
        await player.seek(item.lastPosition);
        Get.snackbar('Resuming from ${item.lastPosition.toStringNoMs()}', '');
        Logger().d('Restoring position to ${item.lastPosition}');
      }
      // add even if already exists to push to top
      await WatchHistory.add(WatchHistoryEntry(
          name: item.name,
          path: item.videoPath,
          audioPath: item.audioTrackPath,
          duration: player.state.duration.inSeconds,
          position: player.state.position.inSeconds));
    });
    positionSub = Stream.periodic(2.seconds).listen((_) {
      widget.item.updateWatchPosition(player.state.position);
    });

    playbackEndSub = player.stream.completed.listen((event) {
      if (event && item.watchProgress >= .85) {
        showAdaptiveAlertDialog(
                title: const Text('Seems like finished watching'),
                content: const Text('Delete?'),
                confirmLabel: 'YES',
                onConfirm: item.delete,
                onConfirmStyle:
                    const TextStyle(color: CupertinoColors.destructiveRed),
                cancelLabel: 'NO')
            .then((_) => Get.back(closeOverlays: true));
      }
    });
  }
}
