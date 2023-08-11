import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/torrent.dart';
import '../main.dart' show kIsDesktop;
import '../services/torrent.dart';
import '../style.dart';
import '../utils/units.dart';
import 'torrent_files_dialog.dart';
import 'video_player.dart';

class DownloadListDialog extends MacosSheet {
  DownloadListDialog(BuildContext context, {super.key})
      : super(child: content());

  static StatefulWidget content() => ValueListenableBuilder(
      valueListenable: gTorrentManager.updateNotifier,
      builder: (context, _, __) => Padding(
            padding: const EdgeInsets.all(16.0),
            child: gTorrentManager.torrentList.isEmpty
                ? const Center(child: Text('Nothing Here...'))
                : ListView.separated(
                    padding: const EdgeInsets.all(16.0),
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

class _DownloadListItemStatic extends MacosListTile {
  _DownloadListItemStatic(BuildContext context, Torrent torrent)
      : super(
          leading: MacosIcon(torrent.icon,
              color: torrent.isMultiFile ? Colors.yellowAccent : Colors.white,
              size: 32),
          title: torrent.isPlaceholder
              ? Text(
                  torrent.displayName,
                  style: kItemTitleTextStyle,
                )
              : Row(
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
                      })
                    else if (torrent.watchProgress > 0)
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: Text(
                          '${torrent.watchProgress.percentageUnit(0)} Watched',
                          style: kItemTitleTextStyle.copyWith(
                              color: Colors.yellowAccent),
                        ),
                      ),
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
                                    builder: (context) =>
                                        TorrentFliesSheet(torrent));
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
                            gTorrentManager.deleteTorrent(torrent);
                            if (kIsDesktop &&
                                gTorrentManager.torrentList.isEmpty) {
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
            if (Platform.isWindows) {
              await Process.run('start', ['', torrent.fullPath],
                  runInShell: true);
            } else {
              await Navigator.of(context, rootNavigator: true).push(
                  CupertinoPageRoute(
                      fullscreenDialog: true,
                      builder: (_) => VideoPlayerPage(torrent)));
            }
          },
        );
}
