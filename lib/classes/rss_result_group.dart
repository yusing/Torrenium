import 'package:flutter/cupertino.dart';
import 'package:macos_ui/macos_ui.dart';

import '../main.dart' show kIsDesktop;
import '../widgets/rss_result_dialog.dart';
import 'item.dart';

class RssResultGroup {
  final MapEntry<String, List<Item>> result;

  RssResultGroup(this.result);

  List<Item> get items => result.value;
  String get title => result.key;

  Future<void> showDialog(BuildContext context) async {
    if (kIsDesktop) {
      showMacosSheet(
          context: context,
          builder: (context) => RssResultDialog(context, this));
    } else {
      Navigator.push(
          context,
          CupertinoPageRoute(
              builder: (context) => CupertinoPageScaffold(
                  navigationBar: CupertinoNavigationBar(
                    middle: Text(
                      title,
                      overflow: TextOverflow.ellipsis,
                      softWrap: true,
                    ),
                  ),
                  child: SafeArea(
                      child: RssResultDialog.content(context, this)))));
    }
  }
}
