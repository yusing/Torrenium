import '/class/setting.dart';

class Settings {
  static final dlOverWifiOnly =
      SettingBool(title: 'Download over Wi-Fi only', defaultValue: true);
  static final enableGrouping = SettingBool(
      title: 'Enable Grouping', defaultValue: false, requireReload: true);
  static final textOnlyMode = SettingBool(
      title: 'Text Only Mode', defaultValue: true, requireReload: true);
  static final Map<String, List<Setting>> all = {
    'General': [enableGrouping],
    'UI': [textOnlyMode],
    'Networking': [dlOverWifiOnly],
  };
}
