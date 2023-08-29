import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

import '/services/settings.dart';
import '/services/storage.dart';
import '/style.dart';
import '/utils/file_types.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';
import '/widgets/cached_image.dart';

part 'groupable.g.dart';

const tag10Bit = r'10\-?bit';
const tagDate = r'\d{4}([-\./])\d{1,2}\1\d{1,2}';
const tagFLAC = r'flac(\s+\d+kHz\/\d+bit)?';
const tagHD = r'(1920\s?x\s?1080|1080p)';
const tagMP3 = r'(MP3\s+)?\d{3}k';
const tagRemove =
    r'(web\-?(dl|rip)|bd\-?rip|僅限.+地區|mp4|aac|avc|x26[45]|hevc|h\.26[45])';
const tagSD = r'(1280\s?x\s?720|720p)';

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

  Groupable? parent;

  String? group;

  Groupable({required this.name, this.parent});

  factory Groupable.fromJson(Map<String, dynamic> json) =>
      _$GroupableFromJson(json);

  String? get coverUrl => _coverUrl ??=
      (kStorage.getString('cover-${name.b64}') ?? parent?.coverUrl);

  set coverUrl(String? url) {
    if (url == null) {
      return;
    }
    if (parent != null) {
      parent!.coverUrl = url;
      return;
    }
    _coverUrl = url;
    kStorage.setString('cover-${name.b64}', url);
  }

  String? get episode {
    final e = episodeNumbers?.join(' - ');
    if (e == null) {
      return null;
    }
    if (int.tryParse(e) != null) {
      return 'Episode $e';
    }
    return e;
  }

  String get nameCleaned => _nameCleaned ??= Title(name).value;

  String get nameCleanedNoNum => _nameCleanedNoNum ??= nameCleaned
      .replaceAll(RegExp(r'\d+'), '')
      .replaceAll(RegExp(r'\s+'), ' ')
      .trim();

  String get id => name.b64;

  String get title => name;

  String get videoPath => throw UnimplementedError();

  Widget coverImageWidget([BoxFit fit = BoxFit.contain]) {
    final fType = FileTypeExt.from(name);
    switch (fType) {
      case FileType.image:
        if (Settings.textOnlyMode.value) {
          return const AdaptiveIcon(
            CupertinoIcons.photo_fill,
          );
        }
        return Image.file(
          File(videoPath),
          key: ValueKey(id),
          width: kListTileThumbnailWidth,
          fit: fit,
        );
      case FileType.folder:
      case FileType.video:
        if (Settings.textOnlyMode.value) {
          return fType == FileType.folder
              ? const AdaptiveIcon(
                  CupertinoIcons.folder_fill,
                )
              : const AdaptiveIcon(
                  CupertinoIcons.videocam_fill,
                );
        }
        return parent?.coverImageWidget() ??
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: CachedImage(
                key: ValueKey(coverUrl),
                url: coverUrl,
                fallbackGetter: defaultCoverUrlFallback,
                width: kListTileThumbnailWidth,
                fit: fit,
              ),
            );
      case FileType.audio:
        return const AdaptiveIcon(
          CupertinoIcons.music_note,
        );
      case FileType.subtitle:
        return const AdaptiveIcon(
          CupertinoIcons.doc_text_fill,
        );
      case FileType.archive:
        return const AdaptiveIcon(
          CupertinoIcons.archivebox_fill,
        );
      case FileType.link:
        return const AdaptiveIcon(
          CupertinoIcons.link,
        );
      default:
        return const AdaptiveIcon(
          CupertinoIcons.doc_fill,
        );
    }
  }

  Future<String?> defaultCoverUrlFallback() async {
    // Logger().d('defaultCoverUrlFallback called for $name');
    // final coverUrl = await YouTube.search(nameCleanedNoNum).then(
    //     (value) => value.isEmpty ? null : value.first.value.first.coverUrl);
    // this.coverUrl ??= coverUrl;
    // return coverUrl;
    return null;
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
    tagHD: '[HD]',
    tagSD: '[SD]',
    tag10Bit: '[10-bit]',
    tagFLAC: '[FLAC]',
    tagMP3: '[MP3]',
    tagDate: '',
    tagRemove: ''
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
            .replaceAll(RegExp(r'[\(\)\[\]（）【】★_\-－—\s+]'), ' ')
            // .replaceAll(RegExp(r'\s[a-zA-Z]+[\D\S]'), ' ')

            .replaceAll(RegExp(r'\s+'), ' ')
            .replaceAll(RegExp(r'(\[\]|\(\)|【】|（）)'), '')
            .trim()
            .replaceAll(RegExp(r'\.$'), '') +
        suffixes.toString());
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
    sort((a, b) => a.name.compareTo(b.name));

    if (!Settings.enableGrouping.value) {
      return {'Ungrouped': this};
    }
    final grouped = <String, List<T>>{};
    int i = 0;

    final splitted =
        List.of(map((e) => e.nameCleaned.split(RegExp(r'(\.|\s)'))));

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
      Iterable<int>? diffIndexes;
      while (i < splitted.length) {
        if (this[i].group != null) {
          grouped[this[i].group!] ??= [];
          grouped[this[i].group!]!.add(this[i]);
          ++i;
        } else if ((root.length > 1 &&
                splitted[i].length > 1 &&
                root[1] == splitted[i][1]) &&
            root.last == splitted[i].last) {
          var current = splitted[i];

          if (current.length < root.length) {
            // pad
            current = List.generate(
                root.length,
                (index) =>
                    index < current.length ? current[index] : root[index]);
          }
          this[i].group = this[rootIndex].group;
          this[i].parent = this[rootIndex];

          grouped[this[rootIndex].group]!.add(this[i]);
          diffIndexes ??= List.generate(root.length, (index) => index)
              .where((index) => root[index] != current[index]);
          this[rootIndex].episodeNumbers ??=
              List.unmodifiable(diffIndexes.map((index) => root[index]));
          this[i].episodeNumbers =
              List.unmodifiable(diffIndexes.map((index) => current[index]));
          ++i;
        } else {
          break;
        }
      }
      if (grouped[this[rootIndex].group]!.length == 1) {
        grouped[this[rootIndex].nameCleaned] =
            grouped.remove(this[rootIndex].group)!;
        this[rootIndex].group = this[rootIndex].nameCleaned;
      }
    }

    return grouped;
  }
}

extension GroupExt<T extends Groupable> on Map<String, List<T>> {
  List<T> flatten() => values.expand((e) => e).toList();
}
