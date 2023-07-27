import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:torrenium/style.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:torrenium/utils/torrent_manager.dart';
import 'package:torrenium/widgets/cached_image.dart';

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

class Item {
  final String name;
  final String description;
  final String? magnetUrl;
  final String pubDate;
  final String? category;
  final String? author;
  final String? coverUrl;
  final String? size;

  Item({
    required this.name,
    required this.description,
    required this.magnetUrl,
    this.category,
    this.author,
    this.coverUrl,
    this.size,
    required this.pubDate,
  });

  bool get isMagnet => magnetUrl != null && magnetUrl!.startsWith('magnet:');

  Widget get imageWidget {
    return ClipRect(
      child: CachedImage(
          url: coverUrl,
          fallbackGetter: coverPhotoFallback,
          width: kCoverPhotoWidth),
    );
  }

  Future<String> coverPhotoFallback() async {
    const kFinalFallback =
        'https://p.favim.com/orig/2018/08/16/anime-no-manga-Favim.com-6189353.png';
    final name = this
        .name
        // remove things in brackets including brackets: () [] {} 【】 ★★
        .replaceAll(RegExp(r'(\(|\[|\{|\【)[^\(\[\{【★]*(\)|\]|\}|\】)'), ' ')
        // remove all non english characters
        .replaceAll(RegExp(r'[^a-zA-Z]'), ' ')
        // remove all extra spaces
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final cacheKey = 'cover:$name';
    if (TorrentManager.prefs.containsKey(cacheKey)) {
      Logger().i('Using cached cover photo for $name');
      return TorrentManager.prefs.getString(cacheKey)!;
    }
    final searchUrl = Uri.parse(
        "https://kitsu.io/api/edge/anime?filter[text]=$name&page[limit]=1");
    final resp = await http.get(searchUrl);
    if (resp.statusCode == 200) {
      final body = resp.body;
      final dict = jsonDecode(body);
      final result = (dict["data"] as List?)?.first["attributes"]["posterImage"]
          ["original"];
      if (result != null) {
        final url = result as String;
        TorrentManager.prefs.setString(cacheKey, url);
        return url;
      }
    }
    Logger().e(resp.statusCode);
    return kFinalFallback;
  }
}
