import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

import '/services/subscription.dart';
import '/style.dart';
import '/widgets/adaptive.dart';

class SubscriptionsDialog extends StatelessWidget {
  const SubscriptionsDialog({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
      valueListenable: gSubscriptionManager.subscriptions,
      builder: (context, subs, _) {
        return Padding(
            padding: const EdgeInsets.all(16),
            child: subs.isEmpty
                ? const Center(
                    child: Text('No subscription'),
                  )
                : ListView.separated(
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: subs.length,
                    itemBuilder: (context, index) {
                      final sub = subs[index].value;
                      return AdaptiveListTile(
                          key: ObjectKey(sub),
                          title: Text(
                            sub.keyword,
                            style: kItemTitleTextStyle,
                            softWrap: true,
                            maxLines: 2,
                          ),
                          trailing: [
                            AdaptiveIconButton(
                                icon:
                                    const AdaptiveIcon(CupertinoIcons.refresh),
                                onPressed: () async =>
                                    await gSubscriptionManager.updateSub(
                                        sub, true)),
                            AdaptiveIconButton(
                              icon: const AdaptiveIcon(CupertinoIcons.delete),
                              onPressed: () =>
                                  gSubscriptionManager.removeSubscription(sub),
                            ),
                          ],
                          subtitle: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  '${sub.providerName} - ${sub.categoryName ?? "Any"} - ${sub.authorName ?? "Any"}'),
                              ValueListenableBuilder(
                                  valueListenable: sub.lastUpdateNotifier,
                                  builder: (_, lastCheckedTs, __) => Text(
                                      'Last check: ${lastCheckedTs == null ? "Never" : DateTime.fromMillisecondsSinceEpoch(lastCheckedTs).toLocal().toString()}')),
                              ValueListenableBuilder(
                                  valueListenable: sub.tasksDoneNotifier,
                                  builder: (_, tasksDone, __) => Text(
                                      'Tasks added: ${sub.tasksDoneNotifier.keys.length}')),
                            ],
                          ));
                    },
                  ));
      });
}
