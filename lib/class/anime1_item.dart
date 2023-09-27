import 'package:logger/logger.dart';

import '/interface/playable.dart';
import 'rss_item.dart';

class Anime1Item extends RSSItem with Playable {
  final String catId;
  final String episodeNumber;

  Anime1Item(
      {required super.name,
      required super.source,
      required super.description,
      required this.catId,
      required this.episodeNumber,
      super.pubDate = 'Unknown date',
      super.coverUrl,
      super.category,
      super.author,
      super.size,
      super.viewCount,
      super.likeCount});

  @override
  String get episode => 'Episode $episodeNumber';

  @override
  String get fullPath => 'https://hinata.v.anime1.me/$catId/$episodeNumber.mp4';

  @override
  Future<void> showVideoPlayer() {
    Logger().d('Anime1Item: $name Episode: $episodeNumber URL: $fullPath');
    return super.showVideoPlayer();
  }
}
