import 'dart:async';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart' hide Playable;
import 'package:media_kit_video/media_kit_video.dart';

import '/interface/playable.dart';
import '/services/watch_history.dart';
import '/utils/show_snackbar.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';

class VideoPlayerPage extends StatefulWidget {
  final Playable video;

  VideoPlayerPage(this.video) : super(key: ValueKey(video.id));

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late final controller = VideoController(Player(
      configuration: PlayerConfiguration(
          osc: true,
          title: widget.video.displayName,
          logLevel: kDebugMode ? MPVLogLevel.debug : MPVLogLevel.error,
          ready: onReady,
          libass: true,
          libassAndroidFont: video.externalSubtitltFontPath)));

  late final media = Media(widget.video.fullPath);

  StreamSubscription<void>? positionSub;
  StreamSubscription<bool>? playbackEndSub;

  Playable get video => widget.video;

  Player get player => controller.player;

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      controls: controls,
    );
  }

  @override
  void dispose() {
    positionSub?.cancel();
    playbackEndSub?.cancel();
    player.stop().then((_) => player.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    Logger().d('Playing video from ${media.uri}');
    player.open(media).then((_) async {
      if (video.audioTrackPath != null) {
        await player.setAudioTrack(
            AudioTrack.uri(video.audioTrackPath!, title: 'external audio'));
      }
      if (video.externalSubtitlePaths.isNotEmpty) {
        await player.setSubtitleTrack(SubtitleTrack.uri(
            video.externalSubtitlePaths.values.first,
            language: video.externalSubtitlePaths.keys.first,
            title: video.externalSubtitlePaths.keys.first));
      }
    });
  }

  Future<void> onReady() async {
    await player.stream.duration
        .firstWhere((d) => d.inSeconds > 0)
        .then((_) async {
      if (WatchHistory.has(video.id)) {
        await player.seek(video.lastPosition);
        showSnackBar('Resuming from ${video.lastPosition.toStringNoMs()}', '');
        Logger().d('Restoring position to ${video.lastPosition}');
      }
      // add even if already exists to push to top
      await WatchHistory.add(WatchHistoryEntry(
          name: video.displayName,
          path: video.fullPath,
          audioPath: video.audioTrackPath,
          duration: player.state.duration.inSeconds,
          position: player.state.position.inSeconds));
    });
    positionSub = Stream.periodic(2.seconds).listen((_) {
      widget.video.updateWatchPosition(player.state.position);
    });

    playbackEndSub = player.stream.completed.listen((event) {
      if (event && video.watchProgress >= .85) {
        showAdaptiveAlertDialog(
                title: const Text('Seems like finished watching'),
                content: const Text('Delete?'),
                confirmLabel: 'YES',
                onConfirm: video.delete,
                onConfirmStyle:
                    const TextStyle(color: CupertinoColors.destructiveRed),
                cancelLabel: 'NO')
            .then((_) => Get.back(closeOverlays: true));
      }
    });
  }

  Widget controls(VideoState state) {
    // TODO: implement controls
    return AdaptiveVideoControls(state);
  }
}
