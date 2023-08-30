import '/interface/groupable.dart';
import '/services/rss_providers.dart';
import '/services/torrent_mgr.dart';

class RSSItem extends Groupable {
  final RSSProvider source;
  final String description;
  final String? torrentUrl;
  final DateTime? pubDate;
  final String? category, author, size;
  final int? viewCount, likeCount;

  RSSItem(
      {String? coverUrl,
      required super.name,
      required this.source,
      required this.description,
      required this.torrentUrl,
      required this.pubDate,
      this.category,
      this.author,
      this.size,
      this.viewCount,
      this.likeCount}) {
    if (coverUrl != null) {
      this.coverUrl = coverUrl;
    }
  }

  Future<void> startDownload() async {
    await gTorrentManager.downloadItem(this);
  }
}
