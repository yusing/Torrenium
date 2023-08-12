import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Colors;
import 'package:macos_ui/macos_ui.dart' show MacosSheet, showMacosAlertDialog;

import '../classes/torrent.dart';
import '../main.dart' show kIsDesktop;
import '../services/torrent.dart';
import '../style.dart';
import '../utils/open_file.dart';
import '../utils/units.dart';
import 'dynamic.dart';
import 'torrent_files_dialog.dart';

class DownloadListDialog extends MacosSheet {
  DownloadListDialog(BuildContext context, {super.key})
      : super(child: content());

  static StatefulWidget content() => ValueListenableBuilder(
      valueListenable: gTorrentManager.updateNotifier,
      builder: (context, _, __) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 16.0),
            child: gTorrentManager.torrentList.isEmpty
                ? const Center(child: Text('Nothing Here...'))
                : ListView.separated(
                    separatorBuilder: (_, index) => const SizedBox(height: 16),
                    itemCount: gTorrentManager.torrentList.length,
                    itemBuilder: ((_, index) =>
                        DownloadListItem(gTorrentManager.torrentList[index])),
                  ),
          ));
}

class DownloadListItem extends ValueListenableBuilder<void> {
  DownloadListItem(Torrent torrent, {super.key})
      : super(
          valueListenable: torrent.stateNotifier,
          builder: ((context, __, ___) =>
              _DownloadListItemStatic(context, torrent)),
        );
}

class _DownloadListItemStatic extends DynamicListTile {
  final BuildContext context;
  final Torrent torrent;

  _DownloadListItemStatic(this.context, this.torrent)
      : super(
          leading: DynamicIcon(torrent.icon,
              color: torrent.isMultiFile ? Colors.yellowAccent : Colors.white,
              size: 32),
          title: Text(
            torrent.displayName,
            style: kItemTitleTextStyle,
            softWrap: true,
            maxLines: 2,
          ),
          trailing: torrent.isPlaceholder
              ? null
              : [
                  if (!torrent.isComplete)
                    StatefulBuilder(builder: (context, pauseBtnSetState) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8.0),
                        child: DynamicIconButton(
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
                        child: DynamicIconButton(
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
                                  builder: (context) =>
                                      TorrentFliesSheet(torrent));
                            }),
                      );
                    }),
                  Builder(builder: (context) {
                    return DynamicIconButton(
                        padding: const EdgeInsets.all(0),
                        icon: const Icon(
                          CupertinoIcons.delete,
                          color: Colors.redAccent,
                        ),
                        onPressed: () {
                          gTorrentManager.deleteTorrent(torrent);
                          if (kIsDesktop &&
                              gTorrentManager.torrentList.isEmpty) {
                            Navigator.of(context).pop();
                          }
                        });
                  }),
                ],
          subtitle: Column(
            mainAxisSize: MainAxisSize.max,
            mainAxisAlignment: MainAxisAlignment.start,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Builder(builder: (context) {
                return ConstrainedBox(
                    constraints: BoxConstraints(
                        minWidth: MediaQuery.of(context).size.width),
                    child: DynamicProgressBar(
                      value: (torrent.isComplete
                              ? torrent.watchProgress
                              : torrent.progress)
                          .toDouble(),
                      trackColor:
                          torrent.isComplete ? Colors.purpleAccent : null,
                    ));
              }),
              if (!torrent.isComplete)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                      "${torrent.bytesDownloaded.humanReadableUnit} of ${torrent.size.humanReadableUnit} - ${torrent.etaSecs.timeUnit} remaining",
                      style: kItemTitleTextStyle),
                )
              else if (torrent.isMultiFile)
                Padding(
                  padding: const EdgeInsets.only(top: 4.0),
                  child: Text(
                    '${torrent.files.length} files',
                    style: kItemTitleTextStyle,
                  ),
                )
              else
                const SizedBox.shrink(),
            ],
          ),
          onTap: () => openTorrent(context, torrent),
        );
}
