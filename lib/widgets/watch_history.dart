import 'package:flutter/cupertino.dart';

import '/services/watch_history.dart';
import '/style.dart';
import '/utils/open_file.dart';
import '/utils/string.dart';
import 'adaptive.dart';

class WatchHistoryPage extends StatefulWidget {
  const WatchHistoryPage({super.key});

  @override
  State<WatchHistoryPage> createState() => _WatchHistoryPageState();
}

class _WatchHistoryPageState extends State<WatchHistoryPage> {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: ValueListenableBuilder(
          valueListenable: WatchHistory.notifier,
          builder: (context, v, _) {
            if (WatchHistory.histories.map.isEmpty) {
              return const Center(
                child: Text('No history'),
              );
            }
            return ListView.separated(
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: WatchHistory.histories.length,
              itemBuilder: (context, index) {
                final entry = WatchHistory.histories
                    .elementAt(WatchHistory.histories.length - index - 1);
                return AdaptiveListTile(
                  key: ValueKey(entry.nameHash),
                  leading: ClipRRect(
                    borderRadius: BorderRadius.circular(6.0),
                    child: Stack(
                      children: [
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
                  onTap: () => openItem(context, entry),
                );
              },
            );
          }),
    );
  }
}
