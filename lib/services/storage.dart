import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences get kStorage => Storage.instance;

class Storage {
  static late final SharedPreferences instance;

  static String? getString(String key) => instance.getString(key);

  static bool hasKey(String key) {
    return instance.containsKey(key);
  }

  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
    Logger().d('Storage initialized');
  }

  static Future<void> removeKey(String key) async {
    await instance.remove(key);
  }

  static Future<void> setString(String key, String value) async {
    await instance.setString(key, value);
  }

  static Future<void> setStringIfNotExists(String key, String value) async {
    if (!instance.containsKey(key)) {
      await instance.setString(key, value);
    }
  }
}
