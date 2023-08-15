import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import '../classes/download_item.dart';
import '../widgets/video_player.dart';

Future<void> showVideoPlayer(BuildContext context, DownloadItem item) async {
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeRight,
    DeviceOrientation.landscapeLeft,
  ]);
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Navigator.of(context, rootNavigator: true).push(CupertinoPageRoute(
      fullscreenDialog: true, builder: (_) => VideoPlayerPage(item)));
  SystemChrome.restoreSystemUIOverlays().then((_) async {
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
  });
}
