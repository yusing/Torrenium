import 'package:flutter/cupertino.dart';

import '/widgets/adaptive.dart';
import '/widgets/rss_result_dialog.dart';
import 'item.dart';

typedef RssResultGroup = MapEntry<String, List<Item>>;

extension DialogExt on RssResultGroup {
  Future<void> showDialog(BuildContext context) async {
    await showAdaptivePopup(
        context: context, builder: (_) => RssResultDialog(value));
  }
}
