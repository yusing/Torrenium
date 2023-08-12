import 'package:flutter/cupertino.dart';
import 'package:torrenium/style.dart';
import 'package:torrenium/utils/open_file.dart';

import '../services/watch_history.dart';
import 'dynamic.dart';

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
            return ListView.separated(
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: WatchHistory.list.length,
              itemBuilder: (context, index) {
                final item = WatchHistory.list
                    .elementAt(WatchHistory.list.length - index - 1);
                return DynamicListTile(
                  title: Text(
                    item.title,
                    style: kItemTitleTextStyle,
                    maxLines: 2,
                    softWrap: true,
                  ),
                  subtitle: SizedBox(
                    width: double.infinity,
                    child: DynamicProgressBar(
                      value: item.progress,
                      trackColor: CupertinoColors.systemPurple,
                    ),
                  ),
                  onTap: () => openTorrent(context, item.torrent),
                );
              },
            );
          }),
    );
  }
}
