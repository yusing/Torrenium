import 'dart:io';

import 'package:bitsdojo_window/bitsdojo_window.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/utils/http.dart';
import 'package:torrenium/view.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // !await gTorrentManager.init(); Moved to MainPage
  runApp(const TorreniumApp());
  doWhenWindowReady(() {
    appWindow.size = appWindow.minSize = const Size(1280, 720);
    appWindow.alignment = Alignment.center;
    appWindow.title = 'Torrenium';
    appWindow.show();
  });
}

class TorreniumApp extends StatelessWidget {
  static Widget get view =>
      Platform.isMacOS || Platform.isLinux || Platform.isWindows
          ? const DesktopView()
          : const MobileView();

  const TorreniumApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MacosApp(
        title: 'Torrenium',
        theme: MacosThemeData.light(),
        darkTheme: MacosThemeData.dark(),
        debugShowCheckedModeBanner: false,
        home: view);
  }
}
