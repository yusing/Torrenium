import 'package:flutter/foundation.dart';
import 'package:get_storage/get_storage.dart';
import 'package:logger/logger.dart';

import '/utils/string.dart';
import 'torrent_mgr.dart';

Storage? _storage;
Storage get gStorage =>
    _storage ??= Storage(GetStorage('global_gs', gTorrentManager.dataDir));

typedef ContainerEntry<T> = MapEntry<String, T>;
typedef JsonValueDecoder<T> = T Function(dynamic);
typedef JsonValueEncoder<T> = dynamic Function(T);
typedef JsonValueMap<T> = Map<String, T>;

class ContainerListener<T> extends ChangeNotifier
    implements ValueListenable<List<ContainerEntry<T>>> {
  final String container;
  late final GetStorage _gs;
  final JsonValueDecoder<T> decoder;
  final JsonValueEncoder<T> encoder;

  ContainerListener(String containerName,
      {required this.decoder, required this.encoder})
      : container = containerName.sha256 {
    _gs = GetStorage(container, gTorrentManager.dataDir);
    Logger().d('ContainerListener: $containerName initialized');
  }

  List<String> get keys => List<String>.from(_gs.getKeys());

  @override
  List<ContainerEntry<T>> get value {
    final keys = this.keys, values = this.values;
    return List.generate(keys.length, (i) => MapEntry(keys[i], values[i]));
  }

  List<T> get values => List<T>.from(_gs.getValues().map((e) => decoder(e)));

  Future<void> clear() async {
    await _gs.erase();
    notifyListeners();
  }

  bool hasKey(String key) => _gs.hasData(key);

  Future<void> init() async {
    await _gs.initStorage;
    notifyListeners();
  }

  Future<void> remove(String key) async {
    await _gs.remove(key);
    notifyListeners();
  }

  Future<void> write(String key, T value) async {
    await _gs.write(key, encoder(value));
    notifyListeners();
  }
}

class Storage {
  final GetStorage gs;

  const Storage(this.gs);

  bool containsKey(String key) => gs.hasData(key);

  bool? getBool(String key) => gs.read(key);

  int? getInt(String key) => gs.read(key);

  String? getString(String key) => gs.read(key);

  List<String>? getStringList(String key) => gs.read(key);

  Future<bool> init() async => await gs.initStorage;

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

  StorageValueListener(this.key)
      : rwv = ReadWriteValue(key, null, () => gStorage.gs);

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

class StringListListener extends ContainerListener<void> {
  StringListListener(String container)
      : super(container, encoder: (e) {}, decoder: (e) {});

  Future<void> add(String key) async => await write(key, null);
}
