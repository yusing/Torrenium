import 'dart:math';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '/class/rss_result_group.dart';
import '/pages/rss_tab.dart';
import '/services/settings.dart';
import '/services/torrent_ext.dart';
import '/services/torrent_mgr.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';
import '/widgets/rss_result_card.dart';

class RssResultGridView extends StatelessWidget {
  final ScrollController? controller;
  final List<RssResultGroup> results;
  const RssResultGridView(this.results, {this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    if (Settings.textOnlyMode.value) {
      if (!Settings.enableGrouping.value) {
        return RssResultListView(
          results.first.value
              .map((e) => RssResultGroup(e.nameCleaned, [e]))
              .toList(growable: false),
          controller: controller,
        );
      }
      return RssResultListView(results, controller: controller);
    }
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: MasonryGridView.builder(
          controller: controller,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          gridDelegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: gRssProvider.isYouTube
                ? min(480, MediaQuery.of(context).size.width)
                : max(400, MediaQuery.of(context).size.width / 4),
          ),
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
        final item = results[index].value.first;
        return AdaptiveListTile(
          key: ValueKey(results[index].key),
          title: Text(results[index].key),
          trailing: [
            AdaptiveIconButton(
              padding: const EdgeInsets.all(0),
              icon: const AdaptiveIcon(CupertinoIcons.cloud_download, size: 18),
              slidableLabel:
                  results[index].value.length > 1 ? 'Download All' : null,
              onPressed: () {
                for (var e in results[index].value) {
                  gTorrentManager.download(e, context: context);
                }
              },
            ),
          ],
          onTap: () => results[index].showDialog(context),
          subtitle: Text(
              [
                if (item.category != null) item.category,
                if (item.pubDate != null) item.pubDate!.relative,
                if (item.size != null) item.size,
                if (results[index].value.length > 1)
                  '${results[index].value.length} results'
              ].join(' | '),
              style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }
}
