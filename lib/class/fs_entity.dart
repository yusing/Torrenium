import 'dart:io';

import 'package:path/path.dart' as pathlib;

import '/interface/download_item.dart';
import '/services/torrent_mgr.dart';
import '/utils/string.dart';

class GroupableFileSystemEntity extends DownloadItem {
  final FileSystemEntity entity;
  final DownloadItem? linked;

  GroupableFileSystemEntity(this.entity)
      : linked =
            gTorrentManager.findItem(pathlib.basename(entity.path).sha1Hash),
        super(name: pathlib.basename(entity.path)) {
    super.parent = linked;
  }

  @override
  List<DownloadItem> get files => isMultiFile
      ? List.of(Directory(entity.path)
          .listSync()
          .map((e) => GroupableFileSystemEntity(e)))
      : throw UnsupportedError('Not a directory');

  @override
  bool get isComplete => linked?.isComplete ?? true;

  @override
  bool get isMultiFile => entity is Directory;

  @override
  num get progress => linked?.progress ?? 0;

  @override
  String get videoPath => entity.path;
}
