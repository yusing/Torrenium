import 'dart:async';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/utils/rss_providers.dart';
import 'package:torrenium/utils/torrent_manager.dart';
import 'package:torrenium/widgets/download_list_dialog.dart';
import 'package:torrenium/widgets/rss_tab.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late final MacosTabController _tabController;
  late final ValueNotifier<double> _progressUpdateNotifier;
  late final Timer _progressUpdateTimer;

  @override
  void initState() {
    _tabController =
        MacosTabController(length: rssProviders.length, initialIndex: 0);
    _progressUpdateNotifier = ValueNotifier(0);
    _progressUpdateTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final inProgress =
          TorrentManager.torrentList.map((e) => e.progress).where((p) => p < 1);
      if (inProgress.isNotEmpty) {
        _progressUpdateNotifier.value =
            inProgress.reduce((a, b) => (a + b) / 2) * 100.0;
      } else {
        _progressUpdateNotifier.value = 100;
      }
    });
    super.initState();
  }

  @override
  void dispose() {
    _progressUpdateTimer.cancel();
    _progressUpdateNotifier.dispose();
    _tabController.dispose();
    super.dispose();
  }

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
                              : const MacosIcon(
                                  CupertinoIcons.cloud_download_fill);
                        }),
                    onPressed: () async {
                      if (TorrentManager.torrentList.isEmpty) {
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
          builder: (_, scrollController) => MacosTabView(
            controller: _tabController,
            tabs: rssProviders
                .map((e) => MacosTab(
                      label: e.name,
                    ))
                .toList(growable: false),
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 32),
            position: MacosTabPosition.bottom,
            children: rssProviders
                .map((e) => RSSTab(
                      provider: e,
                    ))
                .toList(growable: false),
          ),
        ),
      ],
    );
  }
}

class ToolbarWindowButton extends StatelessWidget {
  const ToolbarWindowButton({
    required this.color,
    required this.tooltipMessage,
    this.onPressed,
    super.key,
  });

  final VoidCallback? onPressed;
  final String tooltipMessage;
  final Color color;

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
