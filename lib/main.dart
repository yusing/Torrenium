import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
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
  await gStorage.init();
  await TorrentManager.init();
  await gSubscriptionManager.init();
  _isInitialized = true;
}

class TorreniumApp extends StatefulWidget {
  static Widget get view =>
      kIsDesktop ? const DesktopView() : const MobileView();

  const TorreniumApp({super.key});

  @override
  State<TorreniumApp> createState() => _TorreniumAppState();

  static void reload() {
    Get.reloadAll(force: true);
  }
}

class _TorreniumAppState extends State<TorreniumApp> {
  @override
  Widget build(BuildContext context) {
    return kIsDesktop
        ? GetMacosApp(
            title: 'Torrenium',
            theme: MacosThemeData.dark(),
            debugShowCheckedModeBanner: false,
            navigatorObservers: [BotToastNavigatorObserver()],
            builder: BotToastInit(),
            home: content())
        : GetCupertinoApp(
            title: 'Torrenium',
            theme: kCupertinoThemeData,
            debugShowCheckedModeBanner: false,
            showPerformanceOverlay: kDebugMode || kProfileMode,
            navigatorObservers: [BotToastNavigatorObserver()],
            builder: BotToastInit(),
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
}
