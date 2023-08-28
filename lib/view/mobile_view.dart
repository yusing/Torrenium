import 'package:flutter/cupertino.dart';

import '/pages/file_browser.dart';
import '/pages/item_listview.dart';
import '/pages/rss_tab.dart';
import '/pages/settings.dart';
import '/pages/subscriptions_dialog.dart';
import '/pages/watch_history.dart';

class MobileTab {
  final String title;
  final IconData icon;
  final Widget child;

  const MobileTab(this.title, this.icon, this.child);
}

class MobileView extends StatelessWidget {
  // TODO: fix download, subs, files tab not updating

  static final _tabController = CupertinoTabController();
  static const kPages = [
    MobileTab('Home', CupertinoIcons.home, RSSTab(key: ValueKey('home'))),
    MobileTab('Subscriptions', CupertinoIcons.star,
        SubscriptionsDialog(key: ValueKey('subs'))),
    MobileTab('Downloads', CupertinoIcons.down_arrow,
        DownloadsListView(key: ValueKey('downloads'))),
    MobileTab(
        'Files', CupertinoIcons.folder, FileBrowser(key: ValueKey('files'))),
    MobileTab('History', CupertinoIcons.time,
        WatchHistoryPage(key: ValueKey('history'))),
    MobileTab('Settings', CupertinoIcons.settings,
        SettingsPage(key: ValueKey('settings'))),
  ];
  const MobileView({super.key});

  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
        controller: _tabController,
        tabBar: CupertinoTabBar(
            items: List.generate(
                kPages.length,
                (i) => BottomNavigationBarItem(
                      icon: Icon(kPages[i].icon),
                      label: kPages[i].title,
                    ))),
        tabBuilder: (context, index) => CupertinoTabView(
              builder: (context) => CupertinoPageScaffold(
                child: SafeArea(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: kPages[index].child,
                )),
              ),
            ));
  }
}
