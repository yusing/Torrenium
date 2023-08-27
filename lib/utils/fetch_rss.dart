import 'package:xml/xml.dart';

import '/class/rss_item.dart';
import '/class/rss_result_group.dart';
import '/interface/groupable.dart';
import '/services/http.dart';
import '/services/rss_providers.dart';
import '/services/youtube.dart';

Future<List<RssResultGroup>> getRSSResults(RSSProvider provider,
    {String? query, String? author, String? category}) async {
  if (provider.isYouTube) {
    assert(query != null);
    return await YouTube.search(query!);
  }
  return await getRSSResultsDefault(provider,
      provider.searchUrl(query: query, author: author, category: category));
}

Future<List<RssResultGroup>> getRSSResultsDefault(
    RSSProvider provider, String url) async {
  final items = await _getRSSItems(provider, url);
  if (provider.supportTitleGroup) {
    return items.group().entries.toList(growable: false);
  }
  return items.map((e) => RssResultGroup(e.name, [e])).toList(growable: false);
}

List<RSSItem> parseRSSForItems(RSSProvider provider, String body) {
  final doc = XmlDocument.parse(body);
  return doc.findAllElements(provider.tags.item).map((e) {
    final authorElement = provider.tags.authorName == null
        ? null
        : e.findElements(provider.tags.authorName!).first;
    return RSSItem(
      name: e.findElements(provider.tags.title).first.innerText,
      pubDate: provider
          .pubDateParser(e.findElements(provider.tags.pubDate).first.innerText),
      description: provider.detailGetter.getDescription.call(e) ?? '',
      torrentUrl: provider.detailGetter.getMagnetUrl?.call(e),
      coverUrl: provider.detailGetter.getCoverUrl?.call(e),
      viewCount: int.tryParse(provider.detailGetter.getViews?.call(e) ?? ''),
      likeCount: int.tryParse(provider.detailGetter.getLikes?.call(e) ?? ''),
      author: provider.isYouTube
          ? authorElement?.findElements('name').first.innerText
          : authorElement?.innerText,
      category: provider.tags.category == null
          ? null
          : e.findElements(provider.tags.category!).first.innerText,
      size: provider.tags.fileSize == null
          ? null
          : e.findElements(provider.tags.fileSize!).first.innerText,
    );
  }).toList(growable: false);
}

Future<List<RSSItem>> _getRSSItems(RSSProvider provider, String url) async {
  String body = await gCacheManager.getSingleFile(url, headers: {
    'Content-Type': 'application/xml',
    'Accept': 'application/xml',
    'Encoding': 'UTF-8',
  }).then((value) => value.readAsString());

  return parseRSSForItems(provider, body);
}
