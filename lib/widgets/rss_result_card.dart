import 'package:flutter/cupertino.dart';

import '/class/rss_result_group.dart';
import '/style.dart';
import '/utils/string.dart';
import 'adaptive.dart';
import 'cached_image.dart';

class RSSResultCard extends StatelessWidget {
  final RssResultGroup result;
  const RSSResultCard({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => result.showDialog(context),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Stack(
          children: [
            SizedBox.expand(
              child: CachedImage(
                url: result.items.first.coverUrl,
                fallbackGetter: result.items.first.coverPhotoFallbackUrl,
                fit: BoxFit.cover,
              ),
            ),
            Align(
              alignment: Alignment.bottomCenter,
              child: Container(
                width: double.infinity,
                height: 55,
                padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                color: const Color.fromARGB(200, 0, 0, 0),
                child: AdaptiveListTile(
                  title: Text(result.title,
                      style: kItemTitleTextStyle,
                      softWrap: true,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2),
                  subtitle: Text(
                      [
                        if (result.items.length > 1)
                          '${result.items.length} Items',
                        if (result.items.first.author != null)
                          result.items.first.author,
                        if (result.items.last.pubDate != null)
                          result.items.last.pubDate!.relative,
                        if (result.items.last.viewCount != null)
                          '${result.items.last.viewCount!.countUnit} Views',
                        if (result.items.last.likeCount != null)
                          '${result.items.last.likeCount!.countUnit} Likes',
                      ].join(' | '),
                      maxLines: 1),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
