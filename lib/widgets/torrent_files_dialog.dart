import 'dart:io';

import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/style.dart';
import 'package:torrenium/utils/ext_icons.dart';
import 'package:torrenium/utils/torrent_manager.dart';
import 'package:torrenium/utils/units.dart';
import 'package:path/path.dart' as path;

class TorrentFliesSheet extends StatelessWidget {
  const TorrentFliesSheet(this.torrent, {super.key});

  final Torrent torrent;

  @override
  Widget build(BuildContext context) {
    return MacosSheet(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView.separated(
          shrinkWrap: true,
          separatorBuilder: (_, __) => const SizedBox(height: 16),
          itemCount: torrent.files.length,
          padding: const EdgeInsets.all(16.0),
          itemBuilder: (_, index) {
            final file = torrent.files[index];
            return MacosListTile(
              leading: MacosIcon(
                getPathIcon(path.join(
                    TorrentManager.savePath, torrent.name, file.relativePath)),
                size: 32,
                color: Colors.white,
              ),
              title: Text(file.name, style: kItemTitleTextStyle),
              subtitle: file.progress == 1
                  ? Text(
                      file.size.humanReadableUnit,
                      style: kItemTitleTextStyle,
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.max,
                      mainAxisAlignment: MainAxisAlignment.start,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                          const SizedBox(height: 4),
                          SizedBox(
                            width: MediaQuery.of(context).size.width - 162,
                            child: ProgressBar(
                                value: file.progress.toDouble() * 100),
                          ),
                          const SizedBox(height: 8),
                          Text(
                              "${file.bytesDownloaded.humanReadableUnit} of ${file.size.humanReadableUnit}",
                              style: kItemTitleTextStyle),
                        ]),
              onClick: () async {
                await Process.run(
                    'start',
                    [
                      '""',
                      path.join(TorrentManager.savePath, torrent.name,
                          file.relativePath)
                    ],
                    runInShell: true);
              },
            );
          },
        ),
      ),
    );
  }
}
