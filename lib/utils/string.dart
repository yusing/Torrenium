import 'dart:convert';

import 'package:crypto/crypto.dart';

extension TitleExtractor on String {
  String get cleanTitle => removeDelimiters('()[]{}【】★.-_')
      .replaceAll(RegExp(r'(1080|720)\s?p', caseSensitive: false), '')
      .replaceAll(
          RegExp(
              r'(HEVC|AAC|AVC|8bit|10bit|MKV|MP4|MP3|WEBRIP|BAHA|TVB|WEBDL|WEB-DL|招募.+)',
              caseSensitive: false),
          '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .replaceAll(RegExp(r'\d+'), '')
      .trim();
  String get sha1Hash => sha1.convert(utf8.encode(this)).toString();
  String get sha256Hash => sha256.convert(utf8.encode(this)).toString();

  String encodeUrl() {
    return Uri.encodeFull("file://$this");
  }

  String removeDelimiters(String delimiters) {
    String s = this;
    for (var delimiter in delimiters.split('')) {
      s = s.replaceAll(delimiter, ' ');
    }
    return s;
  }
}
