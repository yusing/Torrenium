import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:macos_ui/macos_ui.dart';

import '../class/item.dart';
import '../class/rss_result_group.dart';
import '../main.dart' show kIsDesktop;
import '../services/torrent_ext.dart';
import '../services/torrent_mgr.dart';
import '../style.dart';
import '../utils/fetch_rss.dart';
import '../widgets/rss_tab.dart';
import 'adaptive.dart';

class DownloadButtons extends StatelessWidget {
  final List<Item> results;

  const DownloadButtons(this.results, {super.key});

  @override
  Widget build(BuildContext context) {
    if (results.isEmpty) {
      return const SizedBox.shrink();
    }
    if (results.length == 1) {
      return AdaptiveTextButton(
          icon: const AdaptiveIcon(CupertinoIcons.cloud_download),
          label: const Text('Download'),
          onPressed: () =>
              gTorrentManager.download(results.first, context: context));
    }
    return LayoutBuilder(builder: (context, constraints) {
      return GridView.builder(
          shrinkWrap: true,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 5 / 2),
          itemCount: results.length,
          itemBuilder: (context, i) => FittedBox(
                fit: BoxFit.fitWidth,
                child: AdaptiveTextButton(
                    icon: const AdaptiveIcon(CupertinoIcons.cloud_download),
                    label: Text('Episode $i'),
                    onPressed: () =>
                        gTorrentManager.download(results[i], context: context)),
              ));
    });
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
        result.items.first.isMusic
            ? DownloadButtons(result.items)
            : FutureBuilder(
                future: getRSSResults(
                    gRssProvider, gRssProvider.searchUrl(query: result.title)),
                builder: (context, snapshot) {
                  if (snapshot.hasError ||
                      !snapshot.hasData ||
                      snapshot.data!.isEmpty) {
                    return DownloadButtons(result.items);
                  }
                  if (snapshot.data!.length == 1) {
                    return DownloadButtons(snapshot.data!.first.items);
                  }
                  return DownloadButtons(snapshot.data!
                      .reduce((a, b) => a.items.length > b.items.length ? a : b)
                      .items);
                }),
        Expanded(
          child: SingleChildScrollView(
            child: Html(
              data: result.items.first.description,
            ),
          ),
        ),
      ];
}
