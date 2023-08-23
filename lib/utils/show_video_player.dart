import 'package:flutter/cupertino.dart';

import '/interface/download_item.dart';
import '/main.dart' show kIsDesktop;
import '/widgets/adaptive.dart';
import '/widgets/video_player.dart';

Future<void> showVideoPlayer(BuildContext context, DownloadItem item) async {
  if (kIsDesktop) {
    await showAdaptivePopup(
        context: context, builder: (context) => VideoPlayerPage(item));
  } else {
    Navigator.push(
        context,
        CupertinoPageRoute(
            builder: (_) => CupertinoPageScaffold(
                navigationBar: CupertinoNavigationBar(
                  middle: Text(
                    item.name,
                    overflow: TextOverflow.ellipsis,
                    softWrap: true,
                    maxLines: 2,
                  ),
                ),
                child: SafeArea(child: VideoPlayerPage(item)))));
  }
}
