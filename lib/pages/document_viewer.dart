import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:path/path.dart' as pathlib;

import '/main.dart' show kIsDesktop;
import '/style.dart';

final _kExtToMd = {
  'md': 'markdown',
  'gs': 'json',
  'json': 'json',
  'txt': 'plaintext',
  'srt': 'plaintext',
  'ass': 'plaintext',
  'html': 'html',
  'htm': 'html',
  'css': 'css',
};

class DocumentViewer extends StatelessWidget {
  final String path;
  const DocumentViewer({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    if (File(path).statSync().size > 2 * 1024 * 1024) {
      return const Center(child: Text('File is too large'));
    }
    return FutureBuilder(
        future: File(path).readAsString(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          }
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CupertinoActivityIndicator());
          }
          return Column(
            children: [
              Text(pathlib.basename(path), style: kItemTitleTextStyle),
              Expanded(
                child: Markdown(
                  selectable: true,
                  shrinkWrap: false,
                  softLineBreak: true,
                  styleSheetTheme: kIsDesktop
                      ? MarkdownStyleSheetBaseTheme.material
                      : MarkdownStyleSheetBaseTheme.cupertino,
                  styleSheet: MarkdownStyleSheet(
                    codeblockDecoration: const BoxDecoration(
                      color: CupertinoColors.black,
                    ),
                    code: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: CupertinoColors.white,
                      backgroundColor: CupertinoColors.black,
                    ),
                  ),
                  data:
                      '```${_kExtToMd[pathlib.extension(path).substring(1)] ?? 'plaintext'}\n${snapshot.data}\n```',
                ),
              ),
            ],
          );
        });
  }
}
