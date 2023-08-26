import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';

import '/class/item.dart';
import '/widgets/adaptive.dart';
import 'torrent_mgr.dart';

extension TorrentManagerExtension on TorrentManager {
  // TODO: change this
  void download(Item item, {required BuildContext context, bool pop = false}) {
    item.startDownload().onError((error, stackTrace) async {
      Logger().e(error);

      await showAdaptiveAlertDialog(
        context: context,
        title: const Text('Error'),
        content: const Text('No torrent link found'),
      );
    }).then((value) {
      if (pop) Navigator.pop(context);
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
