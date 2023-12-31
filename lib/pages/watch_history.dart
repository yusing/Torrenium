import 'package:flutter/cupertino.dart';

import '/services/settings.dart';
import '/services/watch_history.dart';
import '/style.dart';
import '/utils/string.dart';
import '/widgets/adaptive.dart';

class WatchHistoryPage extends StatelessWidget {
  const WatchHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ValueListenableBuilder(
          valueListenable: WatchHistory.notifier,
          builder: (context, histories, _) {
            histories.sort((a, b) => b.value.lastWatchedTimestamp
                .compareTo(a.value.lastWatchedTimestamp));
            if (histories.isEmpty) {
              return const Center(
                child: Text('No history'),
              );
            }
            return ListView.separated(
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: histories.length,
              itemBuilder: (context, index) {
                final entry = histories[index].value;
                return AdaptiveListTile(
                  key: ValueKey(entry.id),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: Stack(
                      children: [
                        if (Settings.textOnlyMode.value)
                          SizedBox(
                              width: 120,
                              height: 80,
                              child: entry.coverImageWidget())
                        else
                          entry.coverImageWidget(),
                        if (entry.duration != null)
                          Positioned(
                              bottom: 8,
                              right: 8,
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    vertical: 4.0, horizontal: 6.0),
                                decoration: BoxDecoration(
                                    color:
                                        CupertinoColors.black.withOpacity(0.8),
                                    borderRadius: BorderRadius.circular(4.0)),
                                child: Text(
                                  entry.duration!.videoDuration,
                                  style: const TextStyle(
                                      color: CupertinoColors.white,
                                      fontSize: 12),
                                ),
                              )),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          child: SizedBox(
                            width: kListTileThumbnailWidth,
                            child: AdaptiveProgressBar(
                              value: entry.progress,
                              trackColor: CupertinoColors.systemRed,
                            ),
                          ),
                        )
                      ],
                    ),
                  ),
                  title: Text(
                    entry.title,
                    style: kItemTitleTextStyle,
                    maxLines: 2,
                    softWrap: true,
                  ),
                  trailing: [
                    AdaptiveIconButton(
                        icon: const AdaptiveIcon(CupertinoIcons.delete),
                        onPressed: () => WatchHistory.remove(entry.id)),
                  ],
                  onTap: entry.open,
                );
              },
            );
          }),
    );
  }
}
