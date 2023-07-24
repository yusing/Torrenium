import 'package:xml/xml.dart';

typedef XMLValueGetter = String? Function(XmlElement);
typedef UrlParamGetter = String Function(String);

String? defaultMangetUrlGetter(XmlElement e) =>
    e.findElements('enclosure').first.getAttribute('url');

String? defaultCoverUrlGetter(XmlElement e) {
  String? desc = e.findElements('description').first.innerText;
  // final imgStart = desc.indexOf('<img src="');
  // return imgStart == -1
  //     ? null
  //     : desc.substring(imgStart + 10, desc.indexOf('"', imgStart + 10));
  return RegExp(r'<img src="(.+?)"').firstMatch(desc)?.group(1);
}

class RSSProvider {
  final String name;
  final String homePageUrl;
  final String logoPath;
  final String rssPath;
  final String searchRssPath;
  final String itemNameTag;
  final String? authorNameTag;
  final String pubDateTag;
  final String? categoryTag;
  final String? fileSizeTag;
  final String descriptionTag;
  final XMLValueGetter? magnetUrlGetter;
  final XMLValueGetter? torrentUrlGetter;
  final XMLValueGetter? coverUrlGetter;
  final UrlParamGetter? authorParamGetter;
  final UrlParamGetter? categoryParamGetter;
  final Map<String, String>? categoryRssMap;
  final Map<String, String>? authorRssMap;

  String get rssUrl => homePageUrl + rssPath;
  String get logoUrl => homePageUrl + logoPath;
  String searchUrl(String? keyword, String? category, String? author) =>
      homePageUrl +
      (keyword == null || keyword.isEmpty
          ? rssPath
          : (searchRssPath
              .replaceAll('%q', keyword)
              .replaceAll(
                  '%c',
                  category == null
                      ? ''
                      : categoryParamGetter?.call(categoryRssMap![category]!) ??
                          '')
              .replaceAll(
                  '%a',
                  author == null
                      ? ''
                      : authorParamGetter?.call(authorRssMap![author]!) ??
                          '')));

  RSSProvider(
      {this.logoPath = '/favicon.ico',
      required this.name,
      required this.homePageUrl,
      required this.rssPath,
      required this.searchRssPath,
      this.categoryRssMap,
      this.authorRssMap,
      this.magnetUrlGetter,
      this.coverUrlGetter,
      this.torrentUrlGetter,
      this.authorParamGetter,
      this.categoryParamGetter,
      this.fileSizeTag,
      this.itemNameTag = 'title',
      this.authorNameTag = 'author',
      this.pubDateTag = 'pubDate',
      this.categoryTag = 'category',
      this.descriptionTag = 'description'});
}

// TODO: allow adding custom provider
final List<RSSProvider> rssProviders = [
  RSSProvider(
      name: '動漫花園',
      homePageUrl: 'https://share.dmhy.org/',
      rssPath: 'topics/rss/rss.xml',
      searchRssPath:
          'topics/rss/rss.xml?keyword=%q&sort_id=%c&team_id=%a&order=date-desc',
      logoPath: 'images/sitelogo.gif',
      coverUrlGetter: defaultCoverUrlGetter,
      magnetUrlGetter: defaultMangetUrlGetter,
      categoryParamGetter: (path) => path.split('/')[3],
      authorParamGetter: (path) => path.split('/')[3],
      categoryRssMap: {
        '所有類別': 'topics/rss/sort_id/0/rss.xml',
        '動畫': 'topics/rss/sort_id/2/rss.xml',
        '漫畫': 'topics/rss/sort_id/3/rss.xml',
        '音樂': 'topics/rss/sort_id/4/rss.xml',
        '遊戲': 'topics/rss/sort_id/9/rss.xml',
        '日劇': 'topics/rss/sort_id/6/rss.xml',
        'RAW': 'topics/rss/sort_id/7/rss.xml',
        '特攝': 'topics/rss/sort_id/12/rss.xml',
        '其他': 'topics/rss/sort_id/1/rss.xml',
      },
      authorRssMap: {
        '所有字幕組': 'topics/rss/team_id/0/rss.xml',
        '拨雪寻春': 'topics/rss/team_id/823/rss.xml',
        '動漫花園': 'topics/rss/team_id/117/rss.xml',
        'NC-Raws': 'topics/rss/team_id/801/rss.xml',
        '喵萌奶茶屋': 'topics/rss/team_id/669/rss.xml',
        'Lilith-Raws': 'topics/rss/team_id/803/rss.xml',
        '魔星字幕团': 'topics/rss/team_id/648/rss.xml',
        '桜都字幕组': 'topics/rss/team_id/619/rss.xml',
        '天月動漫&amp;發佈組': 'topics/rss/team_id/767/rss.xml',
        '极影字幕社': 'topics/rss/team_id/185/rss.xml',
        'LoliHouse': 'topics/rss/team_id/657/rss.xml',
        '悠哈C9字幕社': 'topics/rss/team_id/151/rss.xml',
        '幻月字幕组': 'topics/rss/team_id/749/rss.xml',
        '天使动漫论坛': 'topics/rss/team_id/390/rss.xml',
        '动漫国字幕组': 'topics/rss/team_id/303/rss.xml',
        '幻樱字幕组': 'topics/rss/team_id/241/rss.xml',
        '爱恋字幕社': 'topics/rss/team_id/47/rss.xml',
        'DBD制作组': 'topics/rss/team_id/805/rss.xml',
        'c.c动漫': 'topics/rss/team_id/604/rss.xml',
        '萝莉社活动室': 'topics/rss/team_id/550/rss.xml',
        '千夏字幕组': 'topics/rss/team_id/283/rss.xml',
        'IET字幕組': 'topics/rss/team_id/772/rss.xml',
        '诸神kamigami字幕组': 'topics/rss/team_id/288/rss.xml',
        '霜庭云花Sub': 'topics/rss/team_id/804/rss.xml',
        'GMTeam': 'topics/rss/team_id/755/rss.xml',
        '风车字幕组': 'topics/rss/team_id/454/rss.xml',
        '雪飄工作室(FLsnow)': 'topics/rss/team_id/37/rss.xml',
        'MCE汉化组': 'topics/rss/team_id/764/rss.xml',
        '丸子家族': 'topics/rss/team_id/488/rss.xml',
        '星空字幕组': 'topics/rss/team_id/731/rss.xml',
        '梦蓝字幕组': 'topics/rss/team_id/574/rss.xml',
        'LoveEcho!': 'topics/rss/team_id/504/rss.xml',
        'SweetSub': 'topics/rss/team_id/650/rss.xml',
        '枫叶字幕组': 'topics/rss/team_id/630/rss.xml',
        'Little Subbers!': 'topics/rss/team_id/479/rss.xml',
        '轻之国度': 'topics/rss/team_id/321/rss.xml',
        '云光字幕组': 'topics/rss/team_id/649/rss.xml',
        '豌豆字幕组': 'topics/rss/team_id/520/rss.xml',
        '驯兽师联盟': 'topics/rss/team_id/626/rss.xml',
        '中肯字幕組': 'topics/rss/team_id/666/rss.xml',
        'SW字幕组': 'topics/rss/team_id/781/rss.xml',
        '银色子弹字幕组': 'topics/rss/team_id/576/rss.xml',
        '风之圣殿': 'topics/rss/team_id/434/rss.xml',
        'YWCN字幕组': 'topics/rss/team_id/665/rss.xml',
        'KRL字幕组': 'topics/rss/team_id/228/rss.xml',
        '华盟字幕社': 'topics/rss/team_id/49/rss.xml',
        '波洛咖啡厅': 'topics/rss/team_id/627/rss.xml',
        '动音漫影': 'topics/rss/team_id/88/rss.xml',
        'VCB-Studio': 'topics/rss/team_id/581/rss.xml',
        'DHR動研字幕組': 'topics/rss/team_id/407/rss.xml',
        '80v08': 'topics/rss/team_id/719/rss.xml',
        '肥猫压制': 'topics/rss/team_id/732/rss.xml',
        'Little字幕组': 'topics/rss/team_id/680/rss.xml',
        'AI-Raws': 'topics/rss/team_id/613/rss.xml',
        '离谱Sub': 'topics/rss/team_id/806/rss.xml',
        '虹咲学园烤肉同好会': 'topics/rss/team_id/812/rss.xml',
        'ARIA吧汉化组': 'topics/rss/team_id/636/rss.xml',
        '百冬練習組': 'topics/rss/team_id/821/rss.xml',
        '柯南事务所': 'topics/rss/team_id/75/rss.xml',
        '冷番补完字幕组': 'topics/rss/team_id/641/rss.xml',
        '極彩字幕组': 'topics/rss/team_id/822/rss.xml',
        '爱咕字幕组': 'topics/rss/team_id/765/rss.xml',
        'AQUA工作室': 'topics/rss/team_id/217/rss.xml',
        '未央阁联盟': 'topics/rss/team_id/592/rss.xml',
        '届恋字幕组': 'topics/rss/team_id/703/rss.xml',
        '夜莺家族': 'topics/rss/team_id/808/rss.xml',
        'TD-RAWS': 'topics/rss/team_id/734/rss.xml',
        '夢幻戀櫻': 'topics/rss/team_id/447/rss.xml',
        'WBX-SUB': 'topics/rss/team_id/790/rss.xml',
        'Liella!の烧烤摊': 'topics/rss/team_id/807/rss.xml',
        'Amor字幕组': 'topics/rss/team_id/814/rss.xml',
        'MingYSub': 'topics/rss/team_id/813/rss.xml',
        'Sakura': 'topics/rss/team_id/832/rss.xml',
        'EMe': 'topics/rss/team_id/817/rss.xml',
        'Alchemist': 'topics/rss/team_id/818/rss.xml',
        '黑岩射手吧字幕组': 'topics/rss/team_id/819/rss.xml',
        'ANi': 'topics/rss/team_id/816/rss.xml',
      }),
  RSSProvider(
      name: 'Bangumi Moe',
      homePageUrl: 'https://bangumi.moe/',
      rssPath: 'rss/latest',
      searchRssPath: 'rss/search/%q',
      logoPath: 'lite/img/logo-20150506.png',
      authorNameTag: null,
      categoryTag: null,
      coverUrlGetter: defaultCoverUrlGetter,
      torrentUrlGetter: defaultMangetUrlGetter,
      categoryRssMap: {
        '所有類別': 'rss/latest',
        '繁體': 'rss/tags/548ee1204ab7379536f56357',
        '簡體': 'rss/tags/548ee0ea4ab7379536f56354',
        '1080p': 'rss/tags/548ee2ce4ab7379536f56358',
        '2160p (4K)': 'rss/tags/5bd093cade4560f455f6967e',
        '動畫': 'rss/tags/549ef207fe682f7549f1ea90',
        '電影': 'rss/tags/549cc9369310bc7d04cddf9f',
        '漫畫': 'rss/tags/549eefebfe682f7549f1ea8c',
        '遊戲': 'rss/tags/549ef015fe682f7549f1ea8d',
        '音樂': 'rss/tags/549eef6ffe682f7549f1ea8b',
        '其他': 'rss/tags/549ef250fe682f7549f1ea91',
        '*此站不支援搜尋過濾': 'rss/latest',
      },
      authorRssMap: {
        '所有字幕组': 'rss/latest',
        '喵萌奶茶屋': 'rss/tags/58a9c1e6f5dc363606ab42ed',
        '桜都字幕组': 'rss/tags/57a034ee5cc0696f1ce1a1b2',
        '幻樱字幕组': 'rss/tags/59af67e6d04829c1623b0e52',
        '星空字幕组': 'rss/tags/5d23fecf306f1a0007b58066',
        '织梦字幕组': 'rss/tags/6277e26b3d5c3100075614ff',
        '悠哈璃羽字幕社': 'rss/tags/575446452165b9ba0c485d13',
        'c.c动漫': 'rss/tags/57c38f7fee98e9ca2072f9b3',
        'NC-Raws': 'rss/tags/600c009432f14c00073a9f49',
        'Lilith-Raws': 'rss/tags/600c00a832f14c00073a9f4a',
        'LoliHouse': 'rss/tags/581be821ee98e9ca20730eae',
        'KissSub': 'rss/tags/553a02b7dd3d5c0b4e82f209',
        'DMG': 'rss/tags/55c057b124180bc3647feb1d',
        'SweetSub': 'rss/tags/5854a57da8e01b4f37915ff4',
        '*此站不支援搜尋過濾': 'rss/latest',
      }),
  RSSProvider(
      name: 'ACG.RIP',
      homePageUrl: 'https://acg.rip/',
      rssPath: '.xml',
      searchRssPath: '%c.xml?term=%q',
      coverUrlGetter: defaultCoverUrlGetter,
      torrentUrlGetter: defaultMangetUrlGetter,
      authorNameTag: null,
      categoryTag: null,
      categoryParamGetter: (e) => e.split('.')[0],
      categoryRssMap: {
        '所有類別': '.xml',
        '動畫': '1.xml',
        '日劇': '2.xml',
        '綜藝': '3.xml',
        '音樂': '4.xml',
        '合集': '5.xml',
        '其他': '6.xml',
      }),
  RSSProvider(
      name: 'Nyaa',
      homePageUrl: 'https://nyaa.si/',
      rssPath: '?page=rss',
      searchRssPath: '?page=rss&q=%q&c=%c&f=0',
      logoPath: 'static/favicon.png',
      torrentUrlGetter: (e) => e.findElements('link').first.innerText,
      coverUrlGetter: null,
      authorNameTag: null,
      categoryTag: 'nyaa:category',
      fileSizeTag: 'nyaa:size',
      categoryParamGetter: (e) => e.substring(15, 18),
      categoryRssMap: {
        'All Catergories': '?page=rss&q=&c=0_0&f=0',
        'Anime': '?page=rss&q=&c=1_0&f=0',
        'Anime - Anime Music Video': '?page=rss&q=&c=1_1&f=0',
        'Anime - English Translated': '?page=rss&q=&c=1_2&f=0',
        'Anime - Non English Translated': '?page=rss&q=&c=1_3&f=0',
        'Anime - Raw': '?page=rss&q=&c=1_4&f=0',
        'Audio': '?page=rss&q=&c=2_0&f=0',
        'Audio - Lossless': '?page=rss&q=&c=2_1&f=0',
        'Audio - Lossy': '?page=rss&q=&c=2_2&f=0',
        'Literature': '?page=rss&q=&c=3_0&f=0',
        'Literature - English Translated': '?page=rss&q=&c=3_1&f=0',
        'Literature - Non-English Translated': '?page=rss&q=&c=3_2&f=0',
        'Literature - Raw': '?page=rss&q=&c=3_3&f=0',
        'Live Action': '?page=rss&q=&c=4_0&f=0',
        'Pictures': '?page=rss&q=&c=5_0&f=0',
        'Software': '?page=rss&q=&c=6_0&f=0',
        'Applications': '?page=rss&q=&c=6_1&f=0',
        'Games': '?page=rss&q=&c=6_2&f=0',
      }),
  RSSProvider(
      name: 'Sukebei Nyaa',
      homePageUrl: 'https://sukebei.nyaa.si/',
      rssPath: '?page=rss',
      searchRssPath: '?page=rss&q=%q&c=%c&f=0',
      logoPath: 'static/favicon.png',
      torrentUrlGetter: (e) => e.findElements('link').first.innerText,
      coverUrlGetter: null,
      authorNameTag: null,
      categoryTag: 'nyaa:category',
      fileSizeTag: 'nyaa:size',
      categoryParamGetter: (e) => e.substring(15, 18),
      categoryRssMap: {
        'All Catergories': '?page=rss&q=&c=0_0&f=0',
        'Art': '?page=rss&q=&c=1_0&f=0',
        'Art - Anime': '?page=rss&q=&c=1_1&f=0',
        'Art - Doujinshi': '?page=rss&q=&c=1_2&f=0',
        'Art - Games': '?page=rss&q=&c=1_3&f=0',
        'Art - Manga': '?page=rss&q=&c=1_4&f=0',
        'Art - Pictures': '?page=rss&q=&c=1_5&f=0',
        'Real Life': '?page=rss&q=&c=2_0&f=0',
        'Real Life - Photobooks and Pictures': '?page=rss&q=&c=2_1&f=0',
        'Real Life - Videos': '?page=rss&q=&c=2_2&f=0',
      })
];
