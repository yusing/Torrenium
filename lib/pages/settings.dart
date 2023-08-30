import 'package:flutter/cupertino.dart';
import 'package:settings_ui/settings_ui.dart';

import '/class/setting.dart';
import '/services/settings.dart';
import '/style.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: SafeArea(
        child: SettingsList(
            applicationType: ApplicationType.cupertino,
            platform: DevicePlatform.iOS,
            brightness: Brightness.dark,
            darkTheme: SettingsThemeData(
                settingsListBackground: CupertinoColors.black,
                settingsSectionBackground: CupertinoColors.black,
                trailingTextColor: kCupertinoThemeData.primaryColor),
            sections: List.of(
              Settings.all.entries.map((e) => SettingsSection(
                    title: Text(e.key),
                    tiles:
                        List.of(e.value.map((s) => ListenableSettingsTile(s))),
                  )),
            )),
      ),
    );
  }
}
