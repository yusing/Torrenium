import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as pathlib;
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

final Map<String, IconData> extIcons = {
  '.mp4': FontAwesomeIcons.fileVideo,
  '.mkv': FontAwesomeIcons.fileVideo,
  '.avi': FontAwesomeIcons.fileVideo,
  '.mp3': FontAwesomeIcons.fileAudio,
  '.flac': FontAwesomeIcons.fileAudio,
  '.m4a': FontAwesomeIcons.fileAudio,
  '.jpg': FontAwesomeIcons.fileImage,
  '.jpeg': FontAwesomeIcons.fileImage,
  '.png': FontAwesomeIcons.fileImage,
  '.gif': FontAwesomeIcons.fileImage,
  '.pdf': FontAwesomeIcons.filePdf,
  '.zip': FontAwesomeIcons.fileZipper,
  '.rar': FontAwesomeIcons.fileZipper,
  '.7z': FontAwesomeIcons.fileZipper,
  '.tar': FontAwesomeIcons.fileZipper,
  '.ass': FontAwesomeIcons.fileLines,
  '.srt': FontAwesomeIcons.fileLines,
  '.url': FontAwesomeIcons.link,
};

IconData getPathIcon(String path) {
  if (Directory(path).existsSync()) {
    return FontAwesomeIcons.folder;
  }
  String ext = '.${pathlib.extension(path).split('.').last}';
  return extIcons[ext] ?? FontAwesomeIcons.file;
}
