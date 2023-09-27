import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:media_kit/media_kit.dart';

import 'services/http.dart';
import 'services/storage.dart';
import 'services/subscription.dart';
import 'services/torrent_mgr.dart';
import 'services/watch_history.dart';
import 'style.dart';
import 'view/desktop_view.dart';
import 'view/mobile_view.dart';
import 'widgets/get_macos_app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  HttpOverrides.global = TorreniumHttpOverrides();

  runApp(const TorreniumApp());
}

final kIsDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

bool _isInitialized = false;

Future<void> init() async {
  if (_isInitialized) {
    return;
  }
  await TorrentManager.init();
  await gStorage.init();
  await WatchHistory.init();
  await gSubscriptionManager.init();
  _isInitialized = true;
}

class TorreniumApp extends StatefulWidget {
  static Widget get view => kIsDesktop ? DesktopView() : const MobileView();

  const TorreniumApp({super.key});

  @override
  State<TorreniumApp> createState() => _TorreniumAppState();

  static void reload() {
    _TorreniumAppState.state.reload();
  }
}

class _TorreniumAppState extends State<TorreniumApp> {
  static late _TorreniumAppState state;
  var key = UniqueKey();

  @override
  Widget build(BuildContext context) {
    return kIsDesktop
        ? GetMacosApp(
            title: 'Torrenium',
            key: key,
            theme: MacosThemeData.dark(),
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: kProfileMode,
            home: content())
        : GetCupertinoApp(
            title: 'Torrenium',
            key: key,
            theme: kCupertinoThemeData,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: kProfileMode,
            home: content());
  }

  Widget content() {
    return FutureBuilder(
        future: init(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            Logger().e('init error', snapshot.error, snapshot.stackTrace);
          }
          if (snapshot.connectionState == ConnectionState.done) {
            return TorreniumApp.view;
          }
          return Center(
              child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CupertinoActivityIndicator(),
              const SizedBox(height: 10),
              Text(snapshot.hasError
                  ? 'Error:\n${snapshot.error}'
                  : 'Initializing...')
            ],
          ));
        });
  }

  @override
  void initState() {
    super.initState();
    state = this;
  }

  void reload() {
    setState(() {
      key = UniqueKey();
    });
  }
}
