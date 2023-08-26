import '/interface/groupable.dart';
import '/services/torrent_mgr.dart';
import '../services/storage.dart';

class Item extends Groupable {
  final String description;
  final String? torrentUrl;
  final DateTime? pubDate;
  final String? category, author;
  final String? size;
  final int? viewCount, likeCount;

  Item(
      {String? coverUrl,
      required super.name,
      required this.description,
      required this.torrentUrl,
      required this.pubDate,
      this.category,
      this.author,
      this.size,
      this.viewCount,
      this.likeCount}) {
    if (coverUrl != null) {
      Storage.setStringIfNotExists('cover-$nameHash', coverUrl);
    }
  }

  Future<void> startDownload() async {
    await gTorrentManager.downloadItem(this);
  }
}
