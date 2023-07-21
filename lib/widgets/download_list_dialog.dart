import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/utils/torrent_manager.dart';
import 'package:torrenium/widgets/download_listitem.dart';

class DownloadListDialog extends MacosSheet {
  DownloadListDialog(BuildContext context, {super.key})
      : super(child: StatefulBuilder(builder: (context, setState) {
          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: ListView.separated(
              padding: const EdgeInsets.all(16.0),
              separatorBuilder: (_, index) => const SizedBox(height: 16),
              itemCount: TorrentManager.torrentList.length,
              itemBuilder: ((_, index) => DownloadListItem(
                  TorrentManager.torrentList[index],
                  setStateCallback: setState)),
            ),
          );
        }));
}
