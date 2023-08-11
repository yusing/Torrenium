import 'package:flutter/cupertino.dart';

import '../utils/rss_providers.dart';
import '../widgets/download_list_dialog.dart';
import '../widgets/rss_tab.dart';
import '../widgets/subscriptions_dialog.dart';

class MobileTab {
  final String title;
  final IconData icon;
  final StatefulWidget child;

  const MobileTab(this.title, this.icon, this.child);
}

class MobileView extends StatefulWidget {
  // TODO: fix download, subs tab not updating

  static final _tabController = CupertinoTabController();
  static final kPages = [
    MobileTab(
        'Home', CupertinoIcons.home, RSSTab(provider: kRssProviders.first)),
    MobileTab(
        'Downloads', CupertinoIcons.down_arrow, DownloadListDialog.content()),
    MobileTab(
        'Subscriptions', CupertinoIcons.star, SubscriptionsDialog.content()),
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
