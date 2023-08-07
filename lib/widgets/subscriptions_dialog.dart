import 'package:flutter/widgets.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/services/subscription.dart';

/*Row(
                    children: [
                      Expanded(
                        child: MacosTextField(
                            controller: _keywordController,
                            placeholder: 'Keyword',
                            clearButtonMode: OverlayVisibilityMode.editing,
                            decoration: const BoxDecoration(
                              color: Colors.transparent,
                              border: Border(
                                bottom: BorderSide(
                                  color: Color(0xFF9E9E9E),
                                  width: 1,
                                ),
                              ),
                            )),
                      ),
                      const SizedBox(width: 16),
                      MacosPopupButton<String>(
                        value: _selectedProvider,
                        items: kProvidersDict.keys
                            .map((e) =>
                                MacosPopupMenuItem(value: e, child: Text(e)))
                            .toList(growable: false),
                        onChanged: (value) {
                          _selectedProvider = value!;
                        },
                      ),
                      const SizedBox(width: 16),
                      PushButton(
                        onPressed: () => gSubscriptionManager
                            .addSubscription(
                                _selectedProvider, _keywordController.text)
                            .then((value) {
                          if (value) {
                            _keywordController.clear();
                            setState(() {});
                          }
                        }),
                        controlSize: ControlSize.regular,
                        child: const Text('Add'),
                      ),
                    ],
                  ),*/

class SubscriptionsDialog extends MacosSheet {
  // static String _selectedProvider = kProvidersDict.keys.first;
  // static final _keywordController = TextEditingController();

  SubscriptionsDialog(BuildContext context, {super.key})
      : super(child: StatefulBuilder(builder: (context, setState) {
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
        }));
}
