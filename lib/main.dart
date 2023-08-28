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
import 'style.dart';
import 'view/desktop_view.dart';
import 'view/mobile_view.dart';

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
  await Storage.init();
  await TorrentManager.init();
  SubscriptionManager.init();
  _isInitialized = true;
}

class TorreniumApp extends StatefulWidget {
  static Widget get view =>
      kIsDesktop ? const DesktopView() : const MobileView();

  const TorreniumApp({super.key});

  @override
  State<TorreniumApp> createState() => _TorreniumAppState();

  static void reload() {
    _TorreniumAppState.state.reload();
  }
}

class _TorreniumAppState extends State<TorreniumApp> {
  var key = UniqueKey();
  static late _TorreniumAppState state;

  @override
  void initState() {
    super.initState();
    state = this;
  }

  @override
  Widget build(BuildContext context) {
    return kIsDesktop
        ? MacosApp(
            key: key,
            title: 'Torrenium',
            theme: MacosThemeData.dark(),
            debugShowCheckedModeBanner: false,
            navigatorObservers: [BotToastNavigatorObserver()],
            builder: BotToastInit(),
            home: content())
        : CupertinoApp(
            key: key,
            title: 'Torrenium',
            theme: kCupertinoThemeData,
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

  void reload() {
    setState(() {
      key = UniqueKey();
    });
  }
}
