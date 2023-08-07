import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/classes/item.dart';
import 'package:torrenium/utils/fetch_rss.dart';
import 'package:torrenium/utils/rss_providers.dart';
import 'package:torrenium/widgets/item_dialog.dart';
import 'package:torrenium/widgets/item_gridview.dart';
import 'package:torrenium/widgets/item_listview.dart';

import '../services/subscription.dart';

class RssSearchResult extends Text {
  final Item item;
  RssSearchResult({super.key, required this.item}) : super(item.name);
}

class RSSTab extends StatefulWidget {
  final RSSProvider provider;
  const RSSTab({required this.provider, super.key});

  @override
  State<RSSTab> createState() => _RSSTabState();
}

class _RSSTabState extends State<RSSTab> {
  static var _keyword = ''; // share across all tabs (RSSProvider)

  late var _selectedCategory = provider.categoryRssMap?.values.first; // ALL
  late var _selectedAuthor = provider.authorRssMap?.values.first;
  final _searchController = TextEditingController();
  RSSProvider get provider => widget.provider;

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    final url = provider.searchUrl(
        query: _keyword, author: _selectedAuthor, category: _selectedCategory);
    return FutureBuilder(
        future: getItemsFromRSS(provider, url),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            debugPrintStack(
                label: snapshot.error.toString(),
                stackTrace: snapshot.stackTrace);
            return Center(child: Text(snapshot.error.toString()));
          }
          return Column(
            children: [
              GestureDetector(
                onLongPress: () async {
                  await Clipboard.setData(ClipboardData(text: url))
                      .then((value) => showMacosAlertDialog(
                          context: context,
                          builder: (_) => MacosAlertDialog(
                                appIcon: const SizedBox.shrink(),
                                title: const Text('Copied to clipboard'),
                                message: const SizedBox.shrink(),
                                primaryButton: PushButton(
                                    controlSize: ControlSize.large,
                                    onPressed: () =>
                                        Navigator.of(context).pop(),
                                    child: const Text('Dismiss')),
                              )));
                },
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: SizedBox(
                    width: double.infinity,
                    child: Card(
                        color: Colors.black26,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4)),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                              vertical: 6.0, horizontal: 4.0),
                          child: Text(url,
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.white,
                                  fontFamily: 'monospace',
                                  letterSpacing: 1,
                                  fontWeight: FontWeight.w500)),
                        )),
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4.0),
                      child: MacosSearchField(
                          autofocus: false,
                          autocorrect: false,
                          maxLines: 1,
                          controller: _searchController,
                          placeholder: 'Search for something...',
                          maxResultsToShow: 10,
                          results: snapshot.data
                              ?.map((e) => SearchResultItem(e.name,
                                  child: RssSearchResult(item: e)))
                              .toList(growable: false),
                          onResultSelected: (e) => showMacosSheet(
                              context: context,
                              builder: (context) => ItemDialog(
                                  (e.child as RssSearchResult).item,
                                  context: context))),
                    ),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Visibility(
                    visible: _keyword.isNotEmpty
                        ? provider.supportAdvancedSearch
                            ? (provider.categoryRssMap?.isNotEmpty ?? false)
                            : false
                        : true,
                    child: MacosPopupButton<String>(
                        value: _selectedCategory,
                        items: provider.categoryRssMap?.entries
                            .map((e) => MacosPopupMenuItem<String>(
                                value: e.value,
                                enabled: !e.key.startsWith('*'),
                                child: Text(e.key)))
                            .toList(growable: false),
                        onChanged: (e) => setState(() {
                              _selectedCategory = e;
                              if (!provider.supportAdvancedSearch) {
                                _searchController.clear();
                                _selectedAuthor = null;
                              }
                            })),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  Visibility(
                    visible: _keyword.isNotEmpty
                        ? provider.supportAdvancedSearch
                            ? (provider.authorRssMap?.isNotEmpty ?? false)
                            : false
                        : true,
                    child: MacosPopupButton<String>(
                        value: _selectedAuthor,
                        items: provider.authorRssMap?.entries
                            .map((e) => MacosPopupMenuItem<String>(
                                value: e.value,
                                enabled: !e.key.startsWith('*'),
                                child: Text(e.key)))
                            .toList(growable: false),
                        onChanged: (e) => setState(() {
                              _selectedAuthor = e;
                              if (!provider.supportAdvancedSearch) {
                                _searchController.clear();
                                _selectedCategory = null;
                              }
                            })),
                  ),
                  TextButton.icon(
                    icon: const MacosIcon(CupertinoIcons.refresh),
                    label: const Text('Refresh'),
                    onPressed: () => setState(() {}),
                  ),
                  TextButton.icon(
                      icon: const MacosIcon(CupertinoIcons.star),
                      label: const Text('Subscribe'),
                      onPressed: () async {
                        if (_keyword.trim().isEmpty) {
                          return;
                        }
                        await gSubscriptionManager
                            .addSubscription(
                                providerName: provider.name,
                                keyword: _keyword,
                                category: _selectedCategory,
                                author: _selectedAuthor)
                            .then((value) async {
                          await showMacosAlertDialog(
                              context: context,
                              builder: (context) {
                                return MacosAlertDialog(
                                  title: Text(value ? 'Success' : 'Error'),
                                  message: Text(value
                                      ? 'Subscription added $_keyword from ${provider.name}'
                                      : 'Subscription already exists'),
                                  appIcon:
                                      const SizedBox(), // TODO: replace this
                                  primaryButton: PushButton(
                                      controlSize: ControlSize.large,
                                      child: const Text('Dismiss'),
                                      onPressed: () {
                                        Navigator.of(context).pop();
                                      }),
                                );
                              });
                        });
                      }),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: (snapshot.hasData
                    ? snapshot.data!.isEmpty
                        ? const Text("No result found")
                        : (provider.coverUrlGetter == null
                            ? ItemListView(items: snapshot.data!)
                            : ItemGridView(items: snapshot.data!))
                    : const Center(
                        child: CupertinoActivityIndicator(),
                      )),
              ),
            ],
          );
        });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    _searchController.addListener(() {
      if (!mounted) {
        return;
      }
      setState(() {
        _keyword = _searchController.text;
        if (!provider.supportAdvancedSearch) {
          _selectedAuthor = null;
          _selectedCategory = null;
        }
      });
    });
    super.initState();
  }
}
