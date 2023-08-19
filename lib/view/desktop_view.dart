import 'dart:async';

import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import '../services/torrent_ext.dart';
import '../services/torrent_mgr.dart';
import '../style.dart';
import '../widgets/adaptive.dart';
import '../widgets/group_list_dialog.dart';
import '../widgets/rss_tab.dart';
import '../widgets/subscriptions_dialog.dart';

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
  final _progressUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
    if (gTorrentManager.torrentsMap.isEmpty) {
      _progressUpdateNotifier.value = 100;
      return;
    }
    final progress = gTorrentManager.torrentsMap.values
        .map((torrents) =>
            torrents
                .map((torrent) => torrent.progress)
                .reduce((a, b) => a + b) /
            torrents.length)
        .reduce((a, b) => a + b);
    _progressUpdateNotifier.value =
        progress / gTorrentManager.torrentsMap.length * 100;
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
                        label: const Text('Downloads'),
                        // tooltipMessage: '${_progressUpdateNotifier.value.toInt()}%',
                        icon: ValueListenableBuilder(
                            valueListenable: _progressUpdateNotifier,
                            builder: (context, progress, __) {
                              return _progressUpdateNotifier.value != 100
                                  ? ProgressCircle(
                                      value: _progressUpdateNotifier.value,
                                      innerColor: MacosColors.appleBlue,
                                    )
                                  : const MacosIcon(
                                      CupertinoIcons.cloud_download);
                            }),
                        onPressed: () async {
                          if (gTorrentManager.torrentsMap.isEmpty) {
                            return await showAdaptiveAlertDialog(
                                context: context,
                                title: const Text('Oops'),
                                content: const Text('Download list is empty'),
                                confirmLabel: 'Dismiss');
                          }
                          await showAdaptivePopup(
                              barrierDismissible: true,
                              context: context,
                              builder: (_) => const DownloadListDialog());
                        },
                      )),
              CustomToolbarItem(
                  inToolbarBuilder: (context) => AdaptiveTextButton(
                        onPressed: () => showAdaptivePopup(
                            barrierDismissible: true,
                            context: context,
                            builder: (_) => const SubscriptionsDialog()),
                        icon: const MacosIcon(CupertinoIcons.star),
                        label: const Text('Subscriptions'),
                      )),
              CustomToolbarItem(inToolbarBuilder: (context) {
                return AdaptiveTextButton(
                  onPressed: () async => await gTorrentManager.selectSavePath(),
                  icon: const MacosIcon(CupertinoIcons.folder_badge_plus),
                  label: const Text('Change Path'),
                );
              })
            ]);
}
