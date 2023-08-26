import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';

import '/class/item.dart';
import '/class/youtube_item.dart';
import '/main.dart' show kIsDesktop;
import '/services/torrent_ext.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/utils/show_video_player.dart';
import 'adaptive.dart';
import 'rss_tab.dart';

class PlayDownloadButtons extends StatelessWidget {
  final List<Item> results;

  const PlayDownloadButtons(this.results, {super.key});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: List.unmodifiable(results.map((e) => AdaptiveTextButton(
          icon: gRssProvider.isYouTube
              ? const AdaptiveIcon(CupertinoIcons.play)
              : const AdaptiveIcon(CupertinoIcons.cloud_download),
          label:
              Text(e.episode ?? (gRssProvider.isYouTube ? 'Play' : 'Download')),
          onPressed: () => openOrDownloadItem(context, e)))),
    );
  }

  void openOrDownloadItem(BuildContext context, Item item) {
    if (gRssProvider.isYouTube) {
      YouTubeItem(item)
          .init()
          .then((ytItem) => showVideoPlayer(context, ytItem))
          .onError((error, st) => showAdaptiveAlertDialog(
              context: context,
              title: const Text('Failed to load video'),
              content: Text(error.toString())));
    } else {
      gTorrentManager.download(item, context: context);
    }
  }
}

class RssResultDialog extends StatelessWidget {
  final List<Item> items;
  const RssResultDialog(this.items, {super.key});

  @override
  Widget build(BuildContext context) => Container(
      decoration: gradientDecoration,
      padding: EdgeInsets.all(kIsDesktop ? 32.0 : 8.0),
      child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            PlayDownloadButtons(items),
            Expanded(
              child: SingleChildScrollView(
                child: gRssProvider.isYouTube
                    ? Text(items.first.description)
                    : Html(
                        data: items.first.description,
                      ),
              ),
            ),
          ]));
}
