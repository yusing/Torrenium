import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:macos_ui/macos_ui.dart';
import 'package:torrenium/classes/item.dart';

class CachedImage extends CachedNetworkImage {
  CachedImage(
      {required String url,
      double? width,
      double? height,
      BoxFit? fit,
      super.key})
      : super(
          alignment: Alignment.topCenter,
          imageUrl: url,
          fit: fit ?? BoxFit.cover,
          placeholder: (context, url) => const Center(
            child: ProgressCircle(),
          ),
          width: width,
          height: height,
          errorWidget: (context, url, error) => const Icon(Icons.error),
          useOldImageOnUrlChange: true,
          cacheManager: TorreniumCacheManager(),
        );
}
