import 'dart:math';

import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../utils/string.dart';

SharedPreferences get kStorage => Storage.instance;

class Storage {
  static late final SharedPreferences instance;

  static String getCache(String key) => instance.getString(key.cacheKey)!;

  static String? getString(String key) => instance.getString(key);

  static bool hasCache(String key) {
    return instance.containsKey(key.cacheKey) &&
        instance.containsKey(key.cacheExpireKey) &&
        DateTime.parse(instance.getString(key.cacheExpireKey)!)
            .isAfter(DateTime.now());
  }

  static bool hasKey(String key) {
    return instance.containsKey(key);
  }

  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
    Logger().d('Storage initialized');
  }

  static Future<void> removeCache(String key) async {
    await instance.remove(key.cacheKey);
    await instance.remove(key.cacheExpireKey);
  }

  static Future<void> removeKey(String key) async {
    await instance.remove(key);
  }

  static Future<void> setCache(String key, String value,
      [Duration? expireAfter]) async {
    await instance.setString(key.cacheKey, value);
    if (expireAfter != null) {
      await instance.setString(key.cacheExpireKey,
          DateTime.now().add(expireAfter).toIso8601String());
    }
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

extension on String {
  String get cacheExpireKey => 'cacheExpire:$sha256Hash';
  String get cacheKey => 'cache:$sha256Hash';
}
