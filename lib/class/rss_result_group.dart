import '/pages/rss_item_dialog.dart';
import '/widgets/adaptive.dart';
import 'rss_item.dart';

typedef RssResultGroup = MapEntry<String, List<RSSItem>>;

extension DialogExt on RssResultGroup {
  Future<void> showDialog() async {
    await showAdaptivePopup(builder: (_) => RssResultDialog(value));
  }
}

extension DialogSingleItemExt on RSSItem {
  Future<void> showDialog() async {
    await showAdaptivePopup(builder: (_) => RssResultDialog([this]));
  }
}
