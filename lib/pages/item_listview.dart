import 'package:flutter/cupertino.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:macos_ui/macos_ui.dart' show MacosColors;

import '/interface/download_item.dart';
import '/interface/groupable.dart';
import '/interface/resumeable.dart';
import '/services/settings.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';
import '/widgets/play_pause_button.dart';

class DownloadsListView extends StatefulWidget {
  const DownloadsListView({super.key});

  @override
  State<DownloadsListView> createState() => _DownloadsListViewState();
}

class _DownloadsListViewState extends State<DownloadsListView> {
  var _hideDownloaded = false;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            AdaptiveSwitch(
                label: 'Hide Downloaded',
                value: _hideDownloaded,
                onChanged: (v) => setState(() {
                      gTorrentManager.hideDownload(v);
                      _hideDownloaded = v;
                    })),
            Visibility(
              visible: Settings.enableGrouping.value,
              child: AdaptiveTextButton(
                  icon: const Icon(CupertinoIcons.refresh),
                  label: const Text('Regroup'),
                  onPressed: gTorrentManager.regroup),
            ),
          ],
        ),
        Expanded(
          child: StreamBuilder(
              stream: Stream.periodic(1.seconds),
              builder: (context, snapshot) {
                if (gTorrentManager.isEmpty) {
                  return const Center(child: Text('Nothing Here...'));
                }
                return ItemListView(gTorrentManager.torrentMap);
              }),
        ),
      ],
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
              if (episodes.every((e) => e.isComplete)) {
                return Wrap(
                    children: List.of(episodes.map((e) => Padding(
                          padding: const EdgeInsets.all(4.0),
                          child: AdaptiveTextButton(
                            icon: const AdaptiveIcon(CupertinoIcons.play_arrow),
                            label: Text(
                              e.episode ?? e.nameCleaned,
                            ),
                            color: e.watchProgress > 0
                                ? CupertinoColors.systemPurple
                                : null,
                            onPressed: onTapCallback(e),
                          ),
                        ))));
              }
              return ListView.separated(
                separatorBuilder: (_, __) => const SizedBox(height: 16),
                itemCount: episodes.length,
                itemBuilder: (context, i) => ItemListTile(episodes[i]),
              );
            }));
  }
}

class ItemListTile extends Visibility {
  final DownloadItem item;

  ItemListTile(this.item)
      : super(
            key: ValueKey(item),
            visible: !item.isHidden,
            child: AdaptiveListTile(
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
              onTap: onTapCallback(item),
            ));
}

class ItemListView extends StatelessWidget {
  final List<MapEntry<String, List<DownloadItem>>> groups;

  ItemListView(Map<String, List<DownloadItem>> map, {super.key})
      : groups = map.sortedGroup();

  @override
  Widget build(BuildContext context) {
    if (groups.isEmpty) {
      return const Center(child: Text('Nothing Here...'));
    }
    if (groups.length == 1) {
      return ListView.separated(
          separatorBuilder: (_, index) => const SizedBox(height: 24),
          itemCount: groups.first.value.length,
          itemBuilder: ((_, index) => ItemListTile(groups.first.value[index])));
    }
    return ListView.separated(
      separatorBuilder: (_, index) => const SizedBox(height: 24),
      itemCount: groups.length,
      itemBuilder: ((_, index) => ItemGroupWidget(groups[index])),
    );
  }
}

VoidCallback? onTapCallback(DownloadItem item) {
  return item.isMultiFile
      ? () {
          final grouped = item.files.group();
          showAdaptivePopup(
              builder: (_) => StreamBuilder(
                  stream: Stream.periodic(1.seconds),
                  builder: (context, snapshot) {
                    return ItemListView(grouped);
                  }));
        }
      : item.isComplete
          ? item.open
          : null;
}
