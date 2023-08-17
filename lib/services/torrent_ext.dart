import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import 'storage.dart';
import 'torrent.dart';

extension TorrentManagerExtension on TorrentManager {
  // TODO: change this
  void download(Item item, {required BuildContext context, bool pop = false}) {
    item.startDownload().onError((error, stackTrace) async {
      Logger().e(error);

      await showMacosAlertDialog(
          context: context,
          builder: (context) {
            return MacosAlertDialog(
              title: const Text('Error'),
              message: const Text('No torrent link found'),
              appIcon: const SizedBox(), // TODO: replace this
              primaryButton: PushButton(
                  controlSize: ControlSize.large,
                  child: const Text('Dismiss'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  }),
            );
          });
    }).then((value) {
      if (pop) Navigator.pop(context);
    });
  }

  Future<bool> selectSavePath() async {
    String? selectedPath = await FilePicker.platform.getDirectoryPath(
      dialogTitle: 'Select a save path',
      initialDirectory: docDir.path,
      lockParentWindow: true,
    );
    if (selectedPath == null) {
      return false;
    }
    Storage.setString('savePath', selectedPath);
    try {
      await Directory(selectedPath).create(recursive: true);
    } catch (e) {
      Logger().e(e);
      return false;
    }
    return true;
  }
}
