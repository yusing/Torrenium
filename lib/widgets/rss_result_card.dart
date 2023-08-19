import 'package:flutter/cupertino.dart';

import '../class/rss_result_group.dart';
import '../style.dart';
import 'cached_image.dart';

class RSSResultCard extends StatelessWidget {
  final RssResultGroup result;
  const RSSResultCard({required this.result, super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => result.showDialog(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: const Color.fromARGB(0, 0, 0, 0),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
                child: ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: CachedImage(
                  url: result.items.first.coverUrl,
                  fallbackGetter: result.items.first.coverPhotoFallbackUrl,
                  width: kCoverPhotoWidth),
            )),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Text(
                result.title,
                textAlign: TextAlign.center,
                style: kItemTitleTextStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
