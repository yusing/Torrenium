import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/widgets.dart';

import '/services/subscription.dart';
import '/style.dart';
import '/widgets/adaptive.dart';

class SubscriptionsDialog extends StatelessWidget {
  const SubscriptionsDialog({super.key});

  @override
  Widget build(BuildContext context) => ValueListenableBuilder(
      valueListenable: gSubscriptionManager.updateNotifier,
      builder: (context, _, __) {
        return Padding(
            padding: const EdgeInsets.all(16),
            child: gSubscriptionManager.subscriptions.isEmpty
                ? const Center(
                    child: Text('No subscription'),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final sub = gSubscriptionManager.subscriptions[index];
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
                                  builder: (_, value, __) => Text(
                                      'Last check: ${value?.toLocal().toString() ?? 'Never'}')),
                              ValueListenableBuilder(
                                  valueListenable: sub.tasksDoneNotifier,
                                  builder: (_, value, __) => Text(
                                      'Tasks added: ${value ?? "Unknown"}')),
                            ],
                          ));
                    },
                    separatorBuilder: (_, __) => const SizedBox(height: 16),
                    itemCount: gSubscriptionManager.subscriptions.length));
      });
}
