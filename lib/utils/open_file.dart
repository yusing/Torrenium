import 'dart:io';

import 'package:flutter/cupertino.dart';

import '../classes/torrent.dart';
import 'show_video_player.dart';

Future<void> openTorrent(BuildContext context, Torrent torrent) async {
  // TODO: implement video player for linux/macos
  if (Platform.isWindows) {
    await Process.run('start', ['', torrent.fullPath], runInShell: true);
  } else {
    await showVideoPlayer(context, torrent);
  }
}
