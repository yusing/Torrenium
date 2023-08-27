import 'dart:io';

import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:media_kit/media_kit.dart';

import 'services/http.dart';
import 'services/storage.dart';
import 'services/subscription.dart';
import 'services/torrent_mgr.dart';
import 'view/desktop_view.dart';
import 'view/mobile_view.dart';

bool _isInitialized = false;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();

  HttpOverrides.global = TorreniumHttpOverrides();

  runApp(const TorreniumApp());
}

final kIsDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

Future<void> init() async {
  if (_isInitialized) {
    return;
  }
  await Storage.init();
  await TorrentManager.init();
  SubscriptionManager.init();
  _isInitialized = true;
}

class TorreniumApp extends StatelessWidget {
  static Widget get view =>
      kIsDesktop ? const DesktopView() : const MobileView();

  const TorreniumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return kIsDesktop
        ? MacosApp(
            title: 'Torrenium',
            theme: MacosThemeData.dark(),
            debugShowCheckedModeBanner: false,
            navigatorObservers: [BotToastNavigatorObserver()],
            builder: BotToastInit(),
            home: content())
        : CupertinoApp(
            title: 'Torrenium',
            theme: const CupertinoThemeData(
                brightness: Brightness.dark,
                primaryColor: CupertinoColors.activeOrange),
            debugShowCheckedModeBanner: false,
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
            return view;
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
