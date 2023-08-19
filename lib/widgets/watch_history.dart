import 'package:flutter/cupertino.dart';
import 'package:torrenium/services/torrent_mgr.dart';

import '../services/watch_history.dart';
import '../style.dart';
import '../utils/open_file.dart';
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
            return ListView.separated(
              separatorBuilder: (_, __) => const SizedBox(height: 16),
              itemCount: WatchHistory.list.length,
              itemBuilder: (context, index) {
                final entry = WatchHistory.list
                    .elementAt(WatchHistory.list.length - index - 1);
                return AdaptiveListTile(
                  title: Text(
                    entry.title,
                    style: kItemTitleTextStyle,
                    maxLines: 2,
                    softWrap: true,
                  ),
                  subtitle: SizedBox(
                    width: double.infinity,
                    child: AdaptiveProgressBar(
                      value: entry.progress,
                      trackColor: CupertinoColors.systemPurple,
                    ),
                  ),
                  onTap: () {
                    final item = gTorrentManager.findTorrent(entry.nameHash);
                    if (item == null) {
                      showAdaptiveAlertDialog(
                          context: context,
                          title: const Text('Error'),
                          content: const Text('Item not found!'));
                      return;
                    }
                    openItem(context, item);
                  },
                );
              },
            );
          }),
    );
  }
}
