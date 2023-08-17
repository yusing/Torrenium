import 'package:xml/xml.dart';

// TODO: allow adding custom provider
const List<RSSProvider> kRssProviders = [
  RSSProvider(
      name: '動漫花園',
      homePageUrl: 'https://share.dmhy.org/',
      rssPath: 'topics/rss/rss.xml',
      logoPath: 'images/sitelogo.gif',
      searchParams: '?keyword=%q&sort_id=%c&team_id=%a&order=date-desc',
      supportTitleGroup: true,
      categoryRssMap: {
        '所有類別': '0',
        '動畫': '2',
        '漫畫': '3',
        '音樂': '4',
        '遊戲': '9',
        '日劇': '6',
        'RAW': '7',
        '特攝': '12',
        '其他': '1',
      },
      authorRssMap: {
        '所有字幕組': '0',
        '拨雪寻春': '823',
        '動漫花園': '117',
        'NC-Raws': '801',
        '喵萌奶茶屋': '669',
        'Lilith-Raws': '803',
        '魔星字幕团': '648',
        '桜都字幕组': '619',
        '天月動漫&amp;發佈組': '767',
        '极影字幕社': '185',
        'LoliHouse': '657',
        '悠哈C9字幕社': '151',
        '幻月字幕组': '749',
        '天使动漫论坛': '390',
        '动漫国字幕组': '303',
        '幻樱字幕组': '241',
        '爱恋字幕社': '47',
        'DBD制作组': '805',
        'c.c动漫': '604',
        '萝莉社活动室': '550',
        '千夏字幕组': '283',
        'IET字幕組': '772',
        '诸神kamigami字幕组': '288',
        '霜庭云花Sub': '804',
        'GMTeam': '755',
        '风车字幕组': '454',
        '雪飄工作室(FLsnow)': '37',
        'MCE汉化组': '764',
        '丸子家族': '488',
        '星空字幕组': '731',
        '梦蓝字幕组': '574',
        'LoveEcho!': '504',
        'SweetSub': '650',
        '枫叶字幕组': '630',
        'Little Subbers!': '479',
        '轻之国度': '321',
        '云光字幕组': '649',
        '豌豆字幕组': '520',
        '驯兽师联盟': '626',
        '中肯字幕組': '666',
        'SW字幕组': '781',
        '银色子弹字幕组': '576',
        '风之圣殿': '434',
        'YWCN字幕组': '665',
        'KRL字幕组': '228',
        '华盟字幕社': '49',
        '波洛咖啡厅': '627',
        '动音漫影': '88',
        'VCB-Studio': '581',
        'DHR動研字幕組': '407',
        '80v08': '719',
        '肥猫压制': '732',
        'Little字幕组': '680',
        'AI-Raws': '613',
        '离谱Sub': '806',
        '虹咲学园烤肉同好会': '812',
        'ARIA吧汉化组': '636',
        '百冬練習組': '821',
        '柯南事务所': '75',
        '冷番补完字幕组': '641',
        '極彩字幕组': '822',
        '爱咕字幕组': '765',
        'AQUA工作室': '217',
        '未央阁联盟': '592',
        '届恋字幕组': '703',
        '夜莺家族': '808',
        'TD-RAWS': '734',
        '夢幻戀櫻': '447',
        'WBX-SUB': '790',
        'Liella!の烧烤摊': '807',
        'Amor字幕组': '814',
        'MingYSub': '813',
        'Sakura': '832',
        'EMe': '817',
        'Alchemist': '818',
        '黑岩射手吧字幕组': '819',
        'ANi': '816',
      }),
  RSSProvider(
      name: 'Bangumi Moe',
      homePageUrl: 'https://bangumi.moe/',
      rssPath: 'rss',
      mainPagePath: 'rss/latest',
      searchParams: '/search/%q',
      logoPath: 'lite/img/logo-20150506.png',
      supportTitleGroup: true,
      authorNameTag: null,
      categoryTag: null,
      coverUrlGetter: descriptionCoverUrlGetter,
      supportAdvancedSearch: false,
      categoryRssMap: {
        '所有類別': null,
        '繁體': '/tags/548ee1204ab7379536f56357',
        '簡體': '/tags/548ee0ea4ab7379536f56354',
        '1080p': '/tags/548ee2ce4ab7379536f56358',
        '2160p (4K)': '/tags/5bd093cade4560f455f6967e',
        '動畫': '/tags/549ef207fe682f7549f1ea90',
        '電影': '/tags/549cc9369310bc7d04cddf9f',
        '漫畫': '/tags/549eefebfe682f7549f1ea8c',
        '遊戲': '/tags/549ef015fe682f7549f1ea8d',
        '音樂': '/tags/549eef6ffe682f7549f1ea8b',
        '其他': '/tags/549ef250fe682f7549f1ea91',
        '*此站不支援搜尋過濾': '',
      },
      authorRssMap: {
        '所有字幕组': null,
        '喵萌奶茶屋': '/tags/58a9c1e6f5dc363606ab42ed',
        '桜都字幕组': '/tags/57a034ee5cc0696f1ce1a1b2',
        '幻樱字幕组': '/tags/59af67e6d04829c1623b0e52',
        '星空字幕组': '/tags/5d23fecf306f1a0007b58066',
        '织梦字幕组': '/tags/6277e26b3d5c3100075614ff',
        '悠哈璃羽字幕社': '/tags/575446452165b9ba0c485d13',
        'c.c动漫': '/tags/57c38f7fee98e9ca2072f9b3',
        'NC-Raws': '/tags/600c009432f14c00073a9f49',
        'Lilith-Raws': '/tags/600c00a832f14c00073a9f4a',
        'LoliHouse': '/tags/581be821ee98e9ca20730eae',
        'KissSub': '/tags/553a02b7dd3d5c0b4e82f209',
        'DMG': '/tags/55c057b124180bc3647feb1d',
        'SweetSub': '/tags/5854a57da8e01b4f37915ff4',
        '*此站不支援搜尋過濾': '',
      }),
  RSSProvider(
      name: 'ACG.RIP',
      homePageUrl: 'https://acg.rip/',
      rssPath: '',
      mainPagePath: '.xml',
      searchParams: '%c.xml?term=%q',
      coverUrlGetter: descriptionCoverUrlGetter,
      supportTitleGroup: true,
      authorNameTag: null,
      categoryTag: null,
      categoryRssMap: {
        '所有類別': null,
        '動畫': '1',
        '日劇': '2',
        '綜藝': '3',
        '音樂': '4',
        '合集': '5',
        '其他': '6',
      }),
  RSSProvider(
      name: 'Nyaa',
      homePageUrl: 'https://nyaa.si/',
      rssPath: '?page=rss',
      searchParams: '&q=%q&c=%c&f=0',
      logoPath: 'static/favicon.png',
      magnetUrlGetter: linkMangerUrlGetter,
      coverUrlGetter: null,
      authorNameTag: null,
      categoryTag: 'nyaa:category',
      fileSizeTag: 'nyaa:size',
      categoryRssMap: {
        'All Catergories': '0_0',
        'Anime': '1_0',
        'Anime - Anime Music Video': '1_1',
        'Anime - English Translated': '1_2',
        'Anime - Non English Translated': '1_3',
        'Anime - Raw': '1_4',
        'Audio': '2_0',
        'Audio - Lossless': '2_1',
        'Audio - Lossy': '2_2',
        'Literature': '3_0',
        'Literature - English Translated': '3_1',
        'Literature - Non-English Translated': '3_2',
        'Literature - Raw': '3_3',
        'Live Action': '4_0',
        'Pictures': '5_0',
        'Software': '6_0',
        'Applications': '6_1',
        'Games': '6_2',
      }),
  RSSProvider(
      name: 'Sukebei Nyaa',
      homePageUrl: 'https://sukebei.nyaa.si/',
      rssPath: '?page=rss',
      searchParams: '&page=rss&q=%q&c=%c&f=0',
      logoPath: 'static/favicon.png',
      magnetUrlGetter: linkMangerUrlGetter,
      coverUrlGetter: null,
      authorNameTag: null,
      categoryTag: 'nyaa:category',
      fileSizeTag: 'nyaa:size',
      categoryRssMap: {
        'All Catergories': '0_0',
        'Art': '1_0',
        'Art - Anime': '1_1',
        'Art - Doujinshi': '1_2',
        'Art - Games': '1_3',
        'Art - Manga': '1_4',
        'Art - Pictures': '1_5',
        'Real Life': '2_0',
        'Real Life - Photobooks and Pictures': '2_1',
        'Real Life - Videos': '2_2',
      }),
  RSSHubProvider('U9A9', 'u9a9'),
  RSSHubProvider('U3C3', 'u3c3'),
];

final kProvidersDict = kRssProviders.fold<Map<String, RSSProvider>>(
    {}, (prev, element) => prev..[element.name] = element);

String? descriptionCoverUrlGetter(XmlElement e) {
  String? desc = e.findElements('description').first.innerText;
  return RegExp(r'<img src="(.+?)"').firstMatch(desc)?.group(1);
}

String? enclosureMangetUrlGetter(XmlElement e) =>
    e.findElements('enclosure').first.getAttribute('url');

String? linkMangerUrlGetter(XmlElement e) =>
    e.findElements('link').first.innerText;

typedef UrlParamGetter = String Function(String);

typedef XMLValueGetter = String? Function(XmlElement);

class RSSProvider {
  final String name;
  final String homePageUrl;
  final String logoPath;
  final String rssPath;
  final String? mainPagePath;
  final String searchParams;
  final String itemNameTag;
  final String? authorNameTag;
  final String pubDateTag;
  final String? categoryTag;
  final String? fileSizeTag;
  final String descriptionTag;
  final bool supportAdvancedSearch;
  final bool supportTitleGroup;
  final XMLValueGetter? magnetUrlGetter;
  final XMLValueGetter? coverUrlGetter;
  final Map<String, String?>? categoryRssMap;
  final Map<String, String?>? authorRssMap;

  const RSSProvider(
      {this.logoPath = '/favicon.ico',
      required this.name,
      required this.homePageUrl,
      required this.rssPath,
      required this.searchParams,
      this.mainPagePath,
      this.categoryRssMap,
      this.authorRssMap,
      this.magnetUrlGetter = enclosureMangetUrlGetter,
      this.coverUrlGetter = descriptionCoverUrlGetter,
      this.fileSizeTag,
      this.supportAdvancedSearch = true,
      this.supportTitleGroup = false,
      this.itemNameTag = 'title',
      this.authorNameTag = 'author',
      this.pubDateTag = 'pubDate',
      this.categoryTag = 'category',
      this.descriptionTag = 'description'});
  String get logoUrl => homePageUrl + logoPath;

  String get rssUrl => homePageUrl + rssPath;

  String searchUrl({String? query, String? author, String? category}) {
    if (query != null && query.isEmpty) {
      query = null;
    }

    if (query == null) {
      if (!supportAdvancedSearch) {
        if (author != null) {
          return homePageUrl + rssPath + author;
        }
        if (category != null) {
          return homePageUrl + rssPath + category;
        }
      }
      if (author == null && category == null) {
        return homePageUrl + (mainPagePath ?? rssPath);
      }
      query = '';
    }
    return homePageUrl +
        rssPath +
        searchParams
            .replaceAll('%q', query)
            .replaceAll('%a', author ?? '')
            .replaceAll('%c', category ?? '');
  }
}

class RSSHubProvider extends RSSProvider {
  const RSSHubProvider(String name, String endPoint)
      : super(
            name: name,
            homePageUrl: 'https://rsshub.app/$endPoint',
            rssPath: '',
            searchParams: '/search/%q',
            coverUrlGetter: null,
            magnetUrlGetter: enclosureMangetUrlGetter,
            authorNameTag: null,
            categoryTag: null);
}
// TODO: open in browser
// TODO: group tags in a class
// TODO: group paths in a class