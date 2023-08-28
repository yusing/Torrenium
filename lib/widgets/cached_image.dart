import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/cupertino.dart';
import 'package:logger/logger.dart';
import 'package:macos_ui/macos_ui.dart';

import '/services/http.dart';
import '/style.dart';

class CachedImage extends CachedNetworkImage {
  CachedImage(
      {required String? url,
      Future<String?> Function()? fallbackGetter,
      double? width,
      double? height,
      BoxFit? fit,
      super.key})
      : super(
          alignment: Alignment.topCenter,
          imageUrl: url ?? '',
          fit: fit ?? BoxFit.cover,
          progressIndicatorBuilder: (context, url, progress) => ConstrainedBox(
            constraints: const BoxConstraints(
                minWidth: kListTileThumbnailWidth,
                minHeight: kListTileThumbnailMinHeight),
            child: Center(
              child: ProgressCircle(
                  value: progress.progress == null
                      ? null
                      : progress.progress! * 100),
            ),
          ),
          width: width,
          height: height,
          errorWidget: (context, url, error) => fallbackGetter == null
              ? const Icon(CupertinoIcons.exclamationmark_circle_fill)
              : FutureBuilder(
                  future: fallbackGetter(),
                  builder: (context, snapshot) {
                    if (snapshot.hasData) {
                      // Logger().i(snapshot.data);
                      return CachedImage(
                          url: snapshot.data,
                          width: width,
                          height: height,
                          fit: fit);
                    }
                    if (snapshot.hasError) {
                      Logger().e('error', snapshot.error, snapshot.stackTrace);
                    }
                    return ConstrainedBox(
                        constraints: const BoxConstraints(
                            minWidth: kListTileThumbnailWidth,
                            minHeight: kListTileThumbnailMinHeight),
                        child: const Center(child: ProgressCircle()));
                  }),
          useOldImageOnUrlChange: false,
          cacheManager: gCacheManager,
        );
}
