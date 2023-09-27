import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as pathlib;

import '/class/fs_entity.dart';
import '/interface/groupable.dart';
import '/services/torrent_mgr.dart';
import 'item_listview.dart';

const _kHiddenExt = [
  '.json',
  '.part',
  '.db',
  '.db-shm',
  '.db-wal',
  '.gs',
  '.bak',
  '.torrent',
];

const _kRootHidden = ['data', 'trackers.txt'];

class FileBrowser extends StatelessWidget {
  final String? path;

  const FileBrowser({super.key, this.path});

  @override
  Widget build(BuildContext context) {
    final dir = Directory(pathlib.join(path ?? gTorrentManager.saveDir));
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: StreamBuilder(
          stream: dir.watch(
              events: FileSystemEvent.create |
                  FileSystemEvent.delete |
                  FileSystemEvent.move),
          builder: (context, _) {
            return FutureBuilder(
                future: dir
                    .list()
                    .where((entity) =>
                        !_kHiddenExt.contains(pathlib.extension(entity.path)) &&
                        (path != null ||
                            !_kRootHidden
                                .contains(pathlib.basename(entity.path))))
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
                  return ItemListView(snapshot.data!);
                });
          }),
    );
  }
}
