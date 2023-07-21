import 'dart:io';

import 'package:flutter/material.dart';
import 'package:logger/logger.dart';
import 'package:torrenium/style.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
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
  final String? category;
  final String? author;
  final String? magnetUrl;
  final String? torrentUrl;
  final String? coverUrl;
  final String? size;
  final String pubDate;

  Item({
    required this.name,
    required this.description,
    this.category,
    this.author,
    this.magnetUrl,
    this.torrentUrl,
    this.coverUrl,
    this.size,
    required this.pubDate,
  }) : assert(
          !(magnetUrl == null && torrentUrl == null),
        );

  Widget get imageWidget {
    return ClipRect(
      child: CachedImage(
          url: coverUrl ??
              'https://p.favim.com/orig/2018/08/16/anime-no-manga-Favim.com-6189353.png',
          width: kCoverPhotoWidth),
    );
  }
}
