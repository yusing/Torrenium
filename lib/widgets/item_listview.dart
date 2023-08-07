import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import '../utils/torrent_manager.dart';
import '../utils/torrent_manager_ext.dart';
import '../widgets/item_dialog.dart';

class ItemListView extends StatelessWidget {
  final ScrollController? controller;
  final List<Item> items;
  const ItemListView({this.controller, required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      controller: controller,
      separatorBuilder: (context, index) => const SizedBox(height: 18),
      itemCount: items.length,
      itemBuilder: ((context, index) {
        final item = items[index];
        return MacosListTile(
          title: FittedBox(
            child: Row(
              children: [
                Text(item.name),
                const SizedBox(width: 16),
                MacosIconButton(
                  padding: const EdgeInsets.all(0),
                  icon:
                      const MacosIcon(CupertinoIcons.cloud_download, size: 18),
                  onPressed: () =>
                      gTorrentManager.download(item, context: context),
                ),
                const SizedBox(width: 16),
                MacosIconButton(
                  padding: const EdgeInsets.all(0),
                  icon: const MacosIcon(
                    CupertinoIcons.info,
                    size: 16,
                  ),
                  onPressed: () => showMacosSheet(
                      context: context,
                      builder: (context) => ItemDialog(
                            item,
                            context: context,
                          )),
                )
              ],
            ),
          ),
          subtitle: Text(
              "${item.category ?? 'Unknown'}: Published at ${item.pubDate} ${item.size != null ? 'Size: ${item.size}' : ''}",
              style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }
}
