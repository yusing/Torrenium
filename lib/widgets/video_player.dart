import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Icons, Material, showModalBottomSheet;
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:logger/logger.dart';
import 'package:torrenium/services/error_reporter.dart';

import '../classes/torrent.dart';
import '../services/torrent.dart';
import '../services/watch_history.dart';
import '../utils/string.dart';
import '../utils/units.dart';
import 'cupertino_picker_button.dart';
import 'dynamic.dart';
import 'play_pause_button.dart';

class VideoPlayerPage extends StatefulWidget {
  final Torrent torrent;
  const VideoPlayerPage(this.torrent, {super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VlcPlayerController _vlcController;
  int? _activeAudioTrack;
  int? _activeSubtitleTrack;
  double _playbackSpeed = 1.0;
  late OverlayEntry _overlay;

  Torrent get torrent => widget.torrent;

  void addToHistory() {
    WatchHistory.add(WatchHistoryEntry(
        title: torrent.displayName,
        nameHash: torrent.nameHash,
        duration: _vlcController.value.duration.inSeconds,
        position: _vlcController.value.position.inSeconds));
  }

  void back() {
    _overlay.remove();
    _overlay.dispose();
    torrent.updateWatchPosition(_vlcController.value.position);
    torrent.stateNotifier.notifyListeners();
    _vlcController.stop().then((_) => _vlcController.dispose());
    // SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.restoreSystemUIOverlays().then((_) async {
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
      await SystemChrome.setPreferredOrientations(
          [DeviceOrientation.portraitUp]);
    });

    if (torrent.watchProgress >= .85) {
      showCupertinoDialog(
          context: context,
          builder: (_) => CupertinoAlertDialog(
                  title: const Text('Seems like finished watching'),
                  content: const Text('Delete?'),
                  actions: [
                    CupertinoDialogAction(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('No')),
                    CupertinoDialogAction(
                        onPressed: () {
                          gTorrentManager.deleteTorrent(torrent);
                          Navigator.pop(context);
                        },
                        child: const Text('Yes',
                            style: TextStyle(color: CupertinoColors.systemRed)))
                  ])).then(
          (value) => Navigator.pop(context)); // pop video player
    } else {
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return CupertinoPageScaffold(
      child: Stack(
        children: [
          SizedBox.expand(
            child: GestureDetector(onTap: () {
              if (!_overlay.mounted) {
                Overlay.of(context).insert(_overlay);
              }
            }),
          ),
          VlcPlayer(
              controller: _vlcController,
              aspectRatio: 16 / 9,
              virtualDisplay: false,
              placeholder: const ColoredBox(
                  color: CupertinoColors.black,
                  child: SizedBox.expand(
                      child: Center(child: CupertinoActivityIndicator())))),
        ],
      ),
    );
  }

  @override
  void initState() {
    _overlay = OverlayEntry(
      opaque: false,
      builder: (context) => GestureDetector(
        onTap: () => _overlay.remove(),
        child: Container(
          color: CupertinoColors.black.withOpacity(0.5),
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CupertinoButton(
                      onPressed: back,
                      child: const Icon(CupertinoIcons.back,
                          color: CupertinoColors.white)),
                  Expanded(child: Text(torrent.displayName)),
                  CupertinoButton(
                    onPressed: () => _showOptions().onError(
                        (error, stackTrace) =>
                            Logger().d('VideoOption', error, stackTrace)),
                    child: const Icon(FontAwesomeIcons.sliders,
                        color: CupertinoColors.white),
                  )
                ],
              ),
              SizedBox(
                width: 400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          onPressed: () => _vlcController.seekTo(
                              _vlcController.value.position -
                                  const Duration(seconds: 5)),
                          child: const Icon(
                            FontAwesomeIcons.backward,
                            size: 32,
                            color: CupertinoColors.white,
                          ),
                        ),
                        const Text('5',
                            style: TextStyle(color: CupertinoColors.systemGrey))
                      ],
                    ),
                    ValueListenableBuilder(
                      valueListenable: _vlcController,
                      builder: (_, __, ___) => PlayPauseButton(
                          iconSize: 32,
                          color: CupertinoColors.white,
                          play: _vlcController.play,
                          pause: _vlcController.pause,
                          isPlaying: _vlcController.value.isPlaying),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CupertinoButton(
                          child: const Icon(FontAwesomeIcons.forward,
                              size: 32, color: CupertinoColors.white),
                          onPressed: () => _vlcController.seekTo(
                              _vlcController.value.position +
                                  const Duration(seconds: 5)),
                        ),
                        const Text('5',
                            style: TextStyle(color: CupertinoColors.systemGrey))
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  ValueListenableBuilder(
                    valueListenable: _vlcController,
                    builder: (_, v, ___) =>
                        Text('${v.position.toStringNoMs()} / '
                            '${v.duration.toStringNoMs()}'),
                  ),
                  Expanded(
                      child: ValueListenableBuilder(
                    valueListenable: _vlcController,
                    builder: (_, v, ___) => CupertinoSlider(
                      value: v.position.inSeconds.toDouble(),
                      onChanged: (_) {},
                      onChangeEnd: (vNew) => _vlcController
                          .seekTo(Duration(seconds: vNew.toInt())),
                      min: 0.0,
                      max: max(
                          1.0, // maybe uninitialized
                          v.duration.inSeconds
                              .toDouble()), // _durationSecs.value may load after _positionSecs.value
                      activeColor: CupertinoColors.white,
                      thumbColor: CupertinoColors.systemRed,
                    ),
                  ))
                ],
              ),
            ],
          ),
        ),
      ),
    );
    _vlcController = VlcPlayerController.network(torrent.fullPath.encodeUrl(),
        autoPlay: true,
        options: VlcPlayerOptions(
            video: VlcVideoOptions([
          VlcVideoOptions.dropLateFrames(true),
          VlcVideoOptions.skipFrames(true)
        ])));
    _vlcController.addOnInitListener(_onVlcInit);
    _vlcController.addOnInitListener(() {
      Overlay.of(context).insert(_overlay);
    });
    super.initState();
  }

  Future<void> _onVlcInit() async {
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    Timer.periodic(const Duration(milliseconds: 100), (timer) async {
      if (_vlcController.value.duration != Duration.zero) {
        if (torrent.progress > 0) {
          await _vlcController.seekTo(torrent.lastPosition);
        }
        addToHistory();
        timer.cancel();
      }
    });

    _vlcController.addListener(() {
      if (_vlcController.value.isEnded) {
        back();
      }
    });
  }

  Future<void> _showOptions() async {
    if (_overlay.mounted) {
      _overlay.remove();
    }
    await showCupertinoModalPopup(
        context: context,
        useRootNavigator: true,
        // shape: const RoundedRectangleBorder(
        //     borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
        builder: (_) => CupertinoPageScaffold(
              child: SizedBox(
                height: 300,
                child: Column(
                  mainAxisSize: MainAxisSize.max,
                  children: [
                    Expanded(
                        child: ColoredBox(
                            color: CupertinoColors.black.withOpacity(.3))),
                    DynamicListTile(
                        leading: const Icon(Icons.speed_outlined),
                        title: const Text('Playback Speed'),
                        trailing: [
                          CupertinoPickerButton(
                              items: List.generate(8, (i) => (i + 1) * 0.25,
                                  growable: false),
                              itemBuilder: (v) =>
                                  Text('${v.toStringAsFixed(2)}x'),
                              value: _playbackSpeed,
                              onPop: (speed) async {
                                _playbackSpeed = speed;
                                await _vlcController
                                    .setPlaybackSpeed(_playbackSpeed);
                              })
                        ]),
                    DynamicListTile(
                        leading: const Icon(Icons.audiotrack_outlined),
                        title: const Text('Audio Track'),
                        trailing: [
                          FutureBuilder<Map<int, String>>(
                              future: _vlcController.getAudioTracks(),
                              builder: (_, snapshot) => snapshot.data == null
                                  ? const SizedBox()
                                  : CupertinoPickerButton(
                                      value:
                                          _vlcController.value.activeAudioTrack,
                                      items: snapshot.data!.keys,
                                      itemBuilder: (i) => Text(
                                          snapshot.data!.values.elementAt(i)),
                                      onPop: (value) async {
                                        await _vlcController
                                            .setAudioTrack(value);
                                      },
                                    ))
                        ]),
                    DynamicListTile(
                        leading: const Icon(Icons.subtitles_outlined),
                        title: const Text('Subtitle'),
                        trailing: [
                          FutureBuilder<Map<int, String>>(
                              future: _vlcController.getSpuTracks(),
                              builder: (_, snapshot) => snapshot.data == null
                                  ? const SizedBox()
                                  : CupertinoPickerButton(
                                      value:
                                          _vlcController.value.activeSpuTrack,
                                      items: snapshot.data!.keys,
                                      itemBuilder: (i) => Text(
                                          snapshot.data!.values.elementAt(i)),
                                      onPop: (value) async {
                                        await _vlcController.setSpuTrack(value);
                                      },
                                    ))
                        ])
                  ],
                ),
              ),
            ));
  }
}
