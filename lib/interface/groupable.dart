import 'package:flutter/foundation.dart';
import 'package:json_annotation/json_annotation.dart';

part 'groupable.g.dart';

const tag10Bit = r'10\-?bit';
const tagFLAC = r'flac(\s+\d+kHz\/\d+bit)?';
const tagHD = r'(1920\s?x\s?1080|1080p|mp4|aac|avc|x264|x265|hevc)';
const tagMP3 = r'(MP3\s+)?\d{3}k';
const tagSD = r'(1280\s?x\s?720|720p)';

@JsonSerializable()
class Groupable {
  String name;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? _nameCleaned;

  @JsonKey(includeFromJson: false, includeToJson: false)
  List<int>? _numbersInName;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? _nameCleanedNoNum;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Iterable<String>? episodeNumbers;

  @JsonKey(includeFromJson: false, includeToJson: false)
  ValueNotifier<void> updateNotifier = ValueNotifier(null);

  @JsonKey(includeFromJson: false, includeToJson: false)
  bool? _isMusic;

  @JsonKey(includeFromJson: false, includeToJson: false)
  List<int>? episodeIndexes;

  Groupable({required this.name});

  String? get episode => episodeNumbers?.join(" - ");
  String get group => nameCleanedNoNum;
  bool get isMusic => _isMusic ??=
      RegExp(r'(flac|mp3|320k)', caseSensitive: false).hasMatch(name);
  String get nameCleaned => _nameCleaned ??= Title(name).value;
  String get nameCleanedNoNum => _nameCleanedNoNum ??= nameCleaned
      .replaceAll(RegExp(r'\d+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  List<int> get numbersInName => _numbersInName ??= RegExp(r'\d+')
      .allMatches(nameCleaned)
      .map((m) => int.parse(m.group(0)!))
      .toList()
    ..sort();

  String get title => name;

  void updateEpisodes(List<int> indexes) {
    final splitted = nameCleaned.split(' ');
    episodeNumbers =
        indexes.map((index) => splitted[index]).toList(growable: false);
  }
}

class Title {
  static const kTagRepr = {
    tagHD: '1080P',
    tagSD: '720P',
    tag10Bit: '10-bit',
    tagFLAC: 'FLAC Music',
    tagMP3: 'MP3 Music',
  };

  final hasTag = {
    tagHD: false,
    tagSD: false,
    tag10Bit: false,
    tagFLAC: false,
    tagMP3: false,
  };

  late String value;

  Title(String title) {
    StringBuffer suffixes = StringBuffer();
    for (final tag in hasTag.keys) {
      hasTag[tag] = RegExp(tag, caseSensitive: false).hasMatch(title);
      if (hasTag[tag]!) {
        suffixes.write(' ${kTagRepr[tag]}');
      }
    }
    for (final tag in hasTag.keys) {
      title = title.replaceAll(RegExp(tag, caseSensitive: false), '');
    }
    value = (title
                .replaceFirst(RegExp('內[嵌封]'), '')
                .replaceAll(RegExp(r'[\(\)\[\]\{\}（）【】★_\-－——\s+]'), ' ')
                .replaceAll(RegExp(r'\s[a-zA-Z]+\D^!'), ' ') +
            suffixes.toString())
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}

extension GroupHelpers<T extends Groupable> on List<T> {
  Map<String, List<T>> group() {
    sort((a, b) => a.name.compareTo(b.name));
    final grouped = <String, List<T>>{};
    final splitted =
        map((e) => e.nameCleaned.split(' ')).toList(growable: false);

    int i = 0;
    List<String> root;
    int rootIndex;
    while (i < splitted.length) {
      root = splitted[i];
      rootIndex = i++;
      grouped[this[rootIndex].nameCleanedNoNum] = [this[rootIndex]];

      if (!RegExp(r'\d+').hasMatch(this[rootIndex].name)) {
        continue;
      }

      while (i < splitted.length &&
          root.length == splitted[i].length &&
          (root.length > 1 && root[1] == splitted[i][1]) &&
          root.last == splitted[i].last) {
        final current = splitted[i];

        grouped[this[rootIndex].nameCleanedNoNum]!.add(this[i]);
        this[rootIndex].episodeIndexes = <int>[];
        for (int j = 0; j < root.length; ++j) {
          if (root[j] != current[j]) {
            this[rootIndex].episodeIndexes!.add(j);
          }
        }
        this[rootIndex].episodeNumbers ??= this[rootIndex]
            .episodeIndexes!
            .map((index) => root[index])
            .toList(growable: false);
        this[i].episodeIndexes = this[rootIndex].episodeIndexes;
        this[i].episodeNumbers = this[rootIndex]
            .episodeIndexes!
            .map((index) => current[index])
            .toList(growable: false);
        ++i;
      }
      if (grouped[this[rootIndex].nameCleanedNoNum]!.length == 1) {
        final old = grouped.remove(this[rootIndex].nameCleanedNoNum);
        grouped[this[rootIndex].nameCleaned] = old!;
      }
    }

    return grouped;
  }
}
