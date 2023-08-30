import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';

import '/class/rss_item.dart';
import '/class/youtube_item.dart';
import '/main.dart' show kIsDesktop;
import '/services/torrent_ext.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/widgets/adaptive.dart';

class PlayDownloadButtons extends StatelessWidget {
  final List<RSSItem> results;

  const PlayDownloadButtons(this.results, {super.key});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }
    return Wrap(
      children: List.unmodifiable(results.map((e) => AdaptiveTextButton(
          icon: e.source.isYouTube
              ? const AdaptiveIcon(CupertinoIcons.play)
              : const AdaptiveIcon(CupertinoIcons.cloud_download),
          label: Text(e.episode ?? (e.source.isYouTube ? 'Play' : 'Download')),
          onPressed: () async => await openOrDownloadItem(e).then((_) {
                if (results.length == 1) {
                  Get.back(closeOverlays: true);
                }
              })))),
    );
  }

  Future<void> openOrDownloadItem(RSSItem item) async {
    if (item.source.isYouTube) {
      YouTubeItem(item).play().onError((error, st) async {
        Logger().e('Failed to load video', error, st);
        BotToast.showText(text: 'Failed to load video $error');
      });
    } else {
      gTorrentManager.download(item);
    }
  }
}

class RssResultDialog extends StatelessWidget {
  final List<RSSItem> items;
  const RssResultDialog(this.items, {super.key});

  @override
  Widget build(BuildContext context) => Container(
      decoration: gradientDecoration,
      padding: EdgeInsets.all(kIsDesktop ? 32.0 : 8.0),
      child: ListView(children: [
        Text(
          items.first.title,
          style: kItemTitleTextStyle,
        ),
        PlayDownloadButtons(items),
        items.first.source.isYouTube
            ? Text(items.first.description)
            : Html(
                data: items.first.description,
              ),
      ]));
}
