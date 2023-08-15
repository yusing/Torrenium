import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';
import 'package:macos_ui/macos_ui.dart';

import '../services/torrent.dart';
import '../services/torrent_ext.dart';
import '../widgets/download_list_dialog.dart';
import '../widgets/dynamic.dart';
import '../widgets/rss_tab.dart';
import '../widgets/subscriptions_dialog.dart';
import '../widgets/toolbar_window_button.dart';

class DesktopView extends StatelessWidget {
  const DesktopView({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: TitleBar(),
      children: [
        ContentArea(
          builder: (context, scrollController) => const Padding(
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
    final inProgress =
        gTorrentManager.torrentList.map((e) => e.progress).where((p) => p < 1);
    _progressUpdateNotifier.value = inProgress.isEmpty
        ? 100
        : inProgress.reduce((a, b) => (a + b) / 2) * 100.0;
  });

  TitleBar({super.key})
      : super(
            height: 30,
            // dividerColor: MacosColors.transparent,
            centerTitle: true,
            enableBlur: true,
            titleWidth: double.infinity,
            title: MoveWindow(
              onDoubleTap: () => appWindow.maximizeOrRestore(),
              child: Stack(
                alignment: Alignment.centerLeft,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ToolbarWindowButton(
                        tooltipMessage: 'Close',
                        color: MacosColors.appleRed,
                        onPressed: appWindow.close,
                      ),
                      const SizedBox(width: 6),
                      ToolbarWindowButton(
                        tooltipMessage: 'Minimize',
                        color: MacosColors.appleYellow,
                        onPressed: appWindow.minimize,
                      ),
                      const SizedBox(width: 6),
                      ToolbarWindowButton(
                        tooltipMessage: 'Maximize/Restore',
                        color: MacosColors.appleGreen,
                        onPressed: appWindow.maximizeOrRestore,
                      ),
                      const SizedBox(width: 6),
                      Builder(
                          builder: (context) => DynamicTextButton(
                                label: const Text('Downloads'),
                                // tooltipMessage: '${_progressUpdateNotifier.value.toInt()}%',
                                icon: ValueListenableBuilder(
                                    valueListenable: _progressUpdateNotifier,
                                    builder: (context, progress, __) {
                                      return _progressUpdateNotifier.value !=
                                              100
                                          ? ProgressCircle(
                                              value:
                                                  _progressUpdateNotifier.value,
                                              innerColor: MacosColors.appleBlue,
                                            )
                                          : const MacosIcon(
                                              CupertinoIcons.cloud_download);
                                    }),
                                onPressed: () async {
                                  if (gTorrentManager.torrentList.isEmpty) {
                                    await showMacosAlertDialog(
                                        context: context,
                                        builder: (context) => MacosAlertDialog(
                                              appIcon: const MacosIcon(
                                                  CupertinoIcons
                                                      .exclamationmark_circle),
                                              title: const Text('Oops'),
                                              message: const Text(
                                                  'Download list is empty'),
                                              primaryButton: PushButton(
                                                controlSize: ControlSize.large,
                                                child: const Text('Dismiss'),
                                                onPressed: () =>
                                                    Navigator.of(context).pop(),
                                              ),
                                            ));
                                  } else {
                                    await showMacosSheet(
                                        barrierDismissible: true,
                                        context: context,
                                        builder: (context) {
                                          return DownloadListDialog(context);
                                        });
                                  }
                                },
                              )),
                      const SizedBox(width: 6),
                      Builder(
                          builder: (context) => DynamicTextButton(
                                onPressed: () async {
                                  await showMacosSheet(
                                      barrierDismissible: true,
                                      context: context,
                                      builder: (context) {
                                        return SubscriptionsDialog(context);
                                      });
                                },
                                icon: const MacosIcon(CupertinoIcons.star),
                                label: const Text('Subscriptions'),
                              )),
                      const SizedBox(width: 6),
                      DynamicTextButton(
                        onPressed: () async =>
                            await gTorrentManager.selectSavePath(),
                        icon: const MacosIcon(CupertinoIcons.folder_badge_plus),
                        label: const Text('Change Path'),
                      )
                    ],
                  ),
                  const Center(
                    child: Text(
                      'Torrenium',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  )
                ],
              ),
            ));
}
