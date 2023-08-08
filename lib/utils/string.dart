import 'dart:convert';

import 'package:crypto/crypto.dart';

extension TitleExtractor on String {
  String
      get cleanTitle => // remove things in brackets including brackets: () [] {} 【】 ★★
          replaceAll(RegExp(r'(\(|\[|\{|\【)[^\(\[\{【★]*(\)|\]|\}|\】)'), ' ')
              // remove all non english characters
              .replaceAll(RegExp(r'[^a-zA-Z]'), ' ')
              // remove all extra spaces
              .replaceAll(RegExp(r'\s+'), ' ')
              .trim();
  String get sha256Hash => sha256.convert(utf8.encode(this)).toString();
}
