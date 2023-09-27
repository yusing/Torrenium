import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';

import '/class/rss_result_group.dart';
import '/services/rss_providers.dart';
import '/services/settings.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';
import '/widgets/rss_result_card.dart';

class RssResultGridView extends StatelessWidget {
  final ScrollController? controller;
  final RSSProvider provider;
  final List<RssResultGroup> results;
  const RssResultGridView(this.provider, this.results,
      {this.controller, super.key});

  @override
  Widget build(BuildContext context) {
    if (Settings.textOnlyMode.value) {
      return RssResultListView(results, controller: controller);
    }
    return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: MasonryGridView.builder(
          controller: controller,
          mainAxisSpacing: 4,
          crossAxisSpacing: 4,
          gridDelegate: SliverSimpleGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent: provider is YouTubeProvider
                ? min(480, MediaQuery.of(context).size.width)
                : max(400, MediaQuery.of(context).size.width / 4),
          ),
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
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
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      itemCount: results.length,
      itemBuilder: ((context, index) {
        final item = results[index].value.first;
        return AdaptiveListTile(
          key: ValueKey(results[index].key),
          title: Text(results[index].key),
          onTap: () => results[index].showDialog(),
          subtitle: Text(
              [
                if (item.category != null) item.category,
                if (item.pubDate is String)
                  item.pubDate
                else
                  (item.pubDate as DateTime).relative,
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
