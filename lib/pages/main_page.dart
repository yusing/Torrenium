import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:macos_ui/macos_ui.dart';

import '../utils/rss_providers.dart';
import '../utils/torrent_manager.dart';
import '../utils/torrent_manager_ext.dart';
import '../widgets/download_list_dialog.dart';
import '../widgets/rss_tab.dart';
import '../widgets/subscriptions_dialog.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class ToolbarWindowButton extends StatelessWidget {
  final VoidCallback? onPressed;

  final String tooltipMessage;
  final Color color;
  const ToolbarWindowButton({
    required this.color,
    required this.tooltipMessage,
    this.onPressed,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return MacosTooltip(
        message: tooltipMessage,
        child: MacosIconButton(
          semanticLabel: tooltipMessage,
          onPressed: onPressed,
          backgroundColor: color,
          hoverColor: color.withOpacity(0.5),
          shape: BoxShape.circle,
          icon: const SizedBox.square(dimension: 12),
          boxConstraints: const BoxConstraints.tightFor(width: 12, height: 12),
          padding: EdgeInsets.zero,
        ));
  }
}

class _MainPageState extends State<MainPage> {
  late final MacosTabController _tabController;
  late final ValueNotifier<double> _progressUpdateNotifier;
  late final Timer _progressUpdateTimer;

  @override
  Widget build(BuildContext context) {
    return MacosScaffold(
      toolBar: ToolBar(
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
                    color: Colors.red,
                    onPressed: appWindow.close,
                  ),
                  const SizedBox(width: 6),
                  ToolbarWindowButton(
                    tooltipMessage: 'Minimize',
                    color: Colors.yellow,
                    onPressed: appWindow.minimize,
                  ),
                  const SizedBox(width: 6),
                  ToolbarWindowButton(
                    tooltipMessage: 'Maximize/Restore',
                    color: Colors.green,
                    onPressed: appWindow.maximizeOrRestore,
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
                    label: const Text('Downloads'),
                    // tooltipMessage: '${_progressUpdateNotifier.value.toInt()}%',
                    icon: ValueListenableBuilder(
                        valueListenable: _progressUpdateNotifier,
                        builder: (context, progress, __) {
                          return _progressUpdateNotifier.value != 100
                              ? ProgressCircle(
                                  value: _progressUpdateNotifier.value,
                                  innerColor: Colors.indigoAccent,
                                )
                              : const MacosIcon(CupertinoIcons.cloud_download);
                        }),
                    onPressed: () async {
                      if (gTorrentManager.torrentList.isEmpty) {
                        await showMacosAlertDialog(
                            context: context,
                            builder: (context) => MacosAlertDialog(
                                  appIcon: const MacosIcon(
                                      CupertinoIcons.exclamationmark_circle),
                                  title: const Text('Oops'),
                                  message: const Text('Download list is empty'),
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
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
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
                  ),
                  const SizedBox(width: 6),
                  TextButton.icon(
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
        ),
      ),
      children: [
        ContentArea(
          builder: (_, scrollController) => FutureBuilder(
              future: TorrentManager.init(),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data!) {
                  return MacosTabView(
                    controller: _tabController,
                    tabs: kRssProviders
                        .map((e) => MacosTab(
                              label: e.name,
                            ))
                        .toList(growable: false),
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
                    position: MacosTabPosition.bottom,
                    children: kRssProviders
                        .map((e) => RSSTab(
                              provider: e,
                            ))
                        .toList(growable: false),
                  );
                } else if (snapshot.hasData) {
                  // TODO: Welcome page
                  return Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Please select a save path'),
                        const SizedBox(width: 16),
                        MacosIconButton(
                          icon: const MacosIcon(FontAwesomeIcons.folderOpen),
                          onPressed: () async {
                            bool result =
                                await gTorrentManager.selectSavePath();
                            if (result) {
                              setState(() {});
                            } else {
                              setState(() {
                                showMacosAlertDialog(
                                    context: context,
                                    builder: (context) => MacosAlertDialog(
                                          appIcon: const MacosIcon(
                                              CupertinoIcons
                                                  .exclamationmark_circle),
                                          title: const Text('Oops'),
                                          message: const Text(
                                              'Failed to select a save path'),
                                          primaryButton: PushButton(
                                            controlSize: ControlSize.large,
                                            child: const Text('Dismiss'),
                                            onPressed: () =>
                                                Navigator.of(context).pop(),
                                          ),
                                        ));
                              });
                            }
                          },
                        )
                      ],
                    ),
                  );
                } else {
                  return const Center(child: CupertinoActivityIndicator());
                }
              }),
        ),
      ],
    );
  }

  @override
  void dispose() {
    _progressUpdateTimer.cancel();
    _progressUpdateNotifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _tabController =
        MacosTabController(length: kRssProviders.length, initialIndex: 0);
    _progressUpdateNotifier = ValueNotifier(0);
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!TorrentManager.isInitialized || !mounted) return;
      final inProgress = gTorrentManager.torrentList
          .map((e) => e.progress)
          .where((p) => p < 1);
      if (inProgress.isNotEmpty) {
        _progressUpdateNotifier.value =
            inProgress.reduce((a, b) => (a + b) / 2) * 100.0;
      } else {
        _progressUpdateNotifier.value = 100;
      }
    });
    super.initState();
  }
}
