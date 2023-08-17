import 'dart:convert';

import '../services/http.dart';
import '../services/torrent.dart';
import '../utils/string.dart';

class Item {
  final String name;
  final String description;
  final String? torrentUrl;
  final String pubDate;
  final String? category;
  final String? author;
  final String? coverUrl;
  final String? size;
  late final String nameCleaned;
  late final List<int> numbersInName;
  late final String nameNoNum;

  Iterable<int>? episode;

  Item({
    required this.name,
    required this.description,
    required this.torrentUrl,
    this.category,
    this.author,
    this.coverUrl,
    this.size,
    required this.pubDate,
  }) {
    nameCleaned = name
        .removeDelimiters('()[]{}【】★.-_')
        .replaceAll(
            RegExp(r'((1920\s?x\s?)?1080|(1280\s?x\s?)?720)\s?p?',
                caseSensitive: false),
            '')
        .replaceAll(
            RegExp(
                r'(HEVC|AAC|AVC|8bit|10bit|MKV|MP4|MP3|WEBRIP|BAHA|TVB|WEBDL|WEB-DL|招募.+)',
                caseSensitive: false),
            '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    numbersInName = RegExp(r'\d+')
        .allMatches(nameCleaned)
        .map((m) => int.parse(m.group(0)!))
        .toList();
    nameNoNum = nameCleaned
        .replaceAll(RegExp(r'\d+'), '')
        .replaceAll(RegExp(r'\s+'), ' ');
  }

  Future<String> coverPhotoFallback() async {
    const kFinalFallback =
        'https://p.favim.com/orig/2018/08/16/anime-no-manga-Favim.com-6189353.png';
    final searchUrl =
        "https://kitsu.io/api/edge/anime?filter[text]=$nameNoNum&page[limit]=1";
    final body = await (await gCacheManager.getSingleFile(searchUrl))
        .readAsString()
        .onError((error, stackTrace) => '{}');
    final results = jsonDecode(body)["data"] as List?;
    if (results == null || results.isEmpty) {
      return kFinalFallback;
    }
    final result = results.first["attributes"]["posterImage"]["original"];
    return result ?? kFinalFallback;
  }

  Future<void> startDownload() async {
    await gTorrentManager.downloadItem(this);
  }
}
