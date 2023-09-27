import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:torrenium/services/http.dart';
import 'package:torrenium/services/rss_providers.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final url = kRssProviders.first.searchUrl(query: '');
  final body = await http.get(url).then((value) => value.body());
  final items = await kRssProviders.first.parseUrlForItems(body);
  final episodes = Map.fromEntries(
      items.map((e) => MapEntry(e.group, e.episode ?? e.nameCleaned)));
  final jsonStr = const JsonEncoder.withIndent('  ').convert(episodes);
  debugPrint(jsonStr);
}
