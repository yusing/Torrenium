import 'dart:convert';
import 'dart:io';

import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http_pkg;
import 'package:logger/logger.dart';

final http = TorreniumHttpFileService();
final gCacheManager = CacheManager(Config('torreniumCacheManager',
    stalePeriod: 7.days, maxNrOfCacheObjects: 100, fileService: http));
final gCacheManagerShortTerm = CacheManager(Config('torreniumCacheManager',
    stalePeriod: 1.minutes, maxNrOfCacheObjects: 10, fileService: http));

class TorreniumHttpFileService extends FileService {
  TorreniumHttpFileService({HttpClient? httpClient});

  @override
  Future<TorreniumHttpResponse> get(String url,
      {Map<String, String>? headers = const {}}) async {
    if (url.isEmpty) {
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

class TorreniumHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback =
          (X509Certificate cert, String host, int port) => true;
  }
}
