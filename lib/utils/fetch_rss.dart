import 'package:intl/intl.dart';
import 'package:torrenium/interface/groupable.dart';
import 'package:xml/xml.dart';

import '../class/item.dart';
import '../class/rss_result_group.dart';
import '../services/http.dart';
import 'rss_providers.dart';

final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

Future<List<Item>> _getRSSItems(RSSProvider provider, String url) async {
  String body = await gCacheManager.getSingleFile(url, headers: {
    'Content-Type': 'application/xml',
    'Accept': 'application/xml',
    'Encoding': 'UTF-8',
  }).then((value) => value.readAsString());

  return parseRSSForItems(provider, body);
}

Future<List<RssResultGroup>> getRSSResults(
    RSSProvider provider, String url) async {
  final items = await _getRSSItems(provider, url);
  if (provider.supportTitleGroup) {
    return items.group().entries.map((e) => RssResultGroup(e)).toList();
  }
  return items
      .map((e) => RssResultGroup(MapEntry(e.nameCleaned, [e])))
      .toList();
}

DateTime parsePubdate(String pubDate) {
  String year = pubDate.substring(12, 16);
  String month = pubDate.substring(8, 11);
  String day = pubDate.substring(5, 7);
  String hour = pubDate.substring(17, 25); //Get the hour section [22:00:00]

  const kMonthDict = {
    'Jan': '01',
    'Feb': '02',
    'Mar': '03',
    'Apr': '04',
    'May': '05',
    'Jun': '06',
    'Jul': '07',
    'Aug': '08',
    'Sep': '09',
    'Oct': '10',
    'Nov': '11',
    'Dec': '12'
  };
  month = kMonthDict[month] ?? '00';
  return DateTime.parse('$year-$month-$day $hour');
}

List<Item> parseRSSForItems(RSSProvider provider, String body) {
  // title: <title>
  // author: <author>
  // pubDate: <pubDate>
  // category: <category>
  // description: <description>
  // magnetUrl: <enclosure url="magnet:?xt=urn:btih:..."/>
  // coverUrl: <description> <![CDATA[<img src="..."/>]]> </description>
  final doc = XmlDocument.parse(body);
  final itemElements = doc.findAllElements('item');
  final items = <Item>[];
  for (final itemElement in itemElements) {
    final title =
        itemElement.findElements(provider.itemNameTag).first.innerText;
    final author = provider.authorNameTag == null
        ? null
        : itemElement.findElements(provider.authorNameTag!).first.innerText;
    final pubDate =
        itemElement.findElements(provider.pubDateTag).first.innerText;
    final category = provider.categoryTag == null
        ? null
        : itemElement.findElements(provider.categoryTag!).first.innerText;
    final description =
        itemElement.findElements(provider.descriptionTag).first.innerText;
    final magnetUrl = provider.magnetUrlGetter?.call(itemElement);
    final coverUrl = provider.coverUrlGetter?.call(itemElement);
    final size = provider.fileSizeTag == null
        ? null
        : itemElement.findElements(provider.fileSizeTag!).first.innerText;
    // convert pubDate to local time
    final pubDateLocal = parsePubdate(pubDate);

    items.add(Item(
      name: title,
      author: author,
      pubDate: _dateFormatter.format(pubDateLocal),
      category: category,
      description: description,
      torrentUrl: magnetUrl,
      coverUrl: coverUrl,
      size: size,
    ));
  }
  return items;
}
