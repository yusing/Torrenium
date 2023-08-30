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
import '/utils/fetch_rss.dart';
import '/utils/show_snackbar.dart';
import '/view/rss_result_view.dart';
import '/widgets/adaptive.dart';
import '/widgets/cupertino_picker_button.dart';

var gAuthorIndex = 0;
var gCategoryIndex = 0;
var gQuery = '';

final searchController = TextEditingController(text: gQuery)
  ..addListener(searchBarListener); // shared across all tabs (RSSProvider)

final scrollController = ScrollController()
  ..addListener(() {
    focusNode.unfocus();
  });

final focusNode = FocusNode();

final urlListenable = ValueNotifier(_rssProvider.searchUrl(
    query: gQuery, author: gSelectedAuthor, category: gSelectedCategory));

var _rssProvider = kRssProviders.first;

String? get gSelectedAuthor =>
    _rssProvider.authorRssMap?.values.elementAt(gAuthorIndex);

String? get gSelectedCategory =>
    _rssProvider.categoryRssMap?.values.elementAt(gCategoryIndex);

void searchBarListener() {
  if (gQuery == searchController.text) {
    return;
  }
  gQuery = searchController.text;
  // clear button workaround
  if (gQuery.isEmpty) {
    updateUrl();
  }
}

void updateUrl() {
  if (_rssProvider.authorRssMap != null &&
      gAuthorIndex >= _rssProvider.authorRssMap!.length) {
    gAuthorIndex = 0;
  }
  if (_rssProvider.categoryRssMap != null &&
      gCategoryIndex >= _rssProvider.categoryRssMap!.length) {
    gCategoryIndex = 0;
  }
  urlListenable.value = _rssProvider.searchUrl(
      query: gQuery, author: gSelectedAuthor, category: gSelectedCategory);
}

typedef KV = MapEntry<String, String?>;

class RSSTab extends StatelessWidget {
  const RSSTab({super.key});

  static final MacosTabController? tabControllerDesktop = kIsDesktop
      ? (MacosTabController(length: kRssProviders.length)
        ..addListener(() {
          _rssProvider = kRssProviders[tabControllerDesktop!.index];
          updateUrl();
        }))
      : null;

  List<Widget> get buttons => [
        AdaptiveTextButton(
            icon: const AdaptiveIcon(CupertinoIcons.star),
            label: const Text('Subscribe'),
            onPressed: () async {
              if (gQuery.trim().isEmpty) {
                return;
              }
              await gSubscriptionManager
                  .addSubscription(Subscription(
                      providerName: _rssProvider.name,
                      keyword: gQuery,
                      category: gSelectedCategory,
                      author: gSelectedAuthor))
                  .then((value) => showAdaptiveAlertDialog(
                        title:
                            value ? const Text('Success') : const Text('Error'),
                        content: Text(value
                            ? 'Subscription added $gQuery from ${_rssProvider.name}'
                            : 'Subscription already exists'),
                      ));
            })
      ];

  @override
  Widget build(BuildContext context) {
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
                      controller: scrollController,
                    )
                  : RssResultGridView(
                      _rssProvider,
                      snapshot.data!,
                      controller: scrollController,
                    ));

  Widget content(String url) => FutureBuilder(
        future: getRSSResults(_rssProvider,
            query: gQuery,
            author: gSelectedAuthor,
            category: gSelectedCategory),
        builder: (_, snapshot) {
          if (snapshot.hasError) {
            Logger().e(snapshot.stackTrace, snapshot.error);
          }

          return Column(
            children: [
              if (kIsDesktop)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: urlBar(url),
                ),
              if (!kIsDesktop) ...[
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
                child: Builder(builder: (_) => builder(snapshot)),
              ),
            ],
          );
        },
      );

  Widget pickerAuthor() {
    final enabled = gQuery.isNotEmpty
        ? _rssProvider.supportAdvancedSearch
            ? (_rssProvider.authorRssMap?.isNotEmpty ?? false)
            : false
        : _rssProvider.authorRssMap != null;
    return enabled
        ? AdaptiveDropDown(
            value: gAuthorIndex,
            items: _rssProvider.authorRssMap!.entries,
            textGetter: (entry) => entry.key,
            onChange: (int e) {
              gAuthorIndex = e;
              if (!_rssProvider.supportAdvancedSearch) {
                searchController.clear();
              }
              updateUrl();
            })
        : const SizedBox.shrink();
  }

  Widget pickerCategory() {
    final enabled = gQuery.isNotEmpty
        ? _rssProvider.supportAdvancedSearch
            ? (_rssProvider.categoryRssMap?.isNotEmpty ?? false)
            : false
        : _rssProvider.categoryRssMap != null;
    return enabled
        ? AdaptiveDropDown(
            value: gCategoryIndex,
            items: _rssProvider.categoryRssMap!.entries,
            textGetter: (entry) => entry.key,
            onChange: (int e) {
              gCategoryIndex = e;
              if (!_rssProvider.supportAdvancedSearch) {
                searchController.clear();
              }
              updateUrl();
            })
        : const SizedBox.shrink();
  }

  Widget searchBar(List<RssResultGroup>? results) {
    if (!kIsDesktop) {
      return CupertinoSearchTextField(
          autofocus: false,
          autocorrect: false,
          controller: searchController,
          focusNode: focusNode,
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
          controller: searchController,
          focusNode: focusNode,
          placeholder: 'Search for something...',
          maxResultsToShow: kIsDesktop ? 10 : 4,
          results: results?.map((e) => SearchResultItem(e.key)).toList(),
          onChanged: (_) => updateUrl(),
          onResultSelected: (e) => (e.child as RssResultGroup).showDialog()),
    );
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
