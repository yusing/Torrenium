import 'dart:io';

extension StringPathExt on String {
  Future<void> createDir() async {
    final dir = Directory(this);
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
  }

  Future<void> deleteDir() async {
    final dir = Directory(this);
    if (await dir.exists()) {
      await dir.delete(recursive: true);
    }
  }

  Future<void> deleteFile() async {
    final file = File(this);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<bool> dirExists() async {
    return await Directory(this).exists();
  }

  Future<bool> fileExists() async {
    return await File(this).exists();
  }
}
