import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:macos_ui/macos_ui.dart';

class GetMacosController extends SuperController {
  bool testMode = false;
  Key? unikey;
  MacosThemeData? theme;
  MacosThemeData? darkTheme;
  ThemeMode? themeMode;

  bool defaultPopGesture = false;
  bool defaultOpaqueRoute = true;

  Transition? defaultTransition;
  Duration defaultTransitionDuration = const Duration(milliseconds: 300);
  Curve defaultTransitionCurve = Curves.easeOutQuad;

  Curve defaultDialogTransitionCurve = Curves.easeOutQuad;

  Duration defaultDialogTransitionDuration = const Duration(milliseconds: 300);

  final routing = Routing();

  Map<String, String?> parameters = {};

  CustomTransition? customTransition;

  var _key = GlobalKey<NavigatorState>(debugLabel: 'Key Created by default');

  Map<dynamic, GlobalKey<NavigatorState>> keys = {};

  GlobalKey<NavigatorState> get key => _key;

  GlobalKey<NavigatorState>? addKey(GlobalKey<NavigatorState> newKey) {
    _key = newKey;
    return key;
  }

  @override
  void didChangeLocales(List<Locale>? locales) {
    Get.asap(() {
      final locale = Get.deviceLocale;
      if (locale != null) {
        Get.updateLocale(locale);
      }
    });
  }

  @override
  void onDetached() {}

  @override
  void onHidden() {}

  @override
  void onInactive() {}

  @override
  void onPaused() {}

  @override
  void onResumed() {}

  void restartApp() {
    unikey = UniqueKey();
    update();
  }

  void setTheme(MacosThemeData value) {
    if (darkTheme == null) {
      theme = value;
    } else {
      if (value.brightness == Brightness.light) {
        theme = value;
      } else {
        darkTheme = value;
      }
    }
    update();
  }

  void setThemeMode(ThemeMode value) {
    themeMode = value;
    update();
  }
}
