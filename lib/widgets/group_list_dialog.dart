import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart' show MacosColors;

import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/interface/resumeable.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/utils/open_file.dart';
import '/utils/string.dart';
import 'adaptive.dart';
import 'play_pause_button.dart';

class DownloadListDialog extends StatelessWidget {
  const DownloadListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: gTorrentManager.updateNotifier,
        builder: (context, _, __) {
          return GroupListDialog(gTorrentManager.torrentList
              .where((t) => !t.isComplete)
              .toList()
              .group());
        });
  }
}

class GroupListDialog extends StatelessWidget {
  final List<MapEntry<String, List<DownloadItem>>> groups;

  GroupListDialog(Map<String, List<DownloadItem>> map, {super.key})
      : groups = map.sortedGroup();

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(child: Text('Nothing Here...'));
    }
    return ListView.separated(
      separatorBuilder: (_, index) => const SizedBox(height: 24),
      itemCount: groups.length,
      itemBuilder: ((_, index) {
        return ItemGroupWidget(groups[index]);
      }),
    );
  }
}

class ItemGroupWidget extends StatelessWidget {
  final MapEntry<String, List<DownloadItem>> group;

  const ItemGroupWidget(this.group, {super.key});

  List<DownloadItem> get items => group.value;

  @override
  Widget build(BuildContext context) {
    // placeholder list may be empty
    if (items.isEmpty) {
      return const SizedBox.shrink();
    }

    if (items.length == 1) {
      return ItemListTile(items.first);
    }

    final episodes = items
      ..sort((a, b) => a.episode?.compareTo(b.episode ?? '') ?? 0);

    return AdaptiveListTile(
        leading: items.first.coverImageWidget(),
        title: Text(group.key, style: kItemTitleTextStyle),
        subtitle: Text('${items.length} items'),
        onTap: () => showAdaptivePopup(
            context: context,
            builder: (_) => ListView.separated(
                  shrinkWrap: true,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemCount: episodes.length,
                  itemBuilder: (context, i) => ItemListTile(episodes[i]),
                )));
  }
}

class ItemListTile extends ValueListenableBuilder<void> {
  ItemListTile(DownloadItem item, {super.key})
      : super(
          valueListenable: item.updateNotifier,
          builder: ((context, __, ___) => Visibility(
              visible: !item.deleted,
              child: _ItemListTileInner(context, item))),
        );
}

class _ItemListTileInner extends AdaptiveListTile {
  final BuildContext context;
  final DownloadItem item;

  _ItemListTileInner(this.context, this.item)
      : super(
          leading: item.coverImageWidget(),
          title: Text(
            item.episode ?? item.displayName,
            style: item.watchProgress == 0
                ? kItemTitleTextStyle
                : kItemTitleTextStyle.copyWith(
                    color: MacosColors.systemPurpleColor),
            softWrap: true,
            maxLines: 2,
          ),
          trailing: item.isPlaceholder
              ? null
              : [
                  if (item is Resumeable && !item.isComplete)
                    Padding(
                      padding: const EdgeInsets.only(right: 4.0),
                      child: PlayPauseButton(
                        isPlaying: !(item as Resumeable).isPaused,
                        play: (item as Resumeable).resume,
                        pause: (item as Resumeable).pause,
                      ),
                    ),
                  if (!item.isPlaceholder)
                    AdaptiveIconButton(
                        padding: const EdgeInsets.all(0),
                        icon: const Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.systemRed,
                        ),
                        onPressed: item.delete),
                ],
          subtitle: item.isComplete
              ? null
              : Column(
                  mainAxisSize: MainAxisSize.max,
                  mainAxisAlignment: MainAxisAlignment.start,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Builder(builder: (context) {
                      return ConstrainedBox(
                          constraints: BoxConstraints(
                              minWidth: MediaQuery.of(context).size.width),
                          child: AdaptiveProgressBar(
                            value: item.progress.toDouble(),
                            trackColor: item.isComplete
                                ? MacosColors.applePurple
                                : null,
                          ));
                    }),
                    Text(
                        '${item.bytesDownloaded.sizeUnit} of ${item.size.sizeUnit}\n${item.etaSecs.timeUnit} remaining')
                  ],
                ),
          onTap: item.isMultiFile
              ? () => showAdaptivePopup(
                  context: context,
                  builder: (_) => GroupListDialog(item.files.group()))
              : item.isComplete
                  ? () => openItem(context, item)
                  : null,
        );
}
