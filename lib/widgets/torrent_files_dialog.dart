import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as pathlib;

import '../classes/torrent.dart';
import '../services/torrent.dart';
import '../style.dart';
import '../utils/ext_icons.dart';
import '../utils/open_file.dart';
import '../utils/units.dart';
import 'dynamic.dart';

class TorrentFliesSheet extends StatelessWidget {
  final Torrent torrent;

  const TorrentFliesSheet(this.torrent, {super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: ListView.separated(
        shrinkWrap: true,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemCount: torrent.files.length,
        padding: const EdgeInsets.all(16.0),
        itemBuilder: (_, index) {
          final file = torrent.files[index];
          if (!file.exists) {
            return const SizedBox.shrink();
          }
          return DynamicListTile(
            leading: DynamicIcon(
              getPathIcon(pathlib.join(
                  gTorrentManager.savePath, torrent.name, file.relativePath)),
              size: 32,
              color: CupertinoColors.white,
            ),
            title: Text(
              file.name,
              style: kItemTitleTextStyle,
              maxLines: 2,
            ),
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
                          child: DynamicProgressBar(
                              value: file.progress.toDouble()),
                        ),
                        const SizedBox(height: 8),
                        Text(
                            "${file.bytesDownloaded.humanReadableUnit} of ${file.size.humanReadableUnit}",
                            style: kItemTitleTextStyle),
                      ]),
            onTap: () => openItem(context, file),
          );
        },
      ),
    );
  }
}
