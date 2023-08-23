import 'dart:convert';

import '/interface/groupable.dart';
import '/services/http.dart';
import '/services/torrent_mgr.dart';

class Item extends Groupable {
  final String description;
  final String? torrentUrl;
  final DateTime? pubDate;
  final String? category;
  final String? author;
  final String? coverUrl;
  final String? size;
  final int? viewCount, likeCount;

  Item(
      {required super.name,
      required this.description,
      required this.torrentUrl,
      required this.pubDate,
      this.category,
      this.author,
      this.coverUrl,
      this.size,
      this.viewCount,
      this.likeCount});

  Future<String> coverPhotoFallbackUrl() async {
    const kFinalFallback =
        'https://p.favim.com/orig/2018/08/16/anime-no-manga-Favim.com-6189353.png';
    final searchUrl =
        "https://kitsu.io/api/edge/anime?filter[text]=$nameCleanedNoNum&page[limit]=1";
    final body = await (await gCacheManager.getSingleFile(searchUrl,
            key: nameCleanedNoNum,
            headers: {
          'Accept-Language': 'zh-HK,zh;q=0.9,en-US;q=0.8,en;q=0.7'
        }))
        .readAsString()
        .onError((error, stackTrace) => '{}');
    // Logger().d(body);
    final results = jsonDecode(body)["data"] as List?;
    if (results == null || results.isEmpty) {
      return kFinalFallback;
    }
    final attrs = results.first["attributes"];
    final result =
        attrs["posterImage"]["original"] ?? attrs["coverImage"]["original"];
    return result ?? kFinalFallback;
  }

  Future<void> startDownload() async {
    await gTorrentManager.downloadItem(this);
  }
}
