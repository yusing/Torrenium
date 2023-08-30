import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

import '/class/rss_item.dart';
import '/widgets/adaptive.dart';
import 'torrent_mgr.dart';

extension TorrentManagerExtension on TorrentManager {
  // TODO: youtube download
  Future<void> download(RSSItem item) async {
    await item.startDownload().onError((error, stackTrace) async {
      Logger().e(error);

      await showAdaptiveAlertDialog(
        title: const Text('Error'),
        content: const Text('No torrent link found'),
      );
    });
  }

  // Future<bool> selectSavePath() async {
  //   String? selectedPath = await FilePicker.platform.getDirectoryPath(
  //     dialogTitle: 'Select a save path',
  //     initialDirectory: docDir.path,
  //     lockParentWindow: true,
  //   );
  //   if (selectedPath == null) {
  //     return false;
  //   }
  //   gTorrentManager.saveDir = selectedPath;
  //   Storage.setString('savePath', selectedPath);
  //   try {
  //     await Directory(selectedPath).create(recursive: true);
  //   } catch (e) {
  //     Logger().e(e);
  //     return false;
  //   }
  //   return true;
  // }
}
