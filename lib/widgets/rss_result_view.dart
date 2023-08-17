import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/rss_result_group.dart';
import '../services/torrent.dart';
import '../services/torrent_ext.dart';
import '../style.dart';
import 'dynamic.dart';
import 'rss_result_card.dart';

class RssResultGridView extends StatelessWidget {
  final ScrollController? controller;
  final List<RssResultGroup> results;
  const RssResultGridView(this.results, {this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: GridView.builder(
          shrinkWrap: true,
          controller: controller,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: kCoverPhotoWidth,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7),
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
        final item = results[index].items.first;
        return DynamicListTile(
          title: Text(results[index].title),
          trailing: [
            DynamicIconButton(
              padding: const EdgeInsets.all(0),
              icon: const MacosIcon(CupertinoIcons.cloud_download, size: 18),
              onPressed: () => gTorrentManager.download(item, context: context),
            ),
            const SizedBox(width: 16),
            DynamicIconButton(
              padding: const EdgeInsets.all(0),
              icon: const MacosIcon(
                CupertinoIcons.info,
                size: 16,
              ),
              onPressed: () => results[index].showDialog(context),
            )
          ],
          subtitle: Text(
              "${item.category ?? 'Unknown'}: Published at ${item.pubDate} ${item.size != null ? 'Size: ${item.size}' : ''}",
              style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }
}
