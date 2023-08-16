import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/services/error_reporter.dart';

import 'services/storage.dart';
import 'services/subscription.dart';
import 'utils/http.dart';
import 'services/torrent.dart';
import 'view/desktop_view.dart';
import 'view/mobile_view.dart';

late Future<void> gInitResult;

Future<void> init() async {
  await Storage.init();
  await TorrentManager.init();
  SubscriptionManager.init();
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();

  gInitResult = init().onError((error, stackTrace) => reportError(
      error: error, stackTrace: stackTrace, msg: 'Error initializing'));

  runApp(const TorreniumApp());
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
