import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:logger/logger.dart';

import '../services/storage.dart';
import '../utils/string.dart';
import '../utils/torrent_manager.dart';

class Item {
  final String name;
  final String description;
  final String? torrentUrl;
  final String pubDate;
  final String? category;
  final String? author;
  final String? coverUrl;
  final String? size;

  Item({
    required this.name,
    required this.description,
    required this.torrentUrl,
    this.category,
    this.author,
    this.coverUrl,
    this.size,
    required this.pubDate,
  });

  Future<String> coverPhotoFallback() async {
    const kFinalFallback =
        'https://p.favim.com/orig/2018/08/16/anime-no-manga-Favim.com-6189353.png';
    final name = this.name.cleanTitle;
    final cacheKey = 'cover:$name';
    if (Storage.hasCache(cacheKey)) {
      return Storage.getCache(cacheKey);
    }
    final searchUrl = Uri.parse(
        "https://kitsu.io/api/edge/anime?filter[text]=$name&page[limit]=1");
    final resp = await http.get(searchUrl);
    if (resp.statusCode == 200) {
      final body = utf8.decode(resp.bodyBytes);
      final results = jsonDecode(body)["data"] as List?;
      if (results == null || results.isEmpty) {
        return kFinalFallback;
      }
      final result = results.first["attributes"]["posterImage"]["original"];
      if (result != null) {
        final url = result as String;
        await Storage.setCache(cacheKey, url, const Duration(days: 7));
        return url;
      }
    }
    Logger().e(resp.statusCode);
    return kFinalFallback;
  }

  Future<void> startDownload() async {
    await gTorrentManager.downloadItem(this);
  }
}

class TorreniumCacheManager extends CacheManager {
  static const key = 'torreniumCacheManager';

  static TorreniumCacheManager? _instance;

  factory TorreniumCacheManager() {
    _instance ??= TorreniumCacheManager._();
    return _instance!;
  }

  TorreniumCacheManager._()
      : super(Config(key,
            stalePeriod: const Duration(days: 7),
            maxNrOfCacheObjects: 100,
            fileService: TorreniumHttpFileService()));
}

class TorreniumHttpFileService extends FileService {
  TorreniumHttpFileService({HttpClient? httpClient});

  @override
  Future<FileServiceResponse> get(String url,
      {Map<String, String>? headers = const {}}) async {
    if (url == "") {
      return HttpGetResponse(
          http.StreamedResponse(Stream.value([]), 404, contentLength: 0));
    }
    final Uri resolved = Uri.base.resolve(url);
    try {
      final response = await http.readBytes(resolved, headers: headers);
      return HttpGetResponse(http.StreamedResponse(Stream.value(response), 200,
          contentLength: response.length));
    } catch (e) {
      Logger().e(e);
      return HttpGetResponse(
          http.StreamedResponse(Stream.value([]), 404, contentLength: 0));
    }
  }
}
