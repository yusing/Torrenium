import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart' show MacosColors;

import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/interface/resumeable.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/utils/open_file.dart';
import '/utils/string.dart';
import '../class/torrent_file.dart';
import 'adaptive.dart';
import 'play_pause_button.dart';

class DownloadListDialog extends StatelessWidget {
  const DownloadListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AdaptiveTextButton(
                icon: const Icon(CupertinoIcons.refresh),
                label: const Text('Regroup'),
                onPressed: gTorrentManager.regroup),
          ],
        ),
        Expanded(
          child: StreamBuilder(
              stream: Stream.periodic(const Duration(seconds: 3)),
              builder: (context, snapshot) {
                return GroupListDialog(gTorrentManager.torrentMap);
              }),
        ),
      ],
    );
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
        key: ValueKey(group.key),
        leading: items.first.coverImageWidget(),
        title: Text(group.key, style: kItemTitleTextStyle),
        subtitle: Text('${items.length} items'),
        onTap: () => showAdaptivePopup(
            context: context,
            builder: (_) {
              if (episodes.every((e) => e is TorrentFile)) {
                return Wrap(
                  children: List.unmodifiable(episodes.map((e) => Padding(
                        padding: const EdgeInsets.all(4.0),
                        child: AdaptiveTextButton(
                            label: Text(e.episode ?? e.nameCleaned),
                            onPressed: context.onTapCallback(e)),
                      ))),
                );
              }
              return ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: episodes.length,
                itemBuilder: (context, i) => ItemListTile(episodes[i]),
              );
            }));
  }
}

class ItemListTile extends Builder {
  ItemListTile(DownloadItem item)
      : super(
          key: ValueKey(item),
          builder: ((context) => Visibility(
              visible: !item.deleted,
              child: _ItemListTileInner(context, item))),
        );
}

class _ItemListTileInner extends AdaptiveListTile {
  final BuildContext context;
  final DownloadItem item;

  _ItemListTileInner(this.context, this.item)
      : super(
          leading: item is! TorrentFile ? item.coverImageWidget() : null,
          title: Text(
            item.episode ?? item.displayName,
            style: item.watchProgress == 0
                ? kItemTitleTextStyle
                : kItemTitleTextStyle.copyWith(
                    color: MacosColors.systemPurpleColor),
            maxLines: 3,
          ),
          trailing: item.isPlaceholder
              ? null
              : [
                  if (item is Resumeable && !item.isComplete)
                    PlayPauseButton(
                      isPlaying: !(item as Resumeable).isPaused,
                      play: (item as Resumeable).resume,
                      pause: (item as Resumeable).pause,
                    ),
                  if (!item.isPlaceholder)
                    AdaptiveIconButton(
                        padding: const EdgeInsets.all(0),
                        icon: const AdaptiveIcon(
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
                    const SizedBox(
                      height: 4,
                    ),
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
                    const SizedBox(
                      height: 4,
                    ),
                    if (item is Resumeable && (item as Resumeable).isPaused)
                      const Text('Paused')
                    else
                      Text(
                          '${item.bytesDownloaded.sizeUnit} of ${item.size.sizeUnit}\n${item.etaSecs.timeUnit} remaining')
                  ],
                ),
          onTap: context.onTapCallback(item),
        );
}

extension _DownloadItemExt on BuildContext {
  VoidCallback? onTapCallback(DownloadItem item) {
    return item.isMultiFile
        ? () => showAdaptivePopup(
            context: this, builder: (_) => GroupListDialog(item.files.group()))
        : item.isComplete
            ? () => openItem(this, item)
            : null;
  }
}
