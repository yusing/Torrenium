import 'package:path/path.dart' as pathlib;

// final Map<String, IconData> extIcons = {
//   '.mp4': FontAwesomeIcons.fileVideo,
//   '.mkv': FontAwesomeIcons.fileVideo,
//   '.avi': FontAwesomeIcons.fileVideo,
//   '.mp3': FontAwesomeIcons.fileAudio,
//   '.flac': FontAwesomeIcons.fileAudio,
//   '.m4a': FontAwesomeIcons.fileAudio,
//   '.jpg': FontAwesomeIcons.fileImage,
//   '.jpeg': FontAwesomeIcons.fileImage,
//   '.png': FontAwesomeIcons.fileImage,
//   '.gif': FontAwesomeIcons.fileImage,
//   '.pdf': FontAwesomeIcons.filePdf,
//   '.zip': FontAwesomeIcons.fileZipper,
//   '.rar': FontAwesomeIcons.fileZipper,
//   '.7z': FontAwesomeIcons.fileZipper,
//   '.tar': FontAwesomeIcons.fileZipper,
//   '.ass': FontAwesomeIcons.fileLines,
//   '.srt': FontAwesomeIcons.fileLines,
//   '.url': FontAwesomeIcons.link,
// };

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
  FileType.folder: ['']
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
  folder
}

extension FileTypeExt on FileType {
  static FileType from(String path) {
    final ext = pathlib.extension(path);
    for (final e in kExtMap.entries) {
      if (e.value.contains(ext)) {
        return e.key;
      }
    }
    return FileType.document;
  }
} 

// IconData getPathIcon(String path) {
//   if (Directory(path).existsSync()) {
//     return FontAwesomeIcons.folder;
//   }
//   String ext = '.${pathlib.extension(path).split('.').last}';
//   return extIcons[ext] ?? FontAwesomeIcons.file;
// }
