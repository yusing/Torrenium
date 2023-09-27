import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:json_annotation/json_annotation.dart';

import '/pages/document_viewer.dart';
import '/utils/file_types.dart';
import '/utils/fs.dart';
import '/utils/show_snackbar.dart';
import '/widgets/adaptive.dart';
import 'groupable.dart';
import 'playable.dart';

part 'download_item.g.dart';

@JsonSerializable()
class DownloadItem extends Groupable with ChangeNotifier, Playable {
  @JsonKey(includeToJson: false, includeFromJson: false)
  int bytesDownloaded, size;
  @JsonKey(includeToJson: false, includeFromJson: false)
  num _progress;
  @JsonKey(includeToJson: false, includeFromJson: false)
  bool isHidden = false;

  @JsonKey(includeToJson: false, includeFromJson: false)
  @protected
  DateTime timeStarted;

  @JsonKey(includeToJson: false, includeFromJson: false)
  @protected
  num progressInitial;

  DownloadItem(
      {num progress = 0.0,
      required super.name,
      super.parent,
      this.bytesDownloaded = 0,
      this.size = 0})
      : timeStarted = DateTime.now(),
        _progress = progress,
        progressInitial = progress;

  factory DownloadItem.fromJson(Map<String, dynamic> json) =>
      _$DownloadItemFromJson(json);

  @override
  String get displayName {
    return isMultiFile ? '$nameCleaned (${files.length} items)' : nameCleaned;
  }

  double get etaSecs {
    return progress == 0
        ? double.infinity
        : (DateTime.now().difference(timeStarted).inSeconds /
            (progress - progressInitial));
  }

  bool get exists => isMultiFile
      ? Directory(fullPath).existsSync()
      : File(fullPath).existsSync();

  List<DownloadItem> get files => throw UnimplementedError();
  bool get isComplete => progress == 1.0 && bytesDownloaded == size;

  bool get isMultiFile => false;
  bool get isPlaceholder => false;
  bool get isUrl => fullPath.startsWith('https://');

  num get progress => _progress;
  set progress(num value) {
    if (value == _progress) return;
    _progress = value;
    notifyListeners();
  }

  @override
  Future<void> delete() async {
    isHidden = true;
    notifyListeners();
    if (isMultiFile) {
      await fullPath.deleteDir();
    } else {
      await fullPath.deleteFile();
    }
  }

  Future<void> open() async {
    // TODO: handle for different file type
    if (!isUrl) {
      if (!(File(fullPath).existsSync())) {
        showSnackBar('File not found', fullPath);
        return;
      }
      switch (FileTypeExt.from(fullPath)) {
        case FileType.video:
          await showVideoPlayer();
          break;
        case FileType.document:
        case FileType.subtitle:
          await showAdaptivePopup(
              builder: (context) => DocumentViewer(path: fullPath));
          break;
        default:
          showSnackBar(
              'File type not supported', FileTypeExt.from(fullPath).name);
      }
    }
  }

  @override
  Map<String, dynamic> toJson() => _$DownloadItemToJson(this);
}
