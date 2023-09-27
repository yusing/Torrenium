import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:get/get.dart';

import '/class/rss_item.dart';
import '/interface/downloadable.dart';
import '/interface/playable.dart';
import '/main.dart' show kIsDesktop;
import '/style.dart';
import '/utils/show_snackbar.dart';
import '/widgets/adaptive.dart';

class PlayDownloadButtons extends StatelessWidget {
  final List<RSSItem> results;

  const PlayDownloadButtons(this.results, {super.key});

  Widget builder(RSSItem e) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (e is Playable)
          AdaptiveTextButton(
              icon: const AdaptiveIcon(CupertinoIcons.play_arrow),
              label: const Text('Play'),
              onPressed: () {
                (e as Playable)
                    .showVideoPlayer()
                    .then((_) => Get.back(closeOverlays: true))
                    .onError((e, st) {
                  showSnackBar('Failed to load video', e.toString());
                });
              }),
        if (e is Downloadable)
          AdaptiveTextButton(
              icon: const AdaptiveIcon(CupertinoIcons.cloud_download),
              label: const Text('Download'),
              onPressed: () {
                (e as Downloadable).startDownload(true).onError((e, st) {
                  showSnackBar('Failed to download', e.toString());
                }).then((value) => Get.back(closeOverlays: true));
              })
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }
    if (results.length == 1) {
      return builder(results.first);
    }
    return Wrap(
      children: List.unmodifiable(results.map((e) => AdaptiveTextButton(
          icon: const AdaptiveIcon(CupertinoIcons.videocam),
          label: Text(e.episode ?? e.nameCleaned),
          onPressed: () async =>
              await showAdaptivePopup(builder: (_) => builder(e))))),
    );
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
        items.first.source.isDescriptionInHTML
            ? Html(
                data: items.first.description,
              )
            : Text(items.first.description),
      ]));
}
