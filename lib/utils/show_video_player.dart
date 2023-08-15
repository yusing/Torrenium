import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:torrenium/widgets/video_player.dart';

import '../classes/torrent.dart';

Future<void> showVideoPlayer(BuildContext context, Torrent torrent) async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
      fullscreenDialog: true, builder: (_) => VideoPlayerPage(torrent)));
  SystemChrome.restoreSystemUIOverlays().then((_) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  });
}
