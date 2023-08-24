import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:macos_ui/macos_ui.dart';

import '/class/item.dart';
import '/class/rss_result_group.dart';
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
    return LayoutBuilder(builder: (context, constraints) {
      return Wrap(
        children: List.unmodifiable(results.map((e) => AdaptiveTextButton(
            icon: gRssProvider.isYouTube
                ? const AdaptiveIcon(CupertinoIcons.play)
                : const AdaptiveIcon(CupertinoIcons.cloud_download),
            label: Text(
                e.episode ?? (gRssProvider.isYouTube ? 'Play' : 'Download')),
            onPressed: () => openOrDownloadItem(context, e)))),
      );
    });
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

class RssResultDialog extends MacosSheet {
  RssResultDialog(BuildContext context, RssResultGroup result, {super.key})
      : super(
            backgroundColor: CupertinoColors.black.withOpacity(.7),
            child: Container(
                decoration: gradientDecoration,
                padding: EdgeInsets.all(kIsDesktop ? 32.0 : 8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        result.title,
                        style: kItemTitleTextStyle,
                      ),
                      ...content(context, result),
                    ])));
  static List<Widget> content(BuildContext context, RssResultGroup result) => [
        // FutureBuilder(
        //     future: gRssProvider.isYouTube
        //         ? Future.value(<RssResultGroup>[])
        //         : getRSSResults(gRssProvider,
        //             query: gQuery,
        //             author: gSelectedAuthor,
        //             category: gSelectedCategory),
        //     builder: (context, snapshot) {
        //       if (snapshot.hasError ||
        //           !snapshot.hasData ||
        //           snapshot.data!.isEmpty ||
        //           snapshot.data!.length < result.items.length) {
        //         return PlayDownloadButtons(result.items);
        //       }
        //       if (snapshot.data!.length == 1) {
        //         return PlayDownloadButtons(snapshot.data!.first.items);
        //       }
        //       return PlayDownloadButtons(snapshot.data!
        //           .reduce((a, b) => a.items.length >= b.items.length ? a : b)
        //           .items);
        //     }),
        PlayDownloadButtons(result.items),
        Expanded(
          child: SingleChildScrollView(
            child: gRssProvider.isYouTube
                ? Text(result.items.first.description)
                : Html(
                    data: result.items.first.description,
                  ),
          ),
        ),
      ];
}
