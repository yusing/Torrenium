import 'dart:math';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import '/class/rss_result_group.dart';
import '/services/torrent_ext.dart';
import '/services/torrent_mgr.dart';
import '/utils/string.dart';
import 'adaptive.dart';
import 'rss_result_card.dart';
import 'rss_tab.dart';

class RssResultGridView extends StatelessWidget {
  final ScrollController? controller;
  final List<RssResultGroup> results;
  const RssResultGridView(this.results, {this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: GridView.builder(
          controller: controller,
          gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: gRssProvider.isYouTube
                  ? min(480, MediaQuery.of(context).size.width)
                  : max(300, MediaQuery.of(context).size.width / 4),
              crossAxisSpacing: 16.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: gRssProvider.isYouTube ? 16 / 9 : 9 / 16),
          itemCount: results.length,
          itemBuilder: (_, index) => RSSResultCard(result: results[index]),
        ));
  }
}

class RssResultListView extends StatelessWidget {
  final ScrollController? controller;
  final List<RssResultGroup> results;
  const RssResultListView(this.results, {this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemCount: results.length,
      itemBuilder: ((context, index) {
        assert(results[index].value.length == 1,
            'RSSResultListView expect and support only one item per result\n${results[index].value}');

        final item = results[index].value.first;
        return AdaptiveListTile(
          title: Text(results[index].key),
          trailing: [
            AdaptiveIconButton(
              padding: const EdgeInsets.all(0),
              icon: const MacosIcon(CupertinoIcons.cloud_download, size: 18),
              onPressed: () => gTorrentManager.download(item, context: context),
            ),
            const SizedBox(width: 16),
            AdaptiveIconButton(
              padding: const EdgeInsets.all(0),
              icon: const MacosIcon(
                CupertinoIcons.info,
                size: 16,
              ),
              onPressed: () => results[index].showDialog(context),
            )
          ],
          subtitle: Text(
              [
                item.category ?? 'Unknown Category',
                if (item.pubDate != null) 'Published ${item.pubDate!.relative}',
                if (item.size != null) item.size
              ].join(' | '),
              style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }
}
