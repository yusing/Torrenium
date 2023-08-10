import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:macos_ui/macos_ui.dart';

import '../services/subscription.dart';

class SubscriptionsDialog extends MacosSheet {
  SubscriptionsDialog(BuildContext context, {super.key})
      : super(child: content());

  static StatefulWidget content() =>
      StatefulBuilder(builder: (context, setState) {
        return Padding(
            padding: const EdgeInsets.all(16),
            child: gSubscriptionManager.subscriptions.isEmpty
                ? const Center(
                    child: Text("No subscription"),
                  )
                : ListView.separated(
                    itemBuilder: (context, index) {
                      final sub = gSubscriptionManager.subscriptions[index];
                      return MacosListTile(
                          title: Row(
                            children: [
                              Expanded(child: Text(sub.keyword)),
                              MacosIconButton(
                                  icon: const Icon(CupertinoIcons.refresh),
                                  onPressed: () async =>
                                      await gSubscriptionManager.updateSub(
                                          sub, true)),
                              MacosIconButton(
                                icon: const Icon(CupertinoIcons.delete),
                                onPressed: () => gSubscriptionManager
                                    .removeSubscription(sub)
                                    .then((value) {
                                  if (value) {
                                    setState(() {});
                                  }
                                }),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                  'Provider: ${sub.providerName} Category: ${sub.category ?? "Any"} Author ${sub.author ?? "Any"}'),
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
