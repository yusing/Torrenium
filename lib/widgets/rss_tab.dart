import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/classes/item.dart';
import 'package:torrenium/utils/fetch_rss.dart';
import 'package:torrenium/utils/rss_providers.dart';
import 'package:torrenium/widgets/item_dialog.dart';
import 'package:torrenium/widgets/item_gridview.dart';
import 'package:torrenium/widgets/item_listview.dart';

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
  static String? _keyword;
  final _searchController = TextEditingController();
  late var _selectedCategory =
      widget.provider.categoryRssMap?.keys.first; // ALL
  late var _selectedAuthor = widget.provider.authorRssMap?.keys.first;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getItemsFromRSS(widget.provider,
            keyword: _keyword,
            category: _selectedCategory,
            author: _selectedAuthor),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            debugPrintStack(
                label: snapshot.error.toString(),
                stackTrace: snapshot.stackTrace);
            return Center(child: Text(snapshot.error.toString()));
          }
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: MacosSearchField(
                        autofocus: false,
                        autocorrect: false,
                        maxLines: 1,
                        controller: _searchController,
                        placeholder: 'Search...',
                        maxResultsToShow: 10,
                        results: !snapshot.hasData
                            ? []
                            : snapshot.data!
                                .map((e) => SearchResultItem(e.name,
                                    child: RssSearchResult(item: e)))
                                .toList(growable: false),
                        onResultSelected: (e) => showMacosSheet(
                            context: context,
                            builder: (context) => ItemDialog(
                                (e.child as RssSearchResult).item,
                                context: context)),
                        onChanged: (value) => setState(() => _keyword = value)),
                  ),
                  const SizedBox(
                    width: 4,
                  ),
                  MacosPopupButton<String>(
                      value: _selectedCategory,
                      items: widget.provider.categoryRssMap?.keys
                          .map((e) => MacosPopupMenuItem<String>(
                                value: e,
                                enabled: !e.startsWith('*'),
                                child: Text(e),
                              ))
                          .toList(growable: false),
                      onChanged: (e) => setState(() => _selectedCategory = e)),
                  const SizedBox(
                    width: 4,
                  ),
                  Visibility(
                    visible:
                        widget.provider.authorRssMap?.keys.isNotEmpty ?? false,
                    child: MacosPopupButton<String>(
                        value: _selectedAuthor,
                        items: widget.provider.authorRssMap?.keys
                            .map((e) => MacosPopupMenuItem<String>(
                                value: e,
                                enabled: !e.startsWith('*'),
                                child: Text(e)))
                            .toList(growable: false),
                        onChanged: (e) => setState(() => _selectedAuthor = e)),
                  ),
                  MacosIconButton(
                    icon: const MacosIcon(CupertinoIcons.refresh),
                    onPressed: () => setState(() {}),
                  ),
                ],
              ),
              const SizedBox(
                height: 8,
              ),
              Expanded(
                child: (snapshot.hasData
                    ? (widget.provider.coverUrlGetter == null
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
}
