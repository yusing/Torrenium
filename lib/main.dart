import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/services/error_reporter.dart';

import 'services/storage.dart';
import 'services/subscription.dart';
import 'utils/http.dart';
import 'services/torrent.dart';
import 'view/desktop_view.dart';
import 'view/mobile_view.dart';

// const kIsDesktop = false; // for testing

late Future<void> gInitResult;

Future<void> init() async {
  await TorrentManager.init();
  SubscriptionManager.init();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await initReporter();

  gInitResult = init().then((value) => reportError(msg: 'OK')).onError(
      (error, stackTrace) => reportError(
          error: error, stackTrace: stackTrace, msg: 'Error initializing'));

  HttpOverrides.global = MyHttpOverrides();

  runApp(const TorreniumApp());
  if (kIsDesktop) {
    doWhenWindowReady(() {
      appWindow.size = appWindow.minSize =
          kIsDesktop ? const Size(1280, 720) : const Size(720, 1080);
      appWindow.alignment = Alignment.center;
      appWindow.title = 'Torrenium';
      appWindow.show();
    });
  }
}

final kIsDesktop = Platform.isWindows || Platform.isLinux || Platform.isMacOS;

class TorreniumApp extends StatelessWidget {
  static Widget get view =>
      kIsDesktop ? const DesktopView() : const MobileView();

  const TorreniumApp({super.key});

  Widget content() {
    return FutureBuilder(
        future: gInitResult,
        builder: (context, snapshot) {
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

  @override
  Widget build(BuildContext context) {
    return kIsDesktop
        ? MacosApp(
            title: 'Torrenium',
            theme: MacosThemeData.light(),
            darkTheme: MacosThemeData.dark(),
            debugShowCheckedModeBanner: false,
            home: content())
        : CupertinoApp(
            title: 'Torrenium',
            theme: const CupertinoThemeData(
                brightness: Brightness.dark,
                primaryColor: CupertinoColors.activeOrange),
            debugShowCheckedModeBanner: false,
            home: content());
  }
}
