import 'package:flutter/widgets.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

import '/services/storage.dart';
import '/services/youtube.dart';
import '/style.dart';
import '/utils/string.dart';
import '/widgets/cached_image.dart';

part 'groupable.g.dart';

const tag10Bit = r'10\-?bit';
const tagFLAC = r'flac(\s+\d+kHz\/\d+bit)?';
const tagHD = r'(1920\s?x\s?1080|1080p|mp4|aac|avc|x264|x265|hevc)';
const tagMP3 = r'(MP3\s+)?\d{3}k';
const tagSD = r'(1280\s?x\s?720|720p)';
const tagDate = r'\d{4}([-\./])\d{1,2}\1\d{1,2}';

@JsonSerializable()
class Groupable {
  String name;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? _nameCleaned;

  @JsonKey(includeFromJson: false, includeToJson: false)
  String? _nameCleanedNoNum;

  @JsonKey(includeFromJson: false, includeToJson: false)
  Iterable<String>? episodeNumbers;

  @JsonKey(includeToJson: false, includeFromJson: false)
  String? _coverUrl;

  @JsonKey(includeToJson: false, includeFromJson: false)
  Widget? _coverImageWidget;

  Groupable? parent;

  String? group;

  Groupable({required this.name, this.parent});

  factory Groupable.fromJson(Map<String, dynamic> json) =>
      _$GroupableFromJson(json);

  String? get coverUrl =>
      parent?.coverUrl ??
      (_coverUrl ??= Storage.getString('cover-${(group ?? name).sha1Hash}'));

  set coverUrl(String? url) {
    if (url == null) {
      return;
    }
    if (parent != null) {
      parent!.coverUrl = url;
      return;
    }
    _coverUrl = url;
    Storage.setStringIfNotExists('cover-${(group ?? name).sha1Hash}', url);
  }

  String? get episode => episodeNumbers?.join(' - ');

  String get nameCleaned => _nameCleaned ??= Title(name).value;

  String get nameCleanedNoNum => _nameCleanedNoNum ??= nameCleaned
      .replaceAll(RegExp(r'\d+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String get nameHash => name.sha1Hash;

  String get title => name;

  Widget coverImageWidget() =>
      parent?.coverImageWidget() ??
      (_coverImageWidget ??= ClipRRect(
        borderRadius: BorderRadius.circular(6),
        child: CachedImage(
          key: ValueKey(coverUrl),
          url: coverUrl,
          fallbackGetter: defaultCoverUrlFallback,
          width: kListTileThumbnailWidth,
          fit: BoxFit.contain,
        ),
      ));

  Future<String?> defaultCoverUrlFallback() async {
    Logger().d('defaultCoverUrlFallback called for $nameCleanedNoNum');
    final coverUrl = await YouTube.search(nameCleanedNoNum).then(
        (value) => value.isEmpty ? null : value.first.value.first.coverUrl);
    this.coverUrl ??= coverUrl;
    return coverUrl;
  }

  Map<String, dynamic> toJson() => _$GroupableToJson(this);

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
    tagDate: ''
  };

  late String value;

  Title(String title) {
    StringBuffer suffixes = StringBuffer();
    for (final e in kTagRepr.entries) {
      if (RegExp(e.key, caseSensitive: false).hasMatch(title)) {
        suffixes.write(' ${e.value}');
      }
      title = title.replaceAll(RegExp(e.key, caseSensitive: false), '');
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

class UpdateNotifier extends ValueNotifier<void> {
  Groupable owner;
  UpdateNotifier(this.owner) : super(null) {
    Logger().d('UpdateNotifier created for ${owner.nameCleanedNoNum}');
  }
}

extension GroupHelpers<T extends Groupable> on List<T> {
  Map<String, List<T>> group() {
    final grouped = <String, List<T>>{};
    int i = 0;

    sort((a, b) => a.name.compareTo(b.name));

    final splitted = List.unmodifiable(map((e) => e.nameCleaned.split(' ')));

    List<String> root;
    int rootIndex;
    while (i < splitted.length) {
      root = splitted[i];
      rootIndex = i++;
      this[rootIndex].group ??= this[rootIndex].nameCleanedNoNum;
      grouped[this[rootIndex].group!] = [this[rootIndex]];

      if (!RegExp(r'\d+').hasMatch(this[rootIndex].name)) {
        continue;
      }
      Iterable<int>? episodeIndexes;
      while (i < splitted.length) {
        if (this[i].group != null) {
          grouped[this[i].group!] ??= [];
          grouped[this[i].group!]!.add(this[i]);
          ++i;
        } else if (root.length == splitted[i].length &&
            (root.length > 1 && root[1] == splitted[i][1]) &&
            root.last == splitted[i].last) {
          final current = splitted[i];
          this[i].group = this[rootIndex].group;
          this[i].parent = this[rootIndex];

          grouped[this[rootIndex].group]!.add(this[i]);
          episodeIndexes ??= List.generate(root.length, (index) => index)
              .where((index) => root[index] != current[index]);
          this[rootIndex].episodeNumbers ??=
              List.unmodifiable(episodeIndexes.map((index) => root[index]));
          this[i].episodeNumbers =
              List.unmodifiable(episodeIndexes.map((index) => current[index]));
          ++i;
        } else {
          break;
        }
      }
      if (grouped[this[rootIndex].group]!.length == 1) {
        grouped[this[rootIndex].nameCleaned] =
            grouped.remove(this[rootIndex].nameCleanedNoNum)!;
      }
    }

    return grouped;
  }
}
