import 'package:flutter/cupertino.dart';

import '../interface/download_item.dart';
import '../widgets/video_player.dart';

Future<void> showVideoPlayer(BuildContext context, DownloadItem item) async {
  await Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
      fullscreenDialog: true, builder: (_) => VideoPlayerPage(item)));
}
