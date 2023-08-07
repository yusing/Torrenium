import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:path/path.dart' as path;
import 'package:torrenium/widgets/torrent_files_dialog.dart';

import '../classes/torrent.dart';
import '../style.dart';
import '../utils/ext_icons.dart';
import '../utils/torrent_manager.dart';
import '../utils/units.dart';

class DownloadListItem extends ValueListenableBuilder {
  DownloadListItem(Torrent torrent,
      {super.key, required StateSetter setStateCallback})
      : super(
          valueListenable: torrent.stateNotifier,
          builder: ((_, __, ___) =>
              _DownloadListItemStatic(torrent, setStateCallback)),
        );
}

class DownloadListMenuItem extends MacosPulldownMenuItem {
  const DownloadListMenuItem({required Widget child, super.key})
      : super(title: child);
  @override
  double get itemHeight => 128;
}

class _DownloadListItemStatic extends MacosListTile {
  _DownloadListItemStatic(Torrent torrent, StateSetter setStateCallback)
      : super(
          leading: MacosIcon(
              getPathIcon(path.join(gTorrentManager.savePath, torrent.name)),
              color: torrent.isMultiFile ? Colors.yellowAccent : Colors.white,
              size: 32),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  torrent.displayName,
                  style: kItemTitleTextStyle,
                ),
              ),
              if (!torrent.isComplete)
                StatefulBuilder(builder: (context, pauseBtnSetState) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: MacosIconButton(
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(0),
                        icon: Icon(
                          torrent.paused
                              ? CupertinoIcons.play_circle_fill
                              : CupertinoIcons.pause_circle_fill,
                          color: Colors.grey[700],
                        ),
                        onPressed: () => pauseBtnSetState(() {
                              if (torrent.paused) {
                                gTorrentManager.resumeTorrent(torrent);
                              } else {
                                gTorrentManager.pauseTorrent(torrent);
                              }
                            })),
                  );
                }),
              if (torrent.isMultiFile)
                Builder(builder: (context) {
                  return Padding(
                    padding: const EdgeInsets.only(right: 8.0),
                    child: MacosIconButton(
                        shape: BoxShape.circle,
                        padding: const EdgeInsets.all(0),
                        icon: Icon(
                          CupertinoIcons.search_circle_fill,
                          color: Colors.grey[700],
                          size: 24,
                        ),
                        onPressed: () async {
                          await showMacosAlertDialog(
                              context: context,
                              barrierDismissible: true,
                              builder: (context) => TorrentFliesSheet(torrent));
                        }),
                  );
                }),
              Builder(builder: (context) {
                return MacosIconButton(
                    shape: BoxShape.circle,
                    padding: const EdgeInsets.all(0),
                    icon: const Icon(
                      CupertinoIcons.delete_solid,
                      color: Colors.redAccent,
                    ),
                    onPressed: () {
                      setStateCallback(
                          () => gTorrentManager.deleteTorrent(torrent));
                      if (gTorrentManager.torrentList.isEmpty) {
                        Navigator.of(context).pop();
                      }
                    });
              }),
            ],
          ),
          subtitle: torrent.isComplete && torrent.isMultiFile ||
                  !torrent.isComplete
              ? Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (!torrent.isComplete) const SizedBox(height: 4),
                    if (!torrent.isComplete)
                      Builder(builder: (context) {
                        return ConstrainedBox(
                            constraints: BoxConstraints(
                                minWidth: MediaQuery.of(context).size.width),
                            child: ProgressBar(
                                value: torrent.progress.toDouble() * 100));
                      }),
                    if (!torrent.isComplete) const SizedBox(height: 4),
                    if (!torrent.isComplete)
                      Text(
                          "${torrent.bytesDownloaded.humanReadableUnit} of ${torrent.size.humanReadableUnit} - ${torrent.etaSecs.timeUnit} remaining",
                          style: kItemTitleTextStyle)
                    else
                      Text(
                        '${torrent.files.length} files',
                        style: kItemTitleTextStyle,
                      ),
                  ],
                )
              : null,
          onClick: () async {
            // Uri pathUri =
            //     Uri.file(path.join(gTorrentManager.savePath, torrent.name));
            // if (await canLaunchUrl(pathUri)) {
            //   await launchUrl(pathUri, mode: LaunchMode.externalApplication);
            // }
            await Process.run('start',
                ['', path.join(gTorrentManager.savePath, torrent.name)],
                runInShell: true);
          },
        );
}
