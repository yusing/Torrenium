import 'package:flutter/cupertino.dart';

import '/widgets/file_browser.dart';
import '/widgets/group_list_dialog.dart';
import '/widgets/rss_tab.dart';
import '/widgets/subscriptions_dialog.dart';
import '/widgets/watch_history.dart';

class MobileTab {
  final String title;
  final IconData icon;
  final Widget child;

  const MobileTab(this.title, this.icon, this.child);
}

class MobileView extends StatefulWidget {
  // TODO: fix download, subs tab not updating

  static final _tabController = CupertinoTabController();
  static const kPages = [
    MobileTab('Home', CupertinoIcons.home, RSSTab()),
    MobileTab('Subscriptions', CupertinoIcons.star, SubscriptionsDialog()),
    MobileTab('Downloads', CupertinoIcons.down_arrow, DownloadListDialog()),
    MobileTab('Files', CupertinoIcons.doc, FileBrowser()),
    MobileTab('History', CupertinoIcons.time, WatchHistoryPage()),
  ];
  const MobileView({super.key});

  @override
  State<MobileView> createState() => _MobileViewState();
}

class _MobileViewState extends State<MobileView> {
  @override
  Widget build(BuildContext context) {
    return CupertinoTabScaffold(
        controller: MobileView._tabController,
        tabBar: CupertinoTabBar(
            items: List.generate(
                MobileView.kPages.length,
                (i) => BottomNavigationBarItem(
                      icon: Icon(MobileView.kPages[i].icon),
                      label: MobileView.kPages[i].title,
                    ))),
        tabBuilder: (context, index) => CupertinoTabView(
              builder: (context) => CupertinoPageScaffold(
                child: SafeArea(
                    child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 8.0, vertical: 4.0),
                  child: MobileView.kPages[index].child,
                )),
              ),
            ));
  }
}
