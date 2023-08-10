import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:macos_ui/macos_ui.dart';

import '../classes/item.dart';
import '../style.dart';
import '../utils/gradient.dart';
import '../services/torrent.dart';
import '../services/torrent_ext.dart';

class ItemDialog extends MacosSheet {
  ItemDialog(Item item, {required BuildContext context, super.key})
      : super(
            backgroundColor: Colors.black.withAlpha(147),
            child: Container(
              decoration: gradientDecoration,
              padding: const EdgeInsets.all(32.0),
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      item.name,
                      style: kItemTitleTextStyle,
                    ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Html(
                          data: item.description,
                        ),
                      ),
                    ),
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
                  ]),
            ));
}
