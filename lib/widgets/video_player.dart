import 'dart:async';
import 'dart:math';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart'
    show Colors, Icons, ListTile, showModalBottomSheet;
import 'package:flutter/services.dart';
import 'package:flutter_vlc_player/flutter_vlc_player.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

import '../classes/torrent.dart';
import '../services/watch_history.dart';
import '../utils/string.dart';
import '../utils/units.dart';
import 'af_dropdown.dart';
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
    Navigator.pop(context);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
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
                  color: Colors.black,
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
          color: Colors.black.withOpacity(0.5),
          margin: const EdgeInsets.all(0),
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CupertinoButton(
                      onPressed: back,
                      child:
                          const Icon(CupertinoIcons.back, color: Colors.white)),
                  Expanded(child: Text(torrent.displayName)),
                  CupertinoButton(
                    onPressed: () => _showOptions(),
                    child: const Icon(CupertinoIcons.info_circle_fill,
                        color: Colors.white),
                  )
                ],
              ),
              SizedBox(
                width: 400,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    CupertinoButton(
                      onPressed: () async {
                        await _vlcController.seekTo(
                            await _vlcController.getPosition() -
                                const Duration(seconds: 5));
                      },
                      child: const Icon(
                        FontAwesomeIcons.backward,
                        size: 32,
                        color: Colors.white,
                      ),
                    ),
                    ValueListenableBuilder(
                      valueListenable: _vlcController,
                      builder: (_, __, ___) => PlayPauseButton(
                          iconSize: 32,
                          color: Colors.white,
                          play: _vlcController.play,
                          pause: _vlcController.pause,
                          isPlaying: _vlcController.value.isPlaying),
                    ),
                    CupertinoButton(
                      child: const Icon(FontAwesomeIcons.forward,
                          size: 32, color: Colors.white),
                      onPressed: () async {
                        await _vlcController.seekTo(
                            await _vlcController.getPosition() +
                                const Duration(seconds: 5));
                      },
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
                      onChanged: (vNew) => _vlcController
                          .seekTo(Duration(seconds: vNew.toInt())),
                      min: 0.0,
                      max: max(
                          1.0, // maybe uninitialized
                          v.duration.inSeconds
                              .toDouble()), // _durationSecs.value may load after _positionSecs.value
                      activeColor: Colors.white,
                      thumbColor: Colors.white.withOpacity(0.3),
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

  void _showOptions() {
    if (_overlay.mounted) {
      _overlay.remove();
    }
    showModalBottomSheet(
        context: context,
        useRootNavigator: true,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(top: Radius.circular(8))),
        builder: (_) => Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                    leading: const Icon(Icons.speed_outlined),
                    title: const Text('Playback Speed'),
                    trailing: AFDropdown<double>(
                        itemsMap: Map.fromIterable(
                            List.generate(8, (i) => (i + 1) * 0.25,
                                growable: false),
                            value: (v) => '${v.toStringAsFixed(2)}x'),
                        valueGetter: () => _playbackSpeed,
                        onChanged: (speed) async {
                          _playbackSpeed = speed!;
                          await _vlcController.setPlaybackSpeed(_playbackSpeed);
                        })),
                ListTile(
                    leading: const Icon(Icons.audiotrack_outlined),
                    title: const Text('Audio Track'),
                    trailing: FutureBuilder<Map<int, String>>(
                        future: _vlcController.getAudioTracks(),
                        builder: (_, snapshot) => snapshot.data == null
                            ? const SizedBox()
                            : AFDropdown<int>(
                                valueGetter: () =>
                                    _activeAudioTrack ??
                                    _vlcController.value.activeAudioTrack,
                                itemsMap: snapshot.data!,
                                onChanged: (value) async {
                                  _activeAudioTrack = value!;
                                  await _vlcController.setAudioTrack(value);
                                },
                              ))),
                ListTile(
                    leading: const Icon(Icons.subtitles_outlined),
                    title: const Text('Subtitle'),
                    trailing: FutureBuilder<Map<int, String>>(
                        future: _vlcController.getSpuTracks(),
                        builder: (_, snapshot) => snapshot.data == null
                            ? const SizedBox()
                            : AFDropdown<int>(
                                valueGetter: () =>
                                    _activeSubtitleTrack ??
                                    _vlcController.value.activeSpuTrack,
                                itemsMap: snapshot.data!,
                                onChanged: (value) async {
                                  _activeSubtitleTrack = value!;
                                  await _vlcController.setSpuTrack(value);
                                },
                              )))
              ],
            ));
  }
}
