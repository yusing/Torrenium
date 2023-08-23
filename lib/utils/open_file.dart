import 'package:flutter/cupertino.dart';

import '/interface/download_item.dart';
import 'show_video_player.dart';

Future<void> openItem(BuildContext context, DownloadItem item) async {
  // TODO: handle for different file type
  await showVideoPlayer(context, item);
}
