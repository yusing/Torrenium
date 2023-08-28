import 'package:flutter/widgets.dart';
import 'package:settings_ui/settings_ui.dart';

import '/main.dart' show TorreniumApp;
import '/services/storage.dart';

class ListenableSettingsTile<T> extends AbstractSettingsTile {
  final Setting<T> setting;
  const ListenableSettingsTile(this.setting, {super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
        listenable: setting, builder: (context, _) => setting.buildTile());
  }
}

abstract class Setting<T> extends ChangeNotifier {
  final String title;
  final T defaultValue;
  final bool requireReload;

  Setting(
      {required this.title,
      required this.defaultValue,
      this.requireReload = false});

  String get key => title.toLowerCase().replaceAll(' ', '_');
  T get value;
  set value(T newValue);

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (requireReload) {
      TorreniumApp.reload();
    }
  }

  SettingsTile buildTile();
}

class SettingBool extends Setting<bool> {
  SettingBool(
      {required super.title, required super.defaultValue, super.requireReload});

  @override
  bool get value => kStorage.getBool('settings:$key') ?? defaultValue;

  @override
  set value(bool newValue) {
    if (value == newValue) {
      return;
    }
    kStorage.setBool('settings:$key', newValue);
    notifyListeners();
  }

  @override
  SettingsTile buildTile() => SettingsTile.switchTile(
      key: ValueKey(key),
      initialValue: value,
      onToggle: (v) => value = v,
      title: Text(title));
}
