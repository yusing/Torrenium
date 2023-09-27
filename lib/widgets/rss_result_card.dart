import 'package:flutter/cupertino.dart';

import '/class/rss_result_group.dart';
import '/utils/string.dart';
import 'adaptive.dart';
import 'cached_image.dart';

class RSSResultCard extends StatelessWidget {
  final RssResultGroup result;
  const RSSResultCard({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => result.showDialog(),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CachedImage(
              url: result.value.first.coverUrl,
              fallbackGetter: result.value.first.defaultCoverUrlFallback,
              fit: BoxFit.cover,
            ),
            ColoredBox(
              color: const Color.fromARGB(200, 0, 0, 0),
              child: AdaptiveListTile(
                key: ValueKey(result.key),
                title: Text(
                  result.key,
                ),
                subtitle: Text([
                  if (result.value.length > 1) '${result.value.length} Items',
                  if (result.value.first.author != null)
                    result.value.first.author,
                  if (result.value.last.pubDate is String)
                    result.value.last.pubDate
                  else
                    (result.value.last.pubDate as DateTime).relative,
                  if (result.value.last.viewCount != null)
                    '${result.value.last.viewCount!.countUnit} Views',
                  if (result.value.last.likeCount != null)
                    '${result.value.last.likeCount!.countUnit} Likes',
                ].join(' | ')),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
