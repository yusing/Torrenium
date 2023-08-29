import 'package:flutter/cupertino.dart';

import 'adaptive.dart';

class PlayPauseButton extends AdaptiveIconButton {
  final VoidCallback play;
  final VoidCallback pause;
  final bool isPlaying;

  PlayPauseButton(
      {Key? key,
      double? iconSize,
      Color? color,
      required this.play,
      required this.pause,
      required this.isPlaying})
      : super(
          key: key,
          icon: AdaptiveIcon(
            isPlaying ? CupertinoIcons.pause : CupertinoIcons.play,
            size: iconSize,
            color: color,
          ),
          onPressed: isPlaying ? pause : play,
        );
}
