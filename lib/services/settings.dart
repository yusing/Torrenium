import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';

import '/class/setting.dart';
import 'http.dart';

class Settings {
  static final dlOverWifiOnly =
      SettingBool(title: 'Download over Wi-Fi only', defaultValue: true);
  static final enableGrouping = SettingBool(
      title: 'Enable Grouping', defaultValue: false, requireReload: true);
  static final textOnlyMode = SettingBool(
      title: 'Text Only Mode', defaultValue: true, requireReload: true);
  static final serverUrl = SettingInputString(
      title: 'WebTorrent Server URL',
      defaultValue: '',
      validator: (v) async {
        return await http.get('$v/ping').timeout(2.seconds).then((resp) async {
          Logger().i('Server ping response: ${resp.statusCode}');
          return resp.statusCode == 200 && await resp.body() == 'pong';
        });
      });
  static final Map<String, List<Setting>> all = {
    'General': [enableGrouping],
    'UI': [textOnlyMode],
    'Networking': [dlOverWifiOnly, serverUrl],
  };
}
