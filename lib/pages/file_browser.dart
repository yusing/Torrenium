import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:path/path.dart' as pathlib;

import '/class/fs_entity.dart';
import '/interface/groupable.dart';
import '/services/torrent_mgr.dart';
import 'item_listview.dart';

class FileBrowser extends StatefulWidget {
  const FileBrowser({super.key});

  @override
  State<FileBrowser> createState() => _FileBrowserState();
}

class _FileBrowserState extends State<FileBrowser> {
  final _subpaths = <String>[];
  static const _kHiddenExt = [
    '.json',
    '.part',
    '.db',
    '.db-shm',
    '.db-wal',
    '.txt'
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: FutureBuilder(
          future: Directory(
                  pathlib.joinAll([gTorrentManager.saveDir, ..._subpaths]))
              .list()
              .where((entity) =>
                  !_kHiddenExt.contains(pathlib.extension(entity.path)))
              .map((entity) => GroupableFileSystemEntity(entity))
              .toList()
              .then((value) => value.group()),
          builder: (context, snapshot) {
            if (snapshot.hasError) {
              return Center(child: Text(snapshot.error.toString()));
            }
            if (snapshot.connectionState != ConnectionState.done) {
              return const Center(child: CupertinoActivityIndicator());
            }
            if (snapshot.data!.isEmpty) {
              return const Center(child: Text('Empty folder'));
            }
            return StreamBuilder(
                stream: Stream.periodic(1.seconds),
                builder: (context, _) {
                  return ItemListView(snapshot.data!);
                });
          }),
    );
  }
}
