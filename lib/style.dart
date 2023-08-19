import 'package:flutter/cupertino.dart';

const double kCoverPhotoWidth = 300.0;
const double kItemTextSize = 14.0;
const double kPagePadding = 16.0;
const double kSidebarMinWidth = 180.0;
const double kDesktopTitleBarHeight = 40.0;
const double kDownloadListTileIconSize = 21.0;
const kItemTitleTextStyle = TextStyle(
    fontWeight: FontWeight.w500, fontSize: kItemTextSize, inherit: false);
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
