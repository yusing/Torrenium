import 'dart:convert';

import 'package:crypto/crypto.dart';

extension StringExt on String {
  String get sha1Hash => sha1.convert(utf8.encode(this)).toString();
  String get sha256Hash => sha256.convert(utf8.encode(this)).toString();

  String removeDelimiters(String delimiters) {
    String s = this;
    for (var delimiter in delimiters.split('')) {
      s = s.replaceAll(delimiter, ' ');
    }
    return s;
  }
}
