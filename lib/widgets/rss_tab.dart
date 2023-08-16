import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import '../main.dart' show kIsDesktop;
import '../services/subscription.dart';
import '../style.dart';
import '../utils/fetch_rss.dart';
import '../utils/rss_providers.dart';
import 'cupertino_picker_button.dart';
import 'item_view.dart';

typedef KV = MapEntry<String, String?>;

class RssSearchResult extends Text {
  final Item item;
  RssSearchResult({super.key, required this.item}) : super(item.name);
}

class RSSTab extends StatefulWidget {
  const RSSTab({super.key});

  @override
  State<RSSTab> createState() => _RSSTabState();
}

class _RSSTabState extends State<RSSTab> {
  static final _searchController =
      TextEditingController(); // share across all tabs (RSSProvider)

  late final _tabControllerDesktop = kIsDesktop
      ? (MacosTabController(length: kRssProviders.length, initialIndex: 0)
        ..addListener(() {
          updateUrl();
        }))
      : null;

  int categoryIndex = 0;
  int authorIndex = 0;
  var provider = kRssProviders.first;

  late final ValueNotifier<String> urlListenable = ValueNotifier(
      provider.searchUrl(
          query: query, author: selectedAuthor, category: selectedCategory));

  List<Widget> get buttons => [
        CupertinoButton(
            child: const Text('Subscribe'),
            onPressed: () async {
              if (query.trim().isEmpty) {
                return;
              }
              await gSubscriptionManager
                  .addSubscription(
                      providerName: provider.name,
                      keyword: query,
                      category: selectedCategory,
                      author: selectedAuthor)
                  .then((value) async {
                if (kIsDesktop) {
                  await showMacosAlertDialog(
                      context: context,
                      builder: (context) {
                        return MacosAlertDialog(
                          title: Text(value ? 'Success' : 'Error'),
                          message: Text(value
                              ? 'Subscription added $query from ${provider.name}'
                              : 'Subscription already exists'),
                          appIcon: const SizedBox(), // TODO: replace this
                          primaryButton: PushButton(
                              controlSize: ControlSize.large,
                              child: const Text('Dismiss'),
                              onPressed: () {
                                Navigator.of(context).pop();
                              }),
                        );
                      });
                } else {
                  await showCupertinoDialog(
                      context: context,
                      builder: (context) {
                        return CupertinoAlertDialog(
                          title: Text(value ? 'Success' : 'Error'),
                          content: Text(value
                              ? 'Subscription added $query from ${provider.name}'
                              : 'Subscription already exists'),
                          actions: [
                            CupertinoDialogAction(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: const Text('Dismiss'))
                          ],
                        );
                      });
                }
              });
            })
      ];

  String get query => _searchController.text;

  String? get selectedAuthor =>
      provider.authorRssMap?.values.elementAt(authorIndex);

  String? get selectedCategory =>
      provider.categoryRssMap?.values.elementAt(categoryIndex);

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    return ValueListenableBuilder(
        valueListenable: urlListenable,
        builder: (context, url, _) {
          if (kIsDesktop) {
            return Column(children: [
              Expanded(
                child: content(url),
              ),
              MacosSegmentedControl(
                  tabs: List.generate(
                      kRssProviders.length,
                      (i) => MacosTab(
                            label: kRssProviders[i].name,
                          )),
                  controller: _tabControllerDesktop!)
            ]);
          }
          return OfflineBuilder(
              connectivityBuilder: (context, connectivity, child) {
                if (connectivity == ConnectivityResult.none) {
                  return Column(
                    children: [
                      const ColoredBox(
                        color: CupertinoColors.systemRed,
                        child: Center(
                          child: Text('No Internet'),
                        ),
                      ),
                      Expanded(child: child)
                    ],
                  );
                }
                return child;
              },
              child: content(url));
        });
  }

  Widget content(String url) => FutureBuilder(
        future: getItemsFromRSS(provider, url),
        builder: (_, snapshot) {
          return Column(
            children: [
              if (kIsDesktop) urlBar(url),
              if (!kIsDesktop) ...[
                Row(
                  children: [
                    Expanded(child: searchBar(snapshot.data)),
                    ...buttons
                  ],
                ),
                const SizedBox(
                  height: 4,
                ),
                urlBar(url),
                const SizedBox(
                  height: 4,
                ),
                Row(
                  children: [
                    Expanded(
                      child: CupertinoPickerButton(
                          valueGetter: () => provider,
                          items: kRssProviders,
                          itemBuilder: (e) =>
                              Text(e.name, style: kItemTitleTextStyle),
                          onSelectedItemChanged: (value) =>
                              provider = kRssProviders[value],
                          onPop: (value) {
                            provider = value;
                            updateUrl();
                          }),
                    ),
                    Expanded(child: pickerCategory()),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(child: pickerAuthor())
                  ],
                )
              ] else
                Row(
                  children: [
                    Expanded(
                      child: searchBar(snapshot.data),
                    ),
                    const SizedBox(
                      width: 4,
                    ),
                    pickerCategory(),
                    const SizedBox(
                      width: 4,
                    ),
                    pickerAuthor(),
                    ...buttons
                  ],
                ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: snapshot.hasError
                    ? Center(child: Text(snapshot.error.toString()))
                    : (snapshot.hasData
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
        },
      );

  Widget pickerAuthor() {
    final enabled = query.isNotEmpty
        ? provider.supportAdvancedSearch
            ? (provider.authorRssMap?.isNotEmpty ?? false)
            : false
        : provider.authorRssMap != null;
    return enabled ? pickerAuthorInner() : const SizedBox.shrink();
  }

  Widget pickerAuthorInner() {
    onChange(int? e) {
      if (e == null) return;
      authorIndex = e;
      if (!provider.supportAdvancedSearch) {
        _searchController.clear();
      }
      updateUrl();
    }

    if (!kIsDesktop) {
      return CupertinoPickerButton(
          items: List.generate(provider.authorRssMap?.length ?? 0, (i) => i,
              growable: false),
          itemBuilder: (i) => Text(provider.authorRssMap!.keys.elementAt(i)),
          valueGetter: () => authorIndex,
          onSelectedItemChanged: (i) => authorIndex = i,
          onPop: (i) => onChange(i));
    }

    return MacosPopupButton(
        value: authorIndex,
        items: List.generate(provider.authorRssMap!.length, (index) {
          final key = provider.authorRssMap!.keys.elementAt(index);
          return MacosPopupMenuItem(
              value: index, enabled: !key.startsWith('*'), child: Text(key));
        }),
        onChanged: onChange);
  }

  Widget pickerCategory() {
    final enabled = query.isNotEmpty
        ? provider.supportAdvancedSearch
            ? (provider.categoryRssMap?.isNotEmpty ?? false)
            : false
        : provider.categoryRssMap != null;
    return enabled ? pickerCategoryInner() : const SizedBox.shrink();
  }

  Widget pickerCategoryInner() {
    onChange(int? e) {
      if (e == null) return;
      categoryIndex = e;
      if (!provider.supportAdvancedSearch) {
        _searchController.clear();
      }
      updateUrl();
    }

    if (!kIsDesktop) {
      return CupertinoPickerButton(
          items: List.generate(provider.categoryRssMap?.length ?? 0, (i) => i,
              growable: false),
          itemBuilder: (i) => Text(provider.categoryRssMap!.keys.elementAt(i)),
          valueGetter: () => categoryIndex,
          onSelectedItemChanged: (i) => categoryIndex = i,
          onPop: (i) => onChange(i));
    }
    return MacosPopupButton(
        value: categoryIndex,
        items: List.generate(provider.categoryRssMap!.length, (index) {
          final key = provider.categoryRssMap!.keys.elementAt(index);
          return MacosPopupMenuItem(
              value: index, enabled: !key.startsWith('*'), child: Text(key));
        }),
        onChanged: onChange);
  }

  Widget searchBar(List<Item>? results) {
    if (!kIsDesktop) {
      return CupertinoSearchTextField(
          autofocus: false,
          autocorrect: false,
          controller: _searchController,
          placeholder: 'Search for something...',
          onSubmitted: (_) => updateUrl(),
          onChanged: (v) {
            // called only on clear button
            if (v.isEmpty) {
              updateUrl();
            }
          });
    }
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: MacosSearchField(
          autofocus: false,
          autocorrect: false,
          maxLines: 1,
          controller: _searchController,
          placeholder: 'Search for something...',
          maxResultsToShow: kIsDesktop ? 10 : 4,
          results: results
              ?.map((e) =>
                  SearchResultItem(e.name, child: RssSearchResult(item: e)))
              .toList(growable: false),
          onChanged: (_) => updateUrl(),
          onResultSelected: (e) =>
              (e.child as RssSearchResult).item.showDialog(context)),
    );
  }

  void updateUrl() {
    if (provider.authorRssMap != null &&
        authorIndex >= provider.authorRssMap!.length) {
      authorIndex = 0;
    }
    if (provider.categoryRssMap != null &&
        categoryIndex >= provider.categoryRssMap!.length) {
      categoryIndex = 0;
    }
    urlListenable.value = provider.searchUrl(
        query: query, author: selectedAuthor, category: selectedCategory);
  }

  Widget urlBar(String url) {
    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: url)).then((value) {
          if (kIsDesktop) {
            return showMacosAlertDialog(
                context: context,
                builder: (context) => MacosAlertDialog(
                      appIcon: const SizedBox.shrink(),
                      title: const Text('Copied to clipboard'),
                      message: const SizedBox.shrink(),
                      primaryButton: PushButton(
                          controlSize: ControlSize.large,
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Dismiss')),
                    ));
          }
          return showCupertinoDialog(
              context: context,
              builder: (context) => CupertinoAlertDialog(
                    title: const Text('Copied to clipboard'),
                    actions: [
                      CupertinoDialogAction(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Dismiss'))
                    ],
                  ));
        });
      },
      child: urlBarInner(url),
    );
  }

  Widget urlBarInner(String url) {
    return SizedBox(
      width: double.infinity,
      child: Container(
          decoration: BoxDecoration(
              color: CupertinoColors.darkBackgroundGray,
              borderRadius: BorderRadius.circular(4),
              shape: BoxShape.rectangle),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
            child: Text(url, style: kMonoTextStyle),
          )),
    );
  }
}
