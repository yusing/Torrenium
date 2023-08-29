import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';

import '/interface/download_item.dart';
import 'file_types.dart';
import 'show_video_player.dart';

Future<void> openItem(BuildContext context, DownloadItem item) async {
  // TODO: handle for different file type
  if (!(File(item.videoPath).existsSync())) {
    BotToast.showText(text: 'File not found');
    return;
  }
  if (FileTypeExt.from(item.videoPath) != FileType.video) {
    BotToast.showText(text: 'File type not supported');
    return;
  }
  await showVideoPlayer(context, item);
}
