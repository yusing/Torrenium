import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:get/utils.dart';
import 'package:macos_ui/macos_ui.dart';

import '../pages/settings.dart';
import '/pages/file_browser.dart';
import '/pages/item_listview.dart';
import '/pages/rss_tab.dart';
import '/pages/subscriptions_dialog.dart';
import '/pages/watch_history.dart';
import '/services/torrent_mgr.dart';
import '/style.dart';
import '/widgets/adaptive.dart';

class DesktopView extends StatelessWidget {
  const DesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: TitleBar(),
      children: [
        ContentArea(
          builder: (context, _) => const Padding(
            padding: EdgeInsets.fromLTRB(16, 0, 16, 32),
            child: RSSTab(),
          ),
        ),
      ],
    );
  }
}

class TitleBar extends ToolBar {
  static final _progressUpdateNotifier = ValueNotifier(100.0);
  // ignore: unused_field
  final _progressUpdateTimer = Timer.periodic(1.seconds, (_) {
    final inProgress = gTorrentManager.torrentMap.values
        .reduce((a, b) => [...a, ...b])
        .where((e) => e.progress < 1)
        .map((e) => e.progress);

    _progressUpdateNotifier.value = inProgress.isEmpty
        ? 100
        : inProgress.reduce((a, b) => (a + b) / 2) * 100.0;
  });

  TitleBar({super.key})
      : super(
            height: kDesktopTitleBarHeight,
            // dividerColor: MacosColors.transparent,
            centerTitle: true,
            enableBlur: true,
            title: const Text(
              'Torrenium',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const FileBrowser(
                                  key: ValueKey('files'),
                                )),
                        icon: const MacosIcon(CupertinoIcons.folder),
                        label: const Text('Files'),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        label: const Text('Downloads'),
                        // tooltipMessage: '${_progressUpdateNotifier.value.toInt()}%',
                        icon: ValueListenableBuilder(
                            valueListenable: _progressUpdateNotifier,
                            builder: (context, progress, __) {
                              return _progressUpdateNotifier.value != 100
                                  ? ProgressCircle(
                                      value: _progressUpdateNotifier.value,
                                      innerColor: MacosColors.systemBlueColor,
                                      radius: 8,
                                    )
                                  : const MacosIcon(
                                      CupertinoIcons.cloud_download);
                            }),
                        onPressed: () async {
                          if (gTorrentManager.torrentMap.isEmpty) {
                            return await showAdaptiveAlertDialog(
                                title: const Text('Oops'),
                                content: const Text('Download list is empty'));
                          }
                          await showAdaptivePopup(
                              barrierDismissible: true,
                              builder: (_) => const DownloadsListView(
                                  key: ValueKey('downloads')));
                        },
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const SubscriptionsDialog(
                                key: ValueKey('subscriptions'))),
                        icon: const MacosIcon(CupertinoIcons.star),
                        label: const Text('Subscriptions'),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const WatchHistoryPage(
                                key: ValueKey('watch_history'))),
                        icon: const MacosIcon(CupertinoIcons.time),
                        label: const Text('Watch History'),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const SettingsPage(
                                  key: ValueKey('settings'),
                                )),
                        icon: const MacosIcon(CupertinoIcons.settings),
                        label: const Text('Settings'),
                      )),
              // CustomToolbarItem(inToolbarBuilder: (context) {
              //   return AdaptiveTextButton(
              //     onPressed: () async => await gTorrentManager.selectSavePath(),
              //     icon: const MacosIcon(CupertinoIcons.folder_badge_plus),
              //     label: const Text('Change Path'),
              //   );
              // })
            ]);
}
