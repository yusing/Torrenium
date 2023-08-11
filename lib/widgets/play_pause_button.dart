import 'package:flutter/cupertino.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class PlayPauseButton extends CupertinoButton {
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
          child: FaIcon(
            isPlaying ? FontAwesomeIcons.pause : FontAwesomeIcons.play,
            size: iconSize,
            color: color,
          ),
          onPressed: isPlaying ? pause : play,
        );
}
