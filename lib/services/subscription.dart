import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart' show ValueNotifier;
import 'package:flutter_animate/flutter_animate.dart';
import 'package:logger/logger.dart';

import '/utils/connectivity.dart';
import '/utils/fetch_rss.dart' show parseRSSForItems;
import 'http.dart';
import 'rss_providers.dart' show RSSProvider, kProvidersDict;
import 'storage.dart';

SubscriptionManager get gSubscriptionManager => SubscriptionManager.instance;

class Subscription {
  final String providerName;
  final String keyword;
  final String? category;
  final String? author;
  late ValueNotifier<DateTime?> lastUpdateNotifier;
  late ValueNotifier<int?> tasksDoneNotifier;

  Subscription(
      {required this.providerName,
      required this.keyword,
      this.category,
      this.author});

  factory Subscription.fromStr(String str) {
    final split = str.split(':');
    final sub = Subscription(
      providerName: split[0],
      keyword: utf8.decode(base64Decode(split[1])),
      category: split[2] == 'null' ? null : split[2],
      author: split[3] == 'null' ? null : split[3],
    );
    sub.initNotifiers(
      lastUpdate: kStorage.containsKey('sublastUpdate_$sub')
          ? DateTime.fromMillisecondsSinceEpoch(
              Storage.instance.getInt('sublastUpdate_$sub')!)
          : null,
      tasksDone: Storage.instance.getStringList('subsTasksDone_$sub')?.length,
    );
    return sub;
  }

  String? get authorName =>
      provider.authorRssMap?.entries.firstWhere((e) => e.value == author).key;

  String? get categoryName => provider.categoryRssMap?.entries
      .firstWhere((e) => e.value == category)
      .key;

  @override
  int get hashCode =>
      providerName.hashCode ^
      keyword.hashCode ^
      category.hashCode ^
      author.hashCode;

  RSSProvider get provider => kProvidersDict[providerName]!;

  @override
  bool operator ==(Object other) {
    if (other is Subscription) {
      return providerName == other.providerName &&
          keyword == other.keyword &&
          category == other.category &&
          author == other.author;
    }
    return false;
  }

  void initNotifiers({DateTime? lastUpdate, int? tasksDone}) {
    lastUpdateNotifier = ValueNotifier<DateTime?>(lastUpdate);
    tasksDoneNotifier = ValueNotifier<int?>(tasksDone);
  }

  @override
  String toString() =>
      '$providerName:${base64Encode(utf8.encode(keyword))}:${category ?? 'null'}:${author ?? 'null'}';
}

class SubscriptionManager {
  static late final SubscriptionManager instance;
  // ignore: unused_field
  final Timer _updateTimer;
  final List<Subscription> subscriptions;
  final updateNotifier = ValueNotifier(null);

  SubscriptionManager()
      : subscriptions = kStorage
                .getStringList('subscriptions')
                ?.map<Subscription>((e) => Subscription.fromStr(e))
                .toList() ??
            [],
        _updateTimer = Timer.periodic(3.seconds, (timer) => update()) {
    Logger().d('SubscriptionManager initialized');
  }
  List<Subscription> get _subs => subscriptions;

  Future<void> addExclusion(String id) {
    final exclusions = getExclusions();
    if (exclusions.contains(id)) {
      return Future.value();
    }
    exclusions.add(id);
    return Storage.instance.setStringList('subsExclusions', exclusions);
  }

  Future<bool> addSubscription(
      {required String providerName,
      required String keyword,
      required String? author,
      required String? category}) async {
    final sub = Subscription(
        providerName: providerName,
        keyword: keyword,
        author: author,
        category: category);
    sub.initNotifiers(lastUpdate: null, tasksDone: null);
    if (_subs.contains(sub)) {
      return false;
    }
    _subs.add(sub);
    await _saveSubscriptions();
    updateNotifier.notifyListeners();
    return true;
  }

  List<String> getExclusions() {
    return Storage.instance.getStringList('subsExclusions') ?? [];
  }

  Future<bool> removeSubscription(Subscription sub) async {
    if (!_subs.contains(sub)) {
      return false;
    }
    _subs.remove(sub);
    await kStorage.remove('sublastUpdate_$sub');
    await kStorage.remove('subsTasksDone_$sub');
    await _saveSubscriptions();
    updateNotifier.notifyListeners();
    return true;
  }

  Future<void> updateSub(Subscription sub, [bool force = false]) async {
    // update every hour
    if (!force &&
        DateTime.now().difference(sub.lastUpdateNotifier.value ?? DateTime(0)) <
            1.hours) {
      return;
    }
    if (await isLimitedConnectivity()) {
      // pause on cellular network or no network
      return;
    }
    final subsTasksDone = force
        ? <String>[]
        : Storage.instance.getStringList('subsTasksDone_$sub') ?? [];
    subsTasksDone.addAll(getExclusions());

    final provider = sub.provider;
    final url = provider.searchUrl(
        query: sub.keyword, author: sub.author, category: sub.category);
    final resp = await http.get(url);
    if (resp.statusCode == 200) {
      final items = parseRSSForItems(provider, await resp.body());
      final tasks = Map.fromEntries(items.map((e) => MapEntry(e.id, e)));
      // start new tasks
      final newTasks =
          tasks.keys.where((task) => !subsTasksDone.contains(task));
      for (final task in newTasks) {
        final item = tasks[task]!;
        try {
          await item.startDownload();
          Logger().i('New task: ${item.name}');
        } catch (e) {
          Logger().e(e);
        }
      }
      await Storage.instance
          .setInt('sublastUpdate_$sub', DateTime.now().millisecondsSinceEpoch);
      await Storage.instance
          .setStringList('subsTasksDone_$sub', tasks.keys.toList());
      sub.lastUpdateNotifier.value = DateTime.now();
      sub.tasksDoneNotifier.value = tasks.length;
    } else {
      Logger().e(resp.statusCode);
    }
  }

  Future<void> _saveSubscriptions() async {
    await Storage.instance.setStringList('subscriptions',
        _subs.map((e) => e.toString()).toList(growable: false));
  }

  static void init() {
    instance = SubscriptionManager();
  }

  static Future<void> update() async {
    for (final sub in instance._subs) {
      await instance.updateSub(sub);
    }
  }
}
