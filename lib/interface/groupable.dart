import 'package:flutter/foundation.dart';

import '../utils/string.dart';

class Groupable {
  String name;
  String? _nameCleaned;
  List<int>? _numbersInName;
  String? _nameCleanedNoNum;
  Iterable<int>? episodeNumbers;
  ValueNotifier<void> updateNotifier = ValueNotifier(null);
  bool? _isMusic;

  Groupable({required this.name});

  String? get episode =>
      episodeNumbers == null ? null : 'Episode ${episodeNumbers?.join(" - ")}';

  String get group => nameCleanedNoNum;

  bool get isMusic => _isMusic ??=
      RegExp(r'(flac|mp3|320k)', caseSensitive: false).hasMatch(name);

  String get nameCleaned => _nameCleaned ??= name
      .removeDelimiters('()[]{}【】★.-_')
      .replaceAll(
          RegExp(r'((1920\s?x\s?)?1080|(1280\s?x\s?)?720)\s?p?',
              caseSensitive: false),
          '')
      .replaceAll(
          RegExp(
              r'(x264|HEVC|AAC|AVC|8bit|10bit|MKV|MP4|MP3|WEBRIP|BAHA|TVB|WEB[\-\s]?DL|招募.+)',
              caseSensitive: false),
          '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String get nameCleanedNoNum => _nameCleanedNoNum ??= nameCleaned
      .replaceAll(RegExp(r'\d+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<int> get numbersInName => _numbersInName ??= RegExp(r'\d+')
      .allMatches(nameCleaned)
      .map((m) => int.parse(m.group(0)!))
      .toList();
}

extension GroupHelpers<T extends Groupable> on List<T> {
  Map<String, List<T>> group() {
    sort((a, b) => a.nameCleanedNoNum.compareTo(b.nameCleanedNoNum));

    Map<String, List<T>> grouped = {};

    int i = 0;
    while (i < length) {
      final root = this[i++];
      if (isEmpty || root.numbersInName.isEmpty || root.isMusic) {
        // music
        grouped[root.nameCleaned] = [root];
        continue;
      }

      List<int>? episodeIndexes;
      final group = grouped[root.nameCleanedNoNum] = [root];
      while (i < length) {
        final current = this[i];

        if (current.numbersInName.isEmpty ||
            root.nameCleanedNoNum != current.nameCleanedNoNum ||
            root.numbersInName.length != current.numbersInName.length) {
          break;
        }
        if (episodeIndexes == null) {
          episodeIndexes = <int>[];
          for (int j = 0; j < root.numbersInName.length; ++j) {
            if (current.numbersInName[j] != root.numbersInName[j]) {
              episodeIndexes.add(j);
            }
          }
        }
        root.episodeNumbers ??= episodeIndexes
            .map((index) => root.numbersInName[index])
            .toList(growable: false);
        current.episodeNumbers ??= episodeIndexes
            .map((index) => current.numbersInName[index])
            .toList(growable: false);
        group.add(current);
        ++i;
      }
    }

    return grouped;
  }
}
