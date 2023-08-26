import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:path/path.dart' as pathlib;

import '/class/fs_entity.dart';
import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/utils/open_file.dart';
import 'adaptive.dart';
import 'group_list_dialog.dart';

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (_subpaths.isNotEmpty)
                AdaptiveIconButton(
                    icon: const Icon(CupertinoIcons.back),
                    onPressed: () => setState(() => _subpaths.removeLast())),
              Expanded(
                child: Text(
                  _subpaths.isEmpty ? '/' : pathlib.joinAll(_subpaths),
                  style: kItemTitleTextStyle,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Expanded(
            child: FutureBuilder(
                future: Directory(pathlib
                        .joinAll([gTorrentManager.saveDir, ..._subpaths]))
                    .list()
                    .where((entity) =>
                        !_kHiddenExt.contains(pathlib.extension(entity.path)))
                    .map((entity) => GroupableFileSystemEntity(entity))
                    .toList()
                    .then((value) => value.group().sortedGroup()),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(child: Text(snapshot.error.toString()));
                  }
                  if (snapshot.connectionState != ConnectionState.done) {
                    return const Center(child: CupertinoActivityIndicator());
                  }
                  return ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemCount: snapshot.data!.length,
                    itemBuilder: (context, index) {
                      final group = snapshot.data![index];
                      return AdaptiveListTile(
                          leading: group.value.first.coverImageWidget(),
                          title: Text(group.key),
                          subtitle: group.value.length == 1 &&
                                  group.value.first.isMultiFile
                              ? Text('${group.value.first.files.length} files')
                              : group.value.length > 1
                                  ? Text('${group.value.length} items}')
                                  : null,
                          onTap: () {
                            if (group.value.length == 1) {
                              if (group.value.first.isMultiFile) {
                                _subpaths.add(group.value.first.name);
                                setState(() {});
                              } else {
                                openItem(context, group.value.first);
                              }
                            } else {
                              showAdaptivePopup(
                                  context: context,
                                  builder: (_) => ListView(
                                        children: List.unmodifiable(group.value
                                            .map((e) => ItemListTile(e))),
                                      ));
                            }
                          });
                    },
                  );
                }),
          ),
        ],
      ),
    );
  }
}
