import 'dart:async';

import 'package:flutter/widgets.dart';
import 'package:settings_ui/settings_ui.dart';

import '/main.dart' show TorreniumApp;
import '/services/storage.dart';
import '/utils/show_snackbar.dart';
import '/widgets/adaptive.dart';

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
  final FutureOr<bool> Function(T)? validator;

  Setting(
      {required this.title,
      required this.defaultValue,
      this.requireReload = false,
      this.validator});

  String get key => title.toLowerCase().replaceAll(' ', '_');
  T get value;
  set value(T newValue);

  SettingsTile buildTile();

  @override
  void notifyListeners() {
    super.notifyListeners();
    if (requireReload) {
      TorreniumApp.reload();
    }
  }

  FutureOr<bool> validate() async {
    if (validator == null) {
      return true;
    }
    return await validator!(value);
  }
}

class SettingBool extends Setting<bool> {
  SettingBool(
      {required super.title,
      required super.defaultValue,
      super.requireReload,
      super.validator});

  @override
  bool get value => gStorage.getBool('settings:$key') ?? defaultValue;

  @override
  set value(bool newValue) {
    if (value == newValue) {
      return;
    }
    gStorage.setBool('settings:$key', newValue);
    notifyListeners();
  }

  @override
  SettingsTile buildTile() => SettingsTile.switchTile(
      key: ValueKey(key),
      initialValue: value,
      onToggle: (v) => value = v,
      title: Text(title));
}

class SettingInputString extends Setting<String> {
  late final controller = TextEditingController(text: value);

  SettingInputString(
      {required super.title,
      required super.defaultValue,
      super.requireReload,
      super.validator});

  @override
  String get value => gStorage.getString('settings:$key') ?? defaultValue;

  @override
  set value(String newValue) {
    if (value == newValue) {
      return;
    }
    gStorage.setString('settings:$key', newValue);
    notifyListeners();
  }

  @override
  SettingsTile buildTile() => SettingsTile(
        key: ValueKey(key),
        title: Text(title),
        description: AdaptiveTextField(
          controller: controller,
          onSubmitted: (v) async {
            value = v;

            if (!await validate()) {
              showSnackBar('Error', 'Invalid value for $title');
            }
          },
        ),
      );
}
