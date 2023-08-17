import 'dart:convert';
import 'dart:io';

import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http_pkg;
import 'package:logger/logger.dart';

final http = TorreniumHttpFileService();
final gCacheManager = TorreniumCacheManager();

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
  Future<TorreniumHttpResponse> get(String url,
      {Map<String, String>? headers = const {}}) async {
    if (url == "") {
      return TorreniumHttpResponse(
          http_pkg.StreamedResponse(Stream.value([]), 404, contentLength: 0));
    }
    final Uri resolved = Uri.base.resolve(url);
    try {
      final response = await http_pkg.readBytes(resolved, headers: headers);
      return TorreniumHttpResponse(http_pkg.StreamedResponse(
          Stream.value(response), 200,
          contentLength: response.length));
    } catch (e) {
      Logger().e(e);
      return TorreniumHttpResponse(
          http_pkg.StreamedResponse(Stream.value([]), 404, contentLength: 0));
    }
  }
}

class TorreniumHttpResponse extends HttpGetResponse {
  TorreniumHttpResponse(http_pkg.StreamedResponse resp) : super(resp);

  Future<String> body() async {
    if (contentLength != null) {
      if (contentLength == 0) {
        return '';
      }
      final bodyBytes = List.filled(contentLength!, 0);
      var i = 0;
      await for (var bytes in content) {
        bodyBytes.setRange(i, i + bytes.length, bytes);
        i += bytes.length;
      }
      assert(i == contentLength);
      return utf8.decode(bodyBytes);
    }
    return utf8.decodeStream(content);
  }
}
