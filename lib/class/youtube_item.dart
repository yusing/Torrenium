import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '/interface/playable.dart';
import '/services/rss_providers.dart';
import 'rss_item.dart';

class YouTubeItem extends RSSItem with Playable {
  final String videoId;
  late final String videoUrl; //, audioUrl;
  // late final Map<String, String> subtitlePaths;

  YouTubeItem(
      {required super.name,
      required super.source,
      required super.description,
      required super.pubDate,
      required this.videoId,
      super.category,
      super.author,
      super.size,
      super.viewCount,
      super.likeCount,
      super.coverUrl});

  @override
  // String get audioTrackPath => audioUrl;

  @override
  // Map<String, String> get externalSubtitlePaths => subtitlePaths;

  @override
  String get fullPath => videoUrl;

  @override
  Future<void> showVideoPlayer() async {
    await _init();
    await super.showVideoPlayer();
  }

  Future<void> _init() async {
    final manifest =
        await YouTubeProvider.client.videos.streams.getManifest(videoId);
    videoUrl = manifest.muxed.withHighestBitrate().url.toString();
    // audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
  }
}
