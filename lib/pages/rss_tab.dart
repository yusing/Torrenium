import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';

import '/class/rss_result_group.dart';
import '/main.dart' show kIsDesktop;
import '/services/rss_providers.dart';
import '/services/subscription.dart';
import '/style.dart';
import '/utils/show_snackbar.dart';
import '/view/rss_result_view.dart';
import '/widgets/adaptive.dart';
import '/widgets/cupertino_picker_button.dart';

var _authorIndex = 0;
var _categoryIndex = 0;
var _query = '';

var _rssProvider = kRssProviders.first;

final _searchController = TextEditingController(text: _query)
  ..addListener(_searchBarListener); // shared across all tabs (RSSProvider)

final _urlListenable = ValueNotifier(_rssProvider.searchUrl(
    query: _query, author: _selectedAuthor, category: _selectedCategory));

String? get _selectedAuthor =>
    _rssProvider.authorRssMap?.values.elementAt(_authorIndex);

String? get _selectedCategory =>
    _rssProvider.categoryRssMap?.values.elementAt(_categoryIndex);

void _searchBarListener() {
  if (_query == _searchController.text) {
    return;
  }
  _query = _searchController.text;
  // clear button workaround
  if (_query.isEmpty) {
    _updateUrl();
  }
}

void _updateUrl() {
  if (_rssProvider.authorRssMap != null &&
      _authorIndex >= _rssProvider.authorRssMap!.length) {
    _authorIndex = 0;
  }
  if (_rssProvider.categoryRssMap != null &&
      _categoryIndex >= _rssProvider.categoryRssMap!.length) {
    _categoryIndex = 0;
  }
  _urlListenable.value = _rssProvider.searchUrl(
      query: _query, author: _selectedAuthor, category: _selectedCategory);
}

typedef KV = MapEntry<String, String?>;

class RSSTab extends StatelessWidget {
  static final MacosTabController? tabControllerDesktop = kIsDesktop
      ? (MacosTabController(length: kRssProviders.length)
        ..addListener(() {
          _rssProvider = kRssProviders[tabControllerDesktop!.index];
          _updateUrl();
        }))
      : null;

  const RSSTab({super.key});

  List<Widget> get buttons => [
        AdaptiveTextButton(
            icon: const AdaptiveIcon(CupertinoIcons.star),
            label: const Text('Subscribe'),
            onPressed: () async {
              if (_query.trim().isEmpty) {
                return;
              }
              await gSubscriptionManager
                  .addSubscription(Subscription(
                      providerName: _rssProvider.name,
                      keyword: _query,
                      category: _selectedCategory,
                      author: _selectedAuthor))
                  .then((value) => showAdaptiveAlertDialog(
                        title:
                            value ? const Text('Success') : const Text('Error'),
                        content: Text(value
                            ? 'Subscription added $_query from ${_rssProvider.name}'
                            : 'Subscription already exists'),
                      ));
            })
      ];

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
        valueListenable: _urlListenable,
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
                          ))
                    ..animate().fadeIn(duration: 300.ms),
                  controller: tabControllerDesktop!)
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

  Widget builder(AsyncSnapshot snapshot) => snapshot.hasError
      ? Center(child: Text('${snapshot.error}'))
      : snapshot.connectionState != ConnectionState.done
          ? const Center(child: CupertinoActivityIndicator())
          : (!snapshot.hasData || snapshot.data!.isEmpty)
              ? const Text('No result found')
              : (_rssProvider.detailGetter.getCoverUrl == null
                  ? RssResultListView(
                      snapshot.data!,
                    )
                  : RssResultGridView(
                      _rssProvider,
                      snapshot.data!,
                    ));

  Widget content(String url) => FutureBuilder(
        future: _rssProvider.getRSSResults(
            query: _query,
            author: _selectedAuthor,
            category: _selectedCategory),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            Logger().e(snapshot.stackTrace, snapshot.error);
          }

          if (kIsDesktop) {
            return Column(
              children: [
                urlBar(url),
                Row(
                  children: [
                    Expanded(child: searchBar(snapshot.data)),
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
                  child: Builder(builder: (_) => builder(snapshot)),
                ),
              ],
            );
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(child: searchBar(snapshot.data)),
                  ...buttons
                ],
              ),
              urlBar(url),
              Row(
                children: [
                  Expanded(
                    child: CupertinoPickerButton(
                        valueGetter: () => _rssProvider,
                        items: kRssProviders,
                        itemBuilder: (e) =>
                            Text(e.name, style: kItemTitleTextStyle),
                        onSelectedItemChanged: (value) =>
                            _rssProvider = kRssProviders[value],
                        onPop: (value) {
                          _rssProvider = value;
                          _updateUrl();
                        }),
                  ),
                  Expanded(child: pickerCategory()),
                  const SizedBox(
                    width: 4,
                  ),
                  Expanded(child: pickerAuthor())
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: Builder(builder: (_) => builder(snapshot)),
              ),
            ],
          );
        },
      );

  Widget pickerAuthor() {
    final enabled = _query.isNotEmpty
        ? _rssProvider.supportAdvancedSearch
            ? (_rssProvider.authorRssMap?.isNotEmpty ?? false)
            : false
        : _rssProvider.authorRssMap != null;
    return enabled
        ? AdaptiveDropDown(
            value: _authorIndex,
            items: _rssProvider.authorRssMap!.entries,
            textGetter: (entry) => entry.key,
            onChange: (int e) {
              _authorIndex = e;
              if (!_rssProvider.supportAdvancedSearch) {
                _searchController.clear();
              }
              _updateUrl();
            })
        : const SizedBox.shrink();
  }

  Widget pickerCategory() {
    final enabled = _query.isNotEmpty
        ? _rssProvider.supportAdvancedSearch
            ? (_rssProvider.categoryRssMap?.isNotEmpty ?? false)
            : false
        : _rssProvider.categoryRssMap != null;
    return enabled
        ? AdaptiveDropDown(
            value: _categoryIndex,
            items: _rssProvider.categoryRssMap!.entries,
            textGetter: (entry) => entry.key,
            onChange: (int e) {
              _categoryIndex = e;
              if (!_rssProvider.supportAdvancedSearch) {
                _searchController.clear();
              }
              _updateUrl();
            })
        : const SizedBox.shrink();
  }

  Widget searchBar(List<RssResultGroup>? results) {
    if (!kIsDesktop) {
      return CupertinoSearchTextField(
          key: const ValueKey('searchBar'),
          autofocus: false,
          autocorrect: false,
          controller: _searchController,
          placeholder: 'Search for something...',
          onSubmitted: (_) => _updateUrl(),
          onChanged: (v) {
            // called only on clear button
            if (v.isEmpty) {
              _updateUrl();
            }
          });
    }
    return MacosSearchField(
        key: const ValueKey('searchBar'),
        autofocus: false,
        autocorrect: false,
        maxLines: 1,
        controller: _searchController,
        placeholder: 'Search for something...',
        maxResultsToShow: kIsDesktop ? 10 : 4,
        results: results?.map((e) => SearchResultItem(e.key)).toList(),
        onChanged: (_) => _updateUrl(),
        onResultSelected: (e) => (e.child as RssResultGroup).showDialog());
  }

  Widget urlBar(String url) {
    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: url))
            .then((value) => showSnackBar('Copied to clipboard', url));
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
