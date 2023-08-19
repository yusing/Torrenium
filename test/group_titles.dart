import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:torrenium/utils/fetch_rss.dart';
import 'package:torrenium/utils/rss_providers.dart';

Future<void> main() async {
  final url = kRssProviders.first.searchUrl();
  final items = await getRSSResults(kRssProviders.first, url);
  final episodes = Map.fromEntries(items.map((e) => MapEntry(
      e.title, e.items.map((i) => i.episodeNumbers?.join('-')).toList())));
  final jsonStr = const JsonEncoder.withIndent('  ').convert(episodes);
  debugPrint(jsonStr);
}
