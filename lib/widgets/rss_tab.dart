import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import '../main.dart';
import '../services/subscription.dart';
import '../style.dart';
import '../utils/fetch_rss.dart';
import '../utils/rss_providers.dart';
import 'cupertino_picker_button.dart';
import 'item_dialog.dart';
import 'item_view.dart';

typedef KV = MapEntry<String, String?>;

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

  late int? _selectedCategoryIndex = provider.categoryRssMap == null ? null : 0;
  late int? _selectedAuthorIndex = provider.authorRssMap == null ? null : 0;
  final _searchController = TextEditingController();

  late var provider = widget.provider;

  List<Widget> get buttons => [
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
                      category: selectedCategory?.value,
                      author: selectedAuthor?.value)
                  .then((value) async {
                await showMacosAlertDialog(
                    context: context,
                    builder: (context) {
                      return MacosAlertDialog(
                        title: Text(value ? 'Success' : 'Error'),
                        message: Text(value
                            ? 'Subscription added $_keyword from ${provider.name}'
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
              });
            })
      ];

  KV? get selectedAuthor => _selectedAuthorIndex != null
      ? provider.authorRssMap?.entries.elementAt(_selectedAuthorIndex!)
      : null;

  KV? get selectedCategory => _selectedCategoryIndex != null
      ? provider.categoryRssMap?.entries.elementAt(_selectedCategoryIndex!)
      : null;

  Widget authorDropdown() {
    final enabled = _keyword.isNotEmpty
        ? provider.supportAdvancedSearch
            ? (provider.authorRssMap?.isNotEmpty ?? false)
            : false
        : provider.authorRssMap != null;
    return enabled ? authorDropdownInner() : const SizedBox.shrink();
  }

  Widget authorDropdownInner() {
    onChange(int? e) => setState(() {
          _selectedAuthorIndex = e;
          if (!provider.supportAdvancedSearch) {
            _searchController.clear();
            _selectedCategoryIndex = null;
          }
        });
    if (!kIsDesktop) {
      return CupertinoPickerButton(
          items: provider.authorRssMap?.entries,
          itemBuilder: (e) => Text(e.key),
          value: selectedAuthor,
          onPop: (e) {
            if (e == null) {
              return;
            }
            onChange(provider.authorRssMap?.keys.toList().indexOf(e.key));
          });
    }

    return MacosPopupButton(
        value: _selectedAuthorIndex,
        items: List.generate(provider.authorRssMap!.length, (index) {
          final key = provider.authorRssMap!.keys.elementAt(index);
          return MacosPopupMenuItem(
              value: index, enabled: !key.startsWith('*'), child: Text(key));
        }),
        onChanged: onChange);
  }

  @override
  Widget build(BuildContext context) {
    if (!mounted) {
      return const SizedBox.shrink();
    }
    final url = provider.searchUrl(
        query: _keyword,
        author: selectedAuthor?.value,
        category: selectedCategory?.value);
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
                Row(
                  children: [
                    Expanded(
                      child: CupertinoPickerButton(
                          value: provider,
                          items: kRssProviders,
                          itemBuilder: (e) =>
                              Text(e.name, style: kItemTitleTextStyle),
                          onPop: (value) {
                            if (value == null) {
                              return;
                            }
                            setState(() => provider = value);
                          }),
                    ),
                    Expanded(child: categoryDropdown()),
                    const SizedBox(
                      width: 4,
                    ),
                    Expanded(child: authorDropdown())
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
                    categoryDropdown(),
                    const SizedBox(
                      width: 4,
                    ),
                    authorDropdown(),
                    ...buttons
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

  Widget categoryDropdown() {
    final enabled = _keyword.isNotEmpty
        ? provider.supportAdvancedSearch
            ? (provider.categoryRssMap?.isNotEmpty ?? false)
            : false
        : provider.categoryRssMap != null;
    return enabled ? categoryDropdownInner() : const SizedBox.shrink();
  }

  Widget categoryDropdownInner() {
    onChange(int? e) => setState(() {
          _selectedCategoryIndex = e;
          if (!provider.supportAdvancedSearch) {
            _searchController.clear();
            _selectedAuthorIndex = null;
          }
        });
    if (!kIsDesktop) {
      return CupertinoPickerButton(
          items: provider.categoryRssMap?.entries,
          itemBuilder: (e) => Text(e.key),
          value: selectedCategory,
          onPop: (e) {
            if (e == null) {
              return;
            }
            onChange(provider.categoryRssMap?.keys.toList().indexOf(e.key));
          });
    }
    return MacosPopupButton(
        value: _selectedCategoryIndex,
        items: List.generate(provider.categoryRssMap!.length, (index) {
          final key = provider.categoryRssMap!.keys.elementAt(index);
          return MacosPopupMenuItem(
              value: index, enabled: !key.startsWith('*'), child: Text(key));
        }),
        onChanged: onChange);
  }

  @override
  void didUpdateWidget(RSSTab oldWidget) {
    if (provider.authorRssMap == null) {
      _selectedAuthorIndex = null;
    } else {
      if (_selectedAuthorIndex! >= provider.authorRssMap!.length) {
        _selectedAuthorIndex = 0;
      }
    }
    if (provider.categoryRssMap == null) {
      _selectedCategoryIndex = null;
    } else {
      if (_selectedCategoryIndex! >= provider.categoryRssMap!.length) {
        _selectedCategoryIndex = 0;
      }
    }
    super.didUpdateWidget(oldWidget);
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
          _selectedAuthorIndex = null;
          _selectedCategoryIndex = null;
        }
      });
    });
    super.initState();
  }

  Widget searchBar(List<Item>? results) {
    if (!kIsDesktop) {
      return CupertinoSearchTextField(
          autofocus: false,
          autocorrect: false,
          controller: _searchController,
          placeholder: 'Search for something...');
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
          onResultSelected: (e) => showMacosSheet(
              context: context,
              builder: (context) => ItemDialog(
                  (e.child as RssSearchResult).item,
                  context: context))),
    );
  }

  Widget urlBar(String url) {
    return GestureDetector(
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
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Dismiss')),
                    )));
      },
      child: urlBarInner(url),
    );
  }

  Widget urlBarInner(String url) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4.0),
      child: SizedBox(
        width: double.infinity,
        child: Card(
            color: Colors.black26,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(vertical: 6.0, horizontal: 4.0),
              child: Text(url, style: kMonoTextStyle),
            )),
      ),
    );
  }
}
