import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

SharedPreferences get kStorage => Storage.instance;

class Storage {
  static late final SharedPreferences instance;

  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
    Logger().d('Storage initialized');
  }
}
