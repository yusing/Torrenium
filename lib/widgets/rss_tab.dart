import 'package:bot_toast/bot_toast.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:flutter_offline/flutter_offline.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';

import '/class/rss_result_group.dart';
import '/main.dart' show kIsDesktop;
import '/services/rss_providers.dart';
import '/services/subscription.dart';
import '/style.dart';
import '/utils/fetch_rss.dart';
import 'adaptive.dart';
import 'cupertino_picker_button.dart';
import 'rss_result_view.dart';

var gAuthorIndex = 0;
var gCategoryIndex = 0;
var gQuery = '';
var gRssProvider = kRssProviders.first;

final searchController = TextEditingController(text: gQuery)
  ..addListener(searchBarListener); // shared across all tabs (RSSProvider)

final urlListenable = ValueNotifier(gRssProvider.searchUrl(
    query: gQuery, author: gSelectedAuthor, category: gSelectedCategory));

String? get gSelectedAuthor =>
    gRssProvider.authorRssMap?.values.elementAt(gAuthorIndex);

String? get gSelectedCategory =>
    gRssProvider.categoryRssMap?.values.elementAt(gCategoryIndex);

void searchBarListener() {
  gQuery = searchController.text;
  // clear button workaround
  if (searchController.text.isEmpty) {
    updateUrl();
  }
}

void updateUrl() {
  if (gRssProvider.authorRssMap != null &&
      gAuthorIndex >= gRssProvider.authorRssMap!.length) {
    gAuthorIndex = 0;
  }
  if (gRssProvider.categoryRssMap != null &&
      gCategoryIndex >= gRssProvider.categoryRssMap!.length) {
    gCategoryIndex = 0;
  }
  urlListenable.value = gRssProvider.searchUrl(
      query: gQuery, author: gSelectedAuthor, category: gSelectedCategory);
}

typedef KV = MapEntry<String, String?>;

class RSSTab extends StatefulWidget {
  const RSSTab({super.key});

  @override
  State<RSSTab> createState() => _RSSTabState();
}

class _RSSTabState extends State<RSSTab> {
  late final MacosTabController? tabControllerDesktop = kIsDesktop
      ? (MacosTabController(length: kRssProviders.length)
        ..addListener(() {
          gRssProvider = kRssProviders[tabControllerDesktop!.index];
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
                  .addSubscription(
                      providerName: gRssProvider.name,
                      keyword: gQuery,
                      category: gSelectedCategory,
                      author: gSelectedAuthor)
                  .then((value) => showAdaptiveAlertDialog(
                        context: context,
                        title:
                            value ? const Text('Success') : const Text('Error'),
                        content: Text(value
                            ? 'Subscription added $gQuery from ${gRssProvider.name}'
                            : 'Subscription already exists'),
                      ));
            })
      ];

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

  Widget content(String url) => FutureBuilder(
        future: getRSSResults(gRssProvider,
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
                          valueGetter: () => gRssProvider,
                          items: kRssProviders,
                          itemBuilder: (e) =>
                              Text(e.name, style: kItemTitleTextStyle),
                          onSelectedItemChanged: (value) =>
                              gRssProvider = kRssProviders[value],
                          onPop: (value) {
                            gRssProvider = value;
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
                            : (gRssProvider.detailGetter.getCoverUrl == null
                                ? RssResultListView(snapshot.data!)
                                : RssResultGridView(snapshot.data!))
                        : const Center(
                            child: CupertinoActivityIndicator(),
                          )),
              ),
            ],
          );
        },
      );

  @override
  void initState() {
    gAuthorIndex = 0;
    gCategoryIndex = 0;
    super.initState();
  }

  Widget pickerAuthor() {
    final enabled = gQuery.isNotEmpty
        ? gRssProvider.supportAdvancedSearch
            ? (gRssProvider.authorRssMap?.isNotEmpty ?? false)
            : false
        : gRssProvider.authorRssMap != null;
    return enabled
        ? AdaptiveDropDown(
            value: gAuthorIndex,
            items: gRssProvider.authorRssMap!.entries,
            textGetter: (entry) => entry.key,
            onChange: (int e) {
              gAuthorIndex = e;
              if (!gRssProvider.supportAdvancedSearch) {
                searchController.clear();
              }
              updateUrl();
            })
        : const SizedBox.shrink();
  }

  Widget pickerCategory() {
    final enabled = gQuery.isNotEmpty
        ? gRssProvider.supportAdvancedSearch
            ? (gRssProvider.categoryRssMap?.isNotEmpty ?? false)
            : false
        : gRssProvider.categoryRssMap != null;
    return enabled
        ? AdaptiveDropDown(
            value: gCategoryIndex,
            items: gRssProvider.categoryRssMap!.entries,
            textGetter: (entry) => entry.key,
            onChange: (int e) {
              gCategoryIndex = e;
              if (!gRssProvider.supportAdvancedSearch) {
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
          placeholder: 'Search for something...',
          maxResultsToShow: kIsDesktop ? 10 : 4,
          results: results?.map((e) => SearchResultItem(e.title)).toList(),
          onChanged: (_) => updateUrl(),
          onResultSelected: (e) =>
              (e.child as RssResultGroup).showDialog(context)),
    );
  }

  Widget urlBar(String url) {
    return GestureDetector(
      onLongPress: () async {
        await Clipboard.setData(ClipboardData(text: url))
            .then((value) => BotToast.showText(text: 'Copied to clipboard'));
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
