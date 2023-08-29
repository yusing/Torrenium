import 'dart:io';

import 'package:path/path.dart' as pathlib;

import '/interface/download_item.dart';
import '/services/torrent_mgr.dart';
import '/utils/string.dart';

class GroupableFileSystemEntity extends DownloadItem {
  final FileSystemEntity entity;

  GroupableFileSystemEntity(this.entity)
      : super(
            name: pathlib.basename(entity.path),
            parent:
                gTorrentManager.findItem(pathlib.basename(entity.path).b64));

  @override
  List<DownloadItem> get files => isMultiFile
      ? List.of(Directory(entity.path)
          .listSync()
          .map((e) => GroupableFileSystemEntity(e)))
      : throw UnsupportedError('Not a directory');

  DownloadItem? get linked => super.parent as DownloadItem?;

  @override
  bool get isComplete => linked?.isComplete ?? true;

  @override
  bool get isMultiFile => entity is Directory;

  @override
  num get progress => linked?.progress ?? 0;

  @override
  int get bytesDownloaded => linked?.bytesDownloaded ?? 0;

  @override
  int get size => linked?.size ?? 0;

  @override
  String get videoPath => entity.path;
}
