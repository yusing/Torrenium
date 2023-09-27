import '/interface/groupable.dart';
import '/services/rss_providers.dart';

abstract class RSSItem extends Groupable {
  final RSSProvider source;
  final String description;
  final Object pubDate;
  final String? category, author;
  final int? viewCount, likeCount;
  final String? size;

  RSSItem(
      {required String? coverUrl,
      required super.name,
      required this.source,
      required this.description,
      required this.pubDate,
      required this.category,
      required this.author,
      required this.size,
      required this.viewCount,
      required this.likeCount}) {
    if (coverUrl != null) {
      this.coverUrl = coverUrl;
    }
  }

  String get displayName => super.name;
}
