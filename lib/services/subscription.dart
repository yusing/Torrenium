import 'dart:async';
import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:get_storage/get_storage.dart';
import 'package:json_annotation/json_annotation.dart';
import 'package:logger/logger.dart';

import '/utils/connectivity.dart';
import '/utils/fetch_rss.dart' show parseRSSForItems;
import '/utils/string.dart';
import 'http.dart';
import 'rss_providers.dart' show RSSProvider, kProvidersDict;
import 'storage.dart';

part 'subscription.g.dart';

final gSubscriptionManager = SubscriptionManager();

@JsonSerializable()
class Subscription {
  final String providerName;
  final String keyword;
  final String? category;
  final String? author;
  String? _id;
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final lastUpdateNotifier =
      StorageValueListener<int>('sublastUpdate:$this');
  @JsonKey(includeFromJson: false, includeToJson: false)
  late final tasksDoneNotifier =
      ContainerListener<void>('subsTasksDone:${toString().b64}');

  Subscription(
      {required this.providerName,
      required this.keyword,
      this.category,
      this.author});

  factory Subscription.fromJson(Map<String, dynamic> json) =>
      _$SubscriptionFromJson(json);

  // factory Subscription.fromStr(String str) {
  //   final split =
  //       str.split(':').map((e) => utf8.decode(base64Decode(e))).toList();
  //   return Subscription(
  //     providerName: split[0],
  //     keyword: split[1],
  //     category: split[2].isEmpty ? null : split[2],
  //     author: split[3].isEmpty ? null : split[3],
  //   );
  // }

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

  String get id => (_id ??= sha256.convert(utf8.encode('$this')).toString());

  RSSProvider get provider => kProvidersDict[providerName]!;

  DateTime get lastUpdated =>
      DateTime.fromMillisecondsSinceEpoch(lastUpdateNotifier.value ?? 0);

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

  String searchUrl(RSSProvider provider) =>
      provider.searchUrl(query: keyword, category: category, author: author);

  Map<String, dynamic> toJson() => _$SubscriptionToJson(this);

  @override
  String toString() =>
      '${providerName.b64}:${keyword.b64}:${category?.b64 ?? ''}:${author?.b64 ?? ''}';
}

class SubscriptionManager {
  // ignore: unused_field
  late final Timer _updateTimer;
  final subscriptions = ContainerListener<Subscription>('subscriptions');
  final exclusions = ContainerListener<void>('subsExclusions');

  SubscriptionManager() {
    _updateTimer = Timer.periodic(3.seconds, (timer) => update());
  }

  Future<void> addExclusion(String id) async {
    if (exclusions.hasKey(id)) {
      return;
    }
    await exclusions.write(id, null);
  }

  Future<bool> addSubscription(Subscription sub) async {
    if (subscriptions.hasKey(sub.id)) {
      return false;
    }
    await subscriptions.write(sub.id, sub);
    return true;
  }

  Future<void> init() async {
    await GetStorage.init('subscriptions');
    await GetStorage.init('subsExclusions');
    Logger().d('SubscriptionManager initialized');
  }

  Future<bool> removeSubscription(Subscription sub) async {
    if (!subscriptions.hasKey(sub.id)) {
      return false;
    }
    await subscriptions.remove(sub.id);
    await sub.lastUpdateNotifier.clear();
    await sub.tasksDoneNotifier.clear();
    return true;
  }

  Future<void> update() async {
    for (final sub in subscriptions.value) {
      await updateSub(Subscription.fromJson(sub));
    }
  }

  Future<void> updateSub(Subscription sub, [bool force = false]) async {
    // update every hour
    if (!force && DateTime.now().difference(sub.lastUpdated) < 1.hours) {
      return;
    }
    if (await isLimitedConnectivity()) {
      // pause on cellular network or no network
      return;
    }
    final subsTasksDone = sub.tasksDoneNotifier.keys..addAll(exclusions.keys);
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
        await tasks[task]!
            .startDownload()
            .then((_) => Logger().i('New task: ${tasks[task]!.name}'))
            .onError((e, st) => Logger().e('Error adding task', e, st));
        sub.tasksDoneNotifier.write(task, null);
        await Future.delayed(1.seconds);
      }
      sub.lastUpdateNotifier.value = DateTime.now().millisecondsSinceEpoch;
    } else {
      Logger().e(resp.statusCode);
    }
  }
}
