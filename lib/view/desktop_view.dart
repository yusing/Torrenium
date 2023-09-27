import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:get/utils.dart';
import 'package:macos_ui/macos_ui.dart';

import '/services/torrent_mgr.dart';
import '/pages/file_browser.dart';
import '/pages/item_listview.dart';
import '/pages/rss_tab.dart';
import '/pages/settings.dart';
import '/pages/subscriptions_dialog.dart';
import '/pages/watch_history.dart';
import '/style.dart';
import '/widgets/adaptive.dart';

class DesktopView extends MacosScaffold {
  DesktopView({super.key})
      : super(
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

class TitleBar extends ToolBar {
  TitleBar({super.key})
      : super(
            height: kDesktopTitleBarHeight,
            dividerColor: MacosColors.transparent,
            centerTitle: true,
            enableBlur: true,
            title: const Text(
              'Torrenium',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            actions: [
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        icon: const MacosIcon(CupertinoIcons.folder),
                        label: const Text('Files'),
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const FileBrowser()),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        icon: StreamBuilder(
                            stream: Stream.periodic(1.seconds),
                            builder: (context, _) {
                              final progress = gTorrentManager.totalProgress;
                              return progress != 100
                                  ? ProgressCircle(
                                      value: progress,
                                      innerColor: MacosColors.systemBlueColor,
                                      radius: 8,
                                    )
                                  : const MacosIcon(
                                      CupertinoIcons.cloud_download);
                            }),
                        label: const Text('Downloads'),
                        onPressed: () async => await showAdaptivePopup(
                            builder: (_) => const DownloadsListView()),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        icon: const MacosIcon(CupertinoIcons.star),
                        label: const Text('Subscriptions'),
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const SubscriptionsDialog()),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        icon: const MacosIcon(CupertinoIcons.time),
                        label: const Text('Watch History'),
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const WatchHistoryPage(
                                key: ValueKey('watch_history'))),
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        icon: const MacosIcon(CupertinoIcons.settings),
                        label: const Text('Settings'),
                        onPressed: () => showAdaptivePopup(
                            builder: (_) => const SettingsPage()),
                      )),
            ]);
}
