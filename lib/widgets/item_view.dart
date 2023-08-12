import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import '../services/torrent.dart';
import '../services/torrent_ext.dart';
import '../style.dart';
import 'dynamic.dart';
import 'item_card.dart';

class ItemGridView extends StatelessWidget {
  final ScrollController? controller;
  final List<Item> items;
  const ItemGridView({this.controller, required this.items, super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
          shrinkWrap: true,
          controller: controller,
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: kCoverPhotoWidth,
              crossAxisSpacing: 8.0,
              mainAxisSpacing: 16.0,
              childAspectRatio: 0.7),
          itemCount: items.length,
          itemBuilder: ((_, index) => ItemCard(item: items[index]))),
    );
  }
}

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
        return DynamicListTile(
          title: Text(item.name),
          trailing: [
            DynamicIconButton(
              padding: const EdgeInsets.all(0),
              icon: const MacosIcon(CupertinoIcons.cloud_download, size: 18),
              onPressed: () => gTorrentManager.download(item, context: context),
            ),
            const SizedBox(width: 16),
            DynamicIconButton(
              padding: const EdgeInsets.all(0),
              icon: const MacosIcon(
                CupertinoIcons.info,
                size: 16,
              ),
              onPressed: () => item.showDialog(context),
            )
          ],
          subtitle: Text(
              "${item.category ?? 'Unknown'}: Published at ${item.pubDate} ${item.size != null ? 'Size: ${item.size}' : ''}",
              style: const TextStyle(fontSize: 12)),
        );
      }),
    );
  }
}
