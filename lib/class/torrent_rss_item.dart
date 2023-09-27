import 'package:logger/logger.dart';

import '/interface/downloadable.dart';
import '/interface/playable.dart';
import '/services/settings.dart';
import '/services/torrent_mgr.dart';
import '/utils/show_snackbar.dart';
import 'rss_item.dart';

class TorrentRSSItem extends RSSItem with Playable implements Downloadable {
  final String? torrentUrl;

  TorrentRSSItem({
    required super.coverUrl,
    required super.name,
    required super.source,
    required super.description,
    required super.pubDate,
    required super.viewCount,
    required super.likeCount,
    required super.author,
    required super.category,
    required super.size,
    required this.torrentUrl,
  });

  @override
  String get fullPath => '${Settings.serverUrl.value}/${torrentUrl!}/0';

  @override
  Future<void> showVideoPlayer() async {
    Logger().i('showVideoPlayer: $name\nfullPath: $fullPath');
    if (!await Settings.serverUrl.validate()) {
      await showSnackBar('Error', 'WebTorrent Server is not reachable');
      Logger().e('WebTorrent Server is not reachable');
      return;
    }
    await super.showVideoPlayer();
  }

  @override
  Future<void> startDownload([bool snackbar = false]) async {
    Logger().i('startDownload: $name');
    if (torrentUrl == null) {
      if (snackbar) {
        await showSnackBar('Error', 'item is not downloadable');
      }
      return;
    }
    if (snackbar) {
      await showSnackBar('Downloading', name);
    }
    await gTorrentManager.downloadItem(this);
  }
}
