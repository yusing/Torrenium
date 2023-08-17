import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:torrenium/utils/fetch_rss.dart';
import 'package:torrenium/utils/rss_providers.dart';

Future<void> main() async {
  final url = kRssProviders.first.searchUrl(query: '英雄王');
  final items = await getRSSItemsGrouped(kRssProviders.first, url);
  final episodes = Map.fromEntries(items.entries.map((e) =>
      MapEntry(e.key, e.value.map((i) => i.episode?.join('-')).toList())));
  final jsonStr = const JsonEncoder.withIndent('  ').convert(episodes);
  debugPrint(jsonStr);
}
