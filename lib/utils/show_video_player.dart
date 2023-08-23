import 'package:flutter/cupertino.dart';

import '/interface/download_item.dart';
import '/widgets/adaptive.dart';
import '/widgets/video_player.dart';

Future<void> showVideoPlayer(BuildContext context, DownloadItem item) async {
  await showAdaptivePopup(
      context: context, builder: (context) => VideoPlayerPage(item));
}
