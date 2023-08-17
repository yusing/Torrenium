import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'package:xml/xml.dart';

import '../classes/item.dart';
import '../classes/rss_result_group.dart';
import '../services/http.dart';
import '../services/storage.dart';
import '../widgets/rss_tab.dart';
import 'rss_providers.dart';

final DateFormat _dateFormatter = DateFormat('yyyy-MM-dd HH:mm:ss');

Future<List<Item>> getRSSItems(RSSProvider provider, String url) async {
  String? body;
  if (!kDebugMode && Storage.hasCache(url)) {
    body = Storage.getCache(url);
  } else {
    final resp = await http.get(url, headers: {
      'Content-Type': 'application/xml',
      'Accept': 'application/xml',
      'Encoding': 'UTF-8',
    });
    if (resp.statusCode == 200) {
      body = await resp.body();
      if (!kDebugMode) {
        await Storage.setCache(url, body, const Duration(minutes: 3));
      }
    } else {
      Logger().e('${resp.statusCode} $url');
    }
  }
  if (body == null) {
    return [];
  }
  return parseRSSForItems(provider, body);
}

Future<Map<String, List<Item>>> getRSSItemsGrouped(
    RSSProvider provider, String url) async {
  var items = await getRSSItems(provider, url);
  items.sort((a, b) => a.nameNoNum.compareTo(b.nameNoNum));

  Map<String, List<Item>> grouped = {};

  while (items.isNotEmpty) {
    final root = items.removeAt(0);
    if (items.isEmpty || root.numbersInName.isEmpty) {
      grouped[items.first.nameCleaned] = [items.first];
      continue;
    }

    List<int>? episodeIndexes;
    grouped[root.nameNoNum] = [root];

    for (int i = 0; i < items.length;) {
      var current = items.first;
      if (current.numbersInName.isEmpty) {
        grouped[current.nameCleaned] = [current];
        continue;
      }
      if (root.nameNoNum != current.nameNoNum) {
        break;
      }
      current = items.removeAt(0);

      if (root.numbersInName.length != current.numbersInName.length) {
        current.episode = current.numbersInName.toSet().toList()..sort();
        grouped[root.nameNoNum]!.add(current);
        break;
      }
      if (episodeIndexes == null) {
        episodeIndexes = <int>[];
        for (int j = 0; j < root.numbersInName.length; ++j) {
          if (current.numbersInName[j] != root.numbersInName[j]) {
            episodeIndexes.add(j);
          }
        }
      }
      final group = grouped[root.nameNoNum]!;
      root.episode ??= episodeIndexes.map((i) => root.numbersInName[i]).toList()
        ..sort();
      current.episode =
          episodeIndexes.map((i) => current.numbersInName[i]).toList()..sort();
      group.add(current);
    }
  }

  return grouped;
}

Future<List<RssResultGroup>> getRSSResults(
    RSSProvider provider, String url) async {
  if (provider.supportTitleGroup) {
    return (await getRSSItemsGrouped(provider, url))
        .entries
        .map((e) => RssResultGroup(e))
        .toList();
  }
  return (await getRSSItems(provider, url))
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
