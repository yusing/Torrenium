import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import 'services/storage.dart';
import 'services/subscription.dart';
import 'utils/http.dart';
import 'services/torrent.dart';
import 'view/desktop_view.dart';
import 'view/mobile_view.dart';

// const kIsDesktop = false; // for testing

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Storage.init();
  await TorrentManager.init();
  SubscriptionManager.init();

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

  @override
  Widget build(BuildContext context) {
    // return kIsDesktop
    //     ? MacosApp(
    //         title: 'Torrenium',
    //         theme: MacosThemeData.light(),
    //         darkTheme: MacosThemeData.dark(),
    //         debugShowCheckedModeBanner: false,
    //         home: view)
    //     : CupertinoApp(
    //         title: 'Torrenium', debugShowCheckedModeBanner: false, home: view);

    return MacosApp(
        title: 'Torrenium',
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: view);
  }
}
