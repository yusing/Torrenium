import 'dart:async';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:media_kit/media_kit.dart';
import 'package:media_kit_video/media_kit_video.dart';

import '/interface/download_item.dart';
import '/services/watch_history.dart';
import '/utils/string.dart';
import 'adaptive.dart';

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
          libassAndroidFont: item.externalSubtitltFontPath)));

  late final media = Media(widget.item.fullPath);

  late final StreamSubscription<void> positionSub;
  late final StreamSubscription<bool> playbackEndSub;

  DownloadItem get item => widget.item;

  Player get player => controller.player;

  @override
  Widget build(BuildContext context) {
    return Video(
      controller: controller,
      controls: MaterialDesktopVideoControls, // TODO: implement controls
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
      if (item.externalAudioPath != null) {
        await player.setAudioTrack(
            AudioTrack.uri(item.externalAudioPath!, title: 'external audio'));
      }
      // for (final sub in item.externalSubtitlePaths.entries) {
      //   player.setSubtitleTrack(
      //       SubtitleTrack.uri(sub.value, language: sub.key, title: sub.key));
      // }
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
        .then((duration) {
      if (WatchHistory.has(item.nameHash)) {
        player.seek(item.lastPosition);
        BotToast.showText(
            text: 'Resuming from ${item.lastPosition.toStringNoMs()}');
        Logger().d('Restoring position to ${item.lastPosition}');
      } else {
        WatchHistory.add(WatchHistoryEntry(
            title: item.displayName,
            nameHash: item.nameHash,
            duration: duration.inSeconds,
            position: player.state.position.inSeconds));
      }
    });
    positionSub = Stream.periodic(const Duration(seconds: 2)).listen((_) async {
      await widget.item.updateWatchPosition(player.state.position);
    });

    playbackEndSub = player.stream.completed.listen((event) {
      if (event) {
        WatchHistory.notifier.notifyListeners();

        if (item.watchProgress >= .85) {
          showAdaptiveAlertDialog(
                  context: context,
                  title: const Text('Seems like finished watching'),
                  content: const Text('Delete?'),
                  confirmLabel: 'YES',
                  onConfirm: item.delete,
                  onConfirmStyle:
                      const TextStyle(color: CupertinoColors.destructiveRed),
                  cancelLabel: 'NO')
              .then((_) =>
                  Navigator.of(context).pop()); // TODO: try play next episode
        }
      }
    });
  }
}
