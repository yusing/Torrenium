import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:macos_ui/macos_ui.dart';

import '../services/subscription.dart';
import '../style.dart';
import 'dynamic.dart';

class SubscriptionsDialog extends MacosSheet {
  SubscriptionsDialog(BuildContext context, {super.key})
      : super(child: content());

  static StatefulWidget content() => ValueListenableBuilder(
      valueListenable: gSubscriptionManager.updateNotifier,
      builder: (context, _, __) {
        return Padding(
            padding: const EdgeInsets.all(16),
            child: gSubscriptionManager.subscriptions.isEmpty
                ? const Center(
                    child: Text("No subscription"),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final sub = gSubscriptionManager.subscriptions[index];
                      return DynamicListTile(
                          title: Text(
                            sub.keyword,
                            style: kItemTitleTextStyle,
                            softWrap: true,
                            maxLines: 2,
                          ),
                          trailing: [
                            DynamicIconButton(
                                icon: const Icon(CupertinoIcons.refresh),
                                onPressed: () async =>
                                    await gSubscriptionManager.updateSub(
                                        sub, true)),
                            const SizedBox(width: 16),
                            DynamicIconButton(
                              icon: const Icon(CupertinoIcons.delete),
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
