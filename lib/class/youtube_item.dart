import 'package:youtube_explode_dart/youtube_explode_dart.dart';

import '/interface/download_item.dart';
import '/services/youtube.dart';
import 'item.dart';

class YouTubeItem extends DownloadItem {
  final String videoID;
  late final String videoUrl; //, audioUrl;

  // late final Map<String, String> subtitlePaths;
  late final String? error;

  YouTubeItem(Item item)
      : videoID = item.torrentUrl!.split('=').last,
        super(name: item.name, bytesDownloaded: 0, progress: 0) {
    coverUrl = item.coverUrl;
  }

  @override
  String get displayName => name;

  @override
  // String get audioTrackPath => audioUrl;

  @override
  // Map<String, String> get externalSubtitlePaths => subtitlePaths;

  @override
  String get videoPath => videoUrl;

  @override
  void delete() {}

  Future<YouTubeItem> init() async {
    final manifest = await YouTube.client.videos.streams.getManifest(videoID);
    videoUrl = manifest.muxed.withHighestBitrate().url.toString();
    // audioUrl = manifest.audioOnly.withHighestBitrate().url.toString();
    return this;
  }
}
