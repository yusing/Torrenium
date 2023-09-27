import 'dart:io';

import 'package:path/path.dart' as pathlib;

final kExtMap = <FileType, List<String>>{
  FileType.video: ['.mp4', '.mkv', '.avi'],
  FileType.audio: ['.mp3', '.flac', '.m4a', '.opus', '.aiff', '.dsd', '.dsf'],
  FileType.image: ['.jpg', '.jpeg', '.png', '.bmp', '.gif'],
  FileType.archive: [
    '.zip',
    '.rar',
    '.7z',
    '.tar',
    '.tgz',
    '.tar.gz',
    '.tar.bz',
    '.zst'
  ],
  FileType.subtitle: ['.ass', '.srt'],
  FileType.pdf: ['.pdf'],
  FileType.unknown: ['']
};

//TODO: svg (maybe unnecessary)

enum FileType {
  video,
  audio,
  image,
  pdf,
  archive,
  link,
  subtitle,
  document,
  folder,
  unknown
}

extension FileTypeExt on FileType {
  static FileType from(String path) {
    if (FileSystemEntity.isDirectorySync(path)) {
      return FileType.folder;
    }
    final ext = pathlib.extension(path);
    for (final e in kExtMap.entries) {
      if (e.value.contains(ext)) {
        return e.key;
      }
    }
    return FileType.document;
  }
}
