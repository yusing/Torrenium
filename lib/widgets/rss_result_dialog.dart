import 'package:flutter/cupertino.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:macos_ui/macos_ui.dart';
import '../services/torrent_ext.dart';
import '../utils/fetch_rss.dart';
import '../widgets/dynamic.dart';
import '../widgets/rss_tab.dart';

import '../classes/item.dart';
import '../classes/rss_result_group.dart';
import '../main.dart' show kIsDesktop;
import '../services/torrent.dart';
import '../style.dart';
import '../utils/gradient.dart';

class DownloadBoxes extends StatelessWidget {
  final List<Item> results;

  const DownloadBoxes(this.results, {super.key});

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
        shrinkWrap: true,
        gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: kCoverPhotoWidth,
            crossAxisSpacing: 8.0,
            mainAxisSpacing: 16.0,
            childAspectRatio: 0.7),
        itemCount: results.length,
        itemBuilder: (context, i) => DynamicTextButton(
            label: Text('$i'),
            onPressed: () =>
                gTorrentManager.download(results[i], context: context)));
  }
}

class RssResultDialog extends MacosSheet {
  RssResultDialog(BuildContext context, RssResultGroup result, {super.key})
      : super(
            backgroundColor: CupertinoColors.black.withAlpha(147),
            child: Container(
                decoration: gradientDecoration,
                padding: EdgeInsets.all(kIsDesktop ? 32.0 : 8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        result.title,
                        style: kItemTitleTextStyle,
                      ),
                      Expanded(child: content(context, result)),
                    ])));
  static Widget content(BuildContext context, RssResultGroup result) =>
      // TODO: update content
      SingleChildScrollView(
        child: Column(
          children: [
            FutureBuilder(
                future: getRSSResults(
                    gRssProvider, gRssProvider.searchUrl(query: result.title)),
                builder: (context, snapshot) {
                  if (snapshot.hasError || !snapshot.hasData) {
                    return DownloadBoxes(result.items);
                  }
                  return DownloadBoxes(snapshot.data!
                      .reduce((a, b) => a.items.length > b.items.length ? a : b)
                      .items);
                }),
            Expanded(
              child: Html(
                data: result.items.first.description,
              ),
            ),
          ],
        ),
      );
}
