import 'package:flutter/cupertino.dart';

import '../style.dart';
import '../utils/rss_providers.dart';
import '../widgets/cupertino_picker_button.dart';
import '../widgets/download_list_dialog.dart';
import '../widgets/rss_tab.dart';
import '../widgets/subscriptions_dialog.dart';

class MobileTab {
  final String title;
  final IconData icon;
  final StatefulWidget child;
  final Widget? trailing;

  const MobileTab(this.title, this.icon, this.child, {this.trailing});
}

class MobileView extends StatefulWidget {
  // TODO: fix download, subs tab not updating

  static final _selectedRSSProvider = ValueNotifier(kRssProviders.first);
  static final _tabController = CupertinoTabController();
  static final kPages = [
    MobileTab(
        'Home',
        CupertinoIcons.home,
        ValueListenableBuilder(
            valueListenable: _selectedRSSProvider,
            builder: (_, value, __) => RSSTab(provider: value)),
        trailing: ValueListenableBuilder(
            valueListenable: _selectedRSSProvider,
            builder: (context, value, __) {
              return FittedBox(
                fit: BoxFit.scaleDown,
                child: CupertinoPickerButton(
                  value: value,
                  items: kRssProviders,
                  itemBuilder: (e) => Text(e.name, style: kItemTitleTextStyle),
                  onPop: (value) =>
                      _selectedRSSProvider.value = value ?? kRssProviders.first,
                ),
              );
            })),
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
                navigationBar: CupertinoNavigationBar(
                  middle: Text(
                    MobileView.kPages[index].title,
                    style: kItemTitleTextStyle,
                  ),
                  trailing: MobileView.kPages[index].trailing ??
                      CupertinoButton(
                          onPressed: () => setState(() {}),
                          child: const Icon(
                            CupertinoIcons.refresh,
                            size: 16,
                          )),
                ),
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
