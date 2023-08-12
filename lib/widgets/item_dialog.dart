import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import '../main.dart' show kIsDesktop;
import '../services/torrent.dart';
import '../services/torrent_ext.dart';
import '../style.dart';
import '../utils/gradient.dart';

class ItemDialog extends MacosSheet {
  ItemDialog(BuildContext context, Item item, {super.key})
      : super(
            backgroundColor: Colors.black.withAlpha(147),
            child: Container(
                decoration: gradientDecoration,
                padding: EdgeInsets.all(kIsDesktop ? 32.0 : 8.0),
                child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        item.name,
                        style: kItemTitleTextStyle,
                      ),
                      Expanded(child: content(context, item)),
                      const SizedBox(height: 10),
                      Row(
                        mainAxisSize: MainAxisSize.max,
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          PushButton(
                            controlSize: ControlSize.large,
                            child: const Text('Download'),
                            onPressed: () => gTorrentManager.download(item,
                                context: context, pop: true),
                          ),
                          const SizedBox(
                            width: 16,
                          ),
                          PushButton(
                            controlSize: ControlSize.large,
                            child: const Text('Dismiss'),
                            onPressed: () => Navigator.of(context).pop(),
                          )
                        ],
                      )
                    ])));
  static Widget content(BuildContext context, Item item) =>
      SingleChildScrollView(
        child: Html(
          data: item.description,
        ),
      );
}
