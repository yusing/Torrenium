import 'package:flutter/cupertino.dart';
import 'package:get/get.dart';
import 'package:macos_ui/macos_ui.dart' show MacosColors;

import '/class/fs_entity.dart';
import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/interface/resumeable.dart';
import '/services/settings.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';
import '/widgets/play_pause_button.dart';
import 'file_browser.dart';

class DownloadsListView extends StatelessWidget {
  const DownloadsListView({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: gTorrentManager.hideDownloaded,
      builder: (context, hideDownloaded, _) => Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Visibility(
                visible: Settings.enableGrouping.value,
                child: AdaptiveTextButton(
                  icon: const Icon(CupertinoIcons.refresh),
                  label: const Text('Regroup'),
                  onPressed: gTorrentManager.regroup,
                ),
              ),
              AdaptiveSwitch(
                  label: 'Hide Downloaded',
                  value: hideDownloaded,
                  onChanged: gTorrentManager.setDownloadedHidden),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(6.0),
              child: StreamBuilder(
                  stream: Stream.periodic(1.seconds),
                  builder: (context, snapshot) {
                    if (gTorrentManager.isEmpty) {
                      return const Center(child: Text('Nothing Here...'));
                    }
                    return ItemListView(gTorrentManager.torrentMap);
                  }),
            ),
          ),
        ],
      ),
    );
  }
}

class ItemGroupWidget extends StatelessWidget {
  final MapEntry<String, List<DownloadItem>> group;

  const ItemGroupWidget(this.group, {super.key});

  List<DownloadItem> get items => group.value;

  @override
  Widget build(BuildContext context) {
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
        onTap: () => showAdaptivePopup(builder: (_) {
              return ItemListView({group.key: episodes});
            }));
  }
}

class ItemListTile extends Visibility {
  final DownloadItem item;

  ItemListTile(this.item)
      : super(
            key: ValueKey(item),
            visible: !item.isHidden && item.exists,
            child: ListenableBuilder(
                listenable: item,
                builder: (context, _) {
                  return AdaptiveListTile(
                    leading: item.coverImageWidget(),
                    title: Text(
                      item.episode ?? item.displayName,
                      style: item.watchProgress == 0
                          ? kItemTitleTextStyle
                          : kItemTitleTextStyle.copyWith(
                              color: MacosColors.systemPurpleColor),
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
                                        minWidth:
                                            MediaQuery.of(context).size.width),
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
                              if (item is Resumeable &&
                                  (item as Resumeable).isPaused)
                                const Text('Paused')
                              else
                                Text(
                                    '${item.bytesDownloaded.sizeUnit} of ${item.size.sizeUnit}\n${item.etaSecs.timeUnit} remaining')
                            ],
                          ),
                    onTap: onTapCallback(item),
                  );
                }));
}

class ItemListView extends StatelessWidget {
  final Map<String, List<DownloadItem>> groups;

  const ItemListView(this.groups, {super.key});

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(child: Text('Nothing Here...'));
    }
    if (groups.values.length == 1) {
      return ListView.separated(
          addAutomaticKeepAlives: false,
          separatorBuilder: (_, index) => const SizedBox(height: 24),
          itemCount: groups.values.first.length,
          itemBuilder: ((_, index) =>
              ItemListTile(groups.values.first[index])));
    }
    return ListView.separated(
      addAutomaticKeepAlives: false,
      separatorBuilder: (_, index) => const SizedBox(height: 24),
      itemCount: groups.length,
      itemBuilder: ((_, index) =>
          ItemGroupWidget(groups.entries.elementAt(index))),
    );
  }
}

VoidCallback? onTapCallback(DownloadItem item) {
  if (item.isMultiFile) {
    if (item is GroupableFileSystemEntity) {
      return () =>
          showAdaptivePopup(builder: (_) => FileBrowser(path: item.fullPath));
    }
    return () {
      final grouped = item.files.group();
      showAdaptivePopup(builder: (_) => ItemListView(grouped));
    };
  }
  return item.isComplete ? item.open : null;
}
