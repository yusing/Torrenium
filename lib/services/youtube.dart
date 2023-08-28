import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '/class/rss_item.dart';
import '/class/rss_result_group.dart';
import '/pages/rss_tab.dart';
import '/utils/fetch_rss.dart';

class YouTube {
  static final client = YoutubeExplode();

  static Future<List<RssResultGroup>> search(String query) async {
    if (query.isEmpty) {
      return await getRSSResultsDefault(
          gRssProvider, gRssProvider.searchUrl(query: query));
    }
    var searchResult =
        await client.search.search(query, filter: const SearchFilter(''));
    return List.unmodifiable(searchResult.map((e) => MapEntry(e.title, [
          RSSItem(
            name: e.title,
            description: e.description,
            torrentUrl: e.url,
            pubDate: e.publishDate ?? DateTime.tryParse(e.uploadDateRaw ?? ''),
            author: e.author,
            category: 'YouTube',
            coverUrl: e.thumbnails.mediumResUrl,
            viewCount: e.engagement.viewCount,
            likeCount: e.engagement.likeCount,
          )
        ])));
  }
}
