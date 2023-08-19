import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../interface/download_item.dart';
import 'show_video_player.dart';

Future<void> openItem(BuildContext context, DownloadItem item) async {
  // TODO: implement video player for linux/macos
  if (Platform.isWindows) {
    await Process.run('start', ['', item.fullPath], runInShell: true);
  } else {
    await showVideoPlayer(context, item);
  }
}
