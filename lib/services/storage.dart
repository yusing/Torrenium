import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';

final gStorage = Storage(GetStorage());

class ContainerListener<T> extends ChangeNotifier
    implements ValueListenable<List<Map<String, dynamic>>> {
  final String container;
  final GetStorage gs;

  ContainerListener(this.container) : gs = GetStorage(container);

  List<String> get keys => List<String>.from(gs.getKeys());

  @override
  List<Map<String, dynamic>> get value => List.from(gs.getValues());

  Future<void> clear() async => await gs.erase();

  bool hasKey(String key) => gs.hasData(key);

  Future<bool> init() async => await GetStorage.init(container);

  Future<void> remove(String key) async => await gs.remove(key);

  Future<void> write(String key, T value) async => await gs.write(key, value);
}

class Storage {
  final GetStorage gs;

  const Storage(this.gs);

  bool containsKey(String key) => gs.hasData(key);

  bool? getBool(String key) => gs.read(key);

  int? getInt(String key) => gs.read(key);

  String? getString(String key) => gs.read(key);

  List<String>? getStringList(String key) => gs.read(key);

  Future<bool> init() async => await GetStorage.init();

  Future<void> remove(String key) async => await gs.remove(key);

  Future<void> setBool(String key, bool value) async =>
      await gs.write(key, value);

  Future<void> setInt(String key, int value) async =>
      await gs.write(key, value);

  Future<void> setString(String key, String value) async =>
      await gs.write(key, value);

  Future<void> setStringList(String key, List<String> sl) async =>
      await gs.write(key, sl);
}

class StorageValueListener<T> extends ChangeNotifier
    implements ValueListenable<T?> {
  final String key;
  ReadWriteValue<T?> rwv;

  StorageValueListener(this.key) : rwv = ReadWriteValue(key, null);

  @override
  T? get value => rwv.val;

  set value(T? newValue) {
    if (newValue == value) {
      return;
    }
    rwv.val = newValue;
    notifyListeners();
  }

  Future<void> clear() async => await gStorage.remove(key);
}
