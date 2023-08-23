import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:torrenium/interface/groupable.dart';
import 'package:torrenium/services/http.dart';
import 'package:torrenium/services/rss_providers.dart';
import 'package:torrenium/utils/fetch_rss.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = kRssProviders.first.searchUrl();
  final body = await http.get(url).then((value) => value.body());
  final items = parseRSSForItems(kRssProviders.first, body).group();
  final episodes = Map.fromEntries(items.entries.map((e) => MapEntry(e.key,
      e.value.map((item) => item.episode ?? item.nameCleaned).toList())));
  final jsonStr = const JsonEncoder.withIndent('  ').convert(episodes);
  debugPrint(jsonStr);
}
