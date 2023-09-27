import 'package:flutter/cupertino.dart';

const double kCoverPhotoWidth = 300.0;
const double kItemTextSize = 16.0;
const double kSubtitleTextSize = 14.0;
const double kPagePadding = 16.0;
const double kSidebarMinWidth = 180.0;
const double kDesktopTitleBarHeight = 40.0;
const double kDownloadListTileIconSize = 21.0;
const double kListTileThumbnailWidth = 180.0;
const double kListTileThumbnailMinHeight = 100.0;
const kCupertinoThemeData = CupertinoThemeData(
    brightness: Brightness.dark,
    primaryColor: CupertinoColors.activeOrange,
    scaffoldBackgroundColor: CupertinoColors.black,
    applyThemeToAll: true);
const kItemTitleTextStyle =
    TextStyle(fontSize: kItemTextSize, color: CupertinoColors.white);
const kItemSubtitleTextStyle =
    TextStyle(fontSize: kSubtitleTextSize, color: CupertinoColors.systemGrey);
const kMonoTextStyle = TextStyle(
    fontSize: 12,
    color: CupertinoColors.white,
    fontFamily: 'monospace',
    letterSpacing: 1,
    fontWeight: FontWeight.w500);
const gradientDecoration = BoxDecoration(
    shape: BoxShape.rectangle,
    borderRadius: BorderRadius.all(Radius.circular(10)),
    gradient: LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        tileMode: TileMode.decal,
        colors: [
          Color.fromARGB(16, 127, 127, 127),
          Color.fromARGB(16, 0, 0, 0),
        ]));
