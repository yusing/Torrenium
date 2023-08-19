import 'dart:convert';

import '../interface/groupable.dart';
import '../services/http.dart';
import '../services/torrent_mgr.dart';

class Item extends Groupable {
  final String description;
  final String? torrentUrl;
  final String pubDate;
  final String? category;
  final String? author;
  final String? coverUrl;
  final String? size;

  Item({
    required super.name,
    required this.description,
    required this.torrentUrl,
    this.category,
    this.author,
    this.coverUrl,
    this.size,
    required this.pubDate,
  });

  Future<String> coverPhotoFallbackUrl() async {
    const kFinalFallback =
        'https://p.favim.com/orig/2018/08/16/anime-no-manga-Favim.com-6189353.png';
    final searchUrl =
        "https://kitsu.io/api/edge/anime?filter[text]=$nameCleanedNoNum&page[limit]=1";
    final body = await (await gCacheManager.getSingleFile(searchUrl,
            key: nameCleanedNoNum))
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
