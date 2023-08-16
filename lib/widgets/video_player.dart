import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart' show Icons;
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

import '../classes/download_item.dart';
import '../services/watch_history.dart';
import '../utils/units.dart';
import 'cupertino_picker_button.dart';
import 'dynamic.dart';
import 'play_pause_button.dart';

class VideoPlayerPage extends StatefulWidget {
  final DownloadItem item;

  const VideoPlayerPage(this.item, {super.key});

  @override
  State<VideoPlayerPage> createState() => _VideoPlayerPageState();
}

class _VideoPlayerPageState extends State<VideoPlayerPage> {
  late VlcPlayerController _vlcController;
  double _playbackSpeed = 1.0;
  late OverlayEntry _overlay;

  DownloadItem get item => widget.item;

  void addToHistory() {
    WatchHistory.add(WatchHistoryEntry(
        title: item.displayName,
        nameHash: item.nameHash,
        duration: _vlcController.value.duration.inSeconds,
        position: _vlcController.value.position.inSeconds));
  }

  void back() {
    if (_overlay.mounted) {
      _overlay.remove();
    }
    item.updateWatchPosition(_vlcController.value.position);
    WatchHistory.notifier.notifyListeners();

    if (item.watchProgress >= .85) {
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
                          item.delete();
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
    return WillPopScope(
      onWillPop: () async {
        await SystemChrome.restoreSystemUIOverlays();
        await SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
        await SystemChrome.setPreferredOrientations(
            [DeviceOrientation.portraitUp]);
        WakelockPlus.disable();
        return true;
      },
      child: CupertinoPageScaffold(
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
      ),
    );
  }

  @override
  void dispose() {
    if (_overlay.mounted) {
      _overlay.remove();
    }
    _overlay.dispose();
    _vlcController.stop().then((value) => _vlcController.dispose());
    super.dispose();
  }

  @override
  void initState() {
    _overlay = overlay();
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeRight,
      DeviceOrientation.landscapeLeft,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
    WakelockPlus.enable();
    _vlcController = VlcPlayerController.file(File(item.fullPath),
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

  OverlayEntry overlay() {
    return OverlayEntry(
      opaque: false,
      builder: (context) => GestureDetector(
        onTap: () => _overlay.remove(),
        child: Container(
          color: CupertinoColors.black.withOpacity(0.5),
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    CupertinoButton(
                        onPressed: back,
                        child: const Icon(CupertinoIcons.back,
                            color: CupertinoColors.white)),
                    Expanded(
                        child: Text(
                      item.displayName,
                      style: const TextStyle(
                          fontSize: 16, fontWeight: FontWeight.w500),
                    )),
                    CupertinoButton(
                      onPressed: _showOptions,
                      child: const Icon(FontAwesomeIcons.sliders,
                          color: CupertinoColors.white),
                    )
                  ],
                ),
                SizedBox(
                  width: 400,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                              style:
                                  TextStyle(color: CupertinoColors.systemGrey))
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
                              style:
                                  TextStyle(color: CupertinoColors.systemGrey))
                        ],
                      ),
                    ],
                  ),
                ),
                Row(
                  children: [
                    ValueListenableBuilder(
                      valueListenable: _vlcController,
                      builder: (_, v, ___) => Text.rich(TextSpan(
                          text: v.position.toStringNoMs(),
                          style: const TextStyle(
                              fontSize: 14, fontWeight: FontWeight.w500),
                          children: [
                            TextSpan(
                                text: ' / ${v.duration.toStringNoMs()}',
                                style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w500,
                                    color:
                                        CupertinoColors.white.withOpacity(.8)))
                          ])),
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
      ),
    );
  }

  Future<void> _onVlcInit() async {
    if (_vlcController.value.duration != Duration.zero) {
      if (item.watchProgress > 0) {
        await _vlcController.seekTo(item.lastPosition);
      }
      addToHistory();
    }

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
        // shape: const RoundedRectangleBorder(
        //     borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
        builder: (_) => Container(
              padding: const EdgeInsets.only(top: 6.0),
              margin: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
              ),
              color: CupertinoColors.systemBackground.resolveFrom(context),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DynamicListTile(
                      leading: const Icon(Icons.speed_outlined),
                      title: const Text('Playback Speed'),
                      trailing: [
                        CupertinoPickerButton(
                            valueGetter: () => _playbackSpeed,
                            items: List.generate(8, (i) => (i + 1) * 0.25,
                                growable: false),
                            itemBuilder: (v) =>
                                Text('${v.toStringAsFixed(2)}x'),
                            onSelectedItemChanged: (i) =>
                                _playbackSpeed = (i + 1) * 0.25,
                            onPop: (speed) async {
                              _playbackSpeed = speed;
                              await _vlcController.setPlaybackSpeed(speed);
                            })
                      ]),
                  DynamicListTile(
                      leading: const Icon(Icons.audiotrack_outlined),
                      title: const Text('Audio Track'),
                      trailing: [
                        FutureBuilder(
                            future: _vlcController.getAudioTracks(),
                            builder: (_, snapshot) => snapshot.data == null
                                ? const SizedBox()
                                : CupertinoPickerButton(
                                    valueGetter: () =>
                                        _vlcController.value.activeAudioTrack,
                                    items: snapshot.data!.keys,
                                    itemBuilder: (i) =>
                                        Text(snapshot.data![i]!),
                                    onPop: (value) =>
                                        _vlcController.setAudioTrack(value),
                                    onEmpty: const Padding(
                                      padding: EdgeInsets.only(right: 16.0),
                                      child: Text('N/A',
                                          style: TextStyle(
                                              color:
                                                  CupertinoColors.systemGrey)),
                                    ),
                                  ))
                      ]),
                  DynamicListTile(
                      leading: const Icon(Icons.subtitles_outlined),
                      title: const Text('Subtitle'),
                      trailing: [
                        FutureBuilder(
                            future: _vlcController.getSpuTracks(),
                            builder: (_, snapshot) => snapshot.data == null
                                ? const SizedBox()
                                : CupertinoPickerButton(
                                    valueGetter: () =>
                                        _vlcController.value.activeSpuTrack,
                                    items: snapshot.data!.keys,
                                    itemBuilder: (i) =>
                                        Text(snapshot.data![i]!),
                                    onPop: (value) =>
                                        _vlcController.setSpuTrack(value),
                                    onEmpty: const Padding(
                                      padding: EdgeInsets.only(right: 16.0),
                                      child: Text('N/A',
                                          style: TextStyle(
                                              color:
                                                  CupertinoColors.systemGrey)),
                                    )))
                      ])
                ],
              ),
            ));
  }
}
