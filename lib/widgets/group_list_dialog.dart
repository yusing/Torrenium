import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart' show MacosColors;

import '../class/torrent.dart';
import '../interface/download_item.dart';
import '../interface/groupable.dart';
import '../interface/resumeable.dart';
import '../main.dart' show kIsDesktop;
import '../services/torrent_mgr.dart';
import '../style.dart';
import '../utils/open_file.dart';
import '../utils/units.dart';
import 'adaptive.dart';
import 'play_pause_button.dart';

class DownloadListDialog extends StatelessWidget {
  const DownloadListDialog({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: gTorrentManager.updateNotifier,
        builder: (context, _, __) {
          return GroupListDialog(gTorrentManager.torrentsMap);
        });
  }
}

class GroupListDialog extends StatelessWidget {
  final List<MapEntry<String, List<DownloadItem>>> groups;

  GroupListDialog(Map<String, List<DownloadItem>> map, {super.key})
      : groups = map.sortedGroup();

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
      valueListenable: gTorrentManager.updateNotifier,
      builder: (context, _, __) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          child: groups.isEmpty
              ? const Center(child: Text('Nothing Here...'))
              : groups.length == 1
                  ? ListView.separated(
                      shrinkWrap: true,
                      separatorBuilder: (_, __) => const SizedBox(height: 16),
                      itemCount: groups.first.value.length,
                      itemBuilder: (context, i) =>
                          ItemListTile(groups.first.value[i]),
                    )
                  : ListView.separated(
                      separatorBuilder: (_, index) =>
                          const SizedBox(height: 24),
                      itemCount: groups.length,
                      itemBuilder: ((_, index) {
                        return ItemGroupWidget(groups[index]);
                      }),
                    ),
        );
      });
}

class ItemGroupWidget extends StatelessWidget {
  final MapEntry<String, List<DownloadItem>> group;

  const ItemGroupWidget(this.group, {super.key});

  @override
  Widget build(BuildContext context) {
    // placeholder list may be empty
    // assert(group.value.isNotEmpty);

    if (group.value.length == 1 && group.value.first.isMultiFile) {
      return ItemListTile(group.value.first);
    }

    final episodes = group.value
      ..sort((b, a) =>
          (a.episodeNumbers?.reduce((x, y) => x + y)) ??
          0.compareTo((b.episodeNumbers?.reduce((x, y) => x + y)) ?? 0));

    return AdaptiveListTile(
        leading: const AdaptiveIcon(CupertinoIcons.list_bullet,
            size: kDownloadListTileIconSize),
        title: Text('${group.key} (${group.value.length} items)',
            style: kItemTitleTextStyle),
        onTap: () => showAdaptivePopup(
            context: context,
            // title: Text(group.key, style: kItemTitleTextStyle),
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
          builder: ((context, __, ___) => _ItemListTileInner(context, item)),
        );
}

class _ItemListTileInner extends AdaptiveListTile {
  final BuildContext context;
  final DownloadItem item;

  _ItemListTileInner(this.context, this.item)
      : super(
          leading: AdaptiveIcon(item.icon,
              color: item.isMultiFile
                  ? MacosColors.appleYellow
                  : MacosColors.white,
              size: kDownloadListTileIconSize),
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
                      padding: const EdgeInsets.only(right: 8.0),
                      child: PlayPauseButton(
                        isPlaying: !(item as Resumeable).isPaused,
                        play: (item as Resumeable).resume,
                        pause: (item as Resumeable).pause,
                      ),
                    ),
                  Builder(builder: (context) {
                    return AdaptiveIconButton(
                        padding: const EdgeInsets.all(0),
                        icon: const Icon(
                          CupertinoIcons.delete,
                          color: CupertinoColors.systemRed,
                        ),
                        onPressed: () {
                          item.delete();
                          if (kIsDesktop &&
                              gTorrentManager.torrentsMap.isEmpty) {
                            Navigator.of(context).pop();
                          }
                        });
                  }),
                ],
          subtitle: item is! Torrent || item.isComplete
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
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                          "${item.bytesDownloaded.humanReadableUnit} of ${item.size.humanReadableUnit} - ${item.etaSecs.timeUnit} remaining",
                          style: kItemTitleTextStyle),
                    )
                  ],
                ),
          onTap: item.isComplete && !item.isMultiFile
              ? () => openItem(context, item)
              : item.isMultiFile
                  ? () => showAdaptivePopup(
                      context: context,
                      builder: (_) => GroupListDialog(item.files.group()))
                  : null,
        );
}
