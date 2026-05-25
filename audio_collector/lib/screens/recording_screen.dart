import 'dart:io';
import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:record/record.dart';
import '../providers/app_provider.dart';
import '../services/audio_service.dart';
import '../services/storage_service.dart';

class RecordingScreen extends StatefulWidget {
  final Directory threadDir;

  const RecordingScreen({super.key, required this.threadDir});

  @override
  State<RecordingScreen> createState() => _RecordingScreenState();
}

class _RecordingScreenState extends State<RecordingScreen> {
  late AudioService _audioService;

  bool _isRecording = false;
  bool _isPlaying = false;

  // Recording State
  Timer? _timer;
  int _recordDuration = 0;
  StreamSubscription<Amplitude>? _amplitudeSubscription;
  List<double> _amplitudes = List.filled(30, 0.0);

  // Playback State
  Duration _audioPosition = Duration.zero;
  Duration _audioDuration = Duration.zero;

  @override
  void initState() {
    super.initState();

    _audioService = AudioService();

    _audioService.playerStateStream.listen((state) {
      if (mounted) {
        setState(() => _isPlaying = state == PlayerState.playing);
      }
    });

    _audioService.positionStream.listen((pos) {
      if (mounted) {
        setState(() => _audioPosition = pos);
      }
    });

    _audioService.durationStream.listen((dur) {
      if (mounted) {
        setState(() => _audioDuration = dur);
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();
    _audioService.dispose();
    super.dispose();
  }

  Future<void> _handleRecordStart(int index) async {
    final path =
        StorageService.getExpectedAudioPath(widget.threadDir, index);

    await _audioService.startRecording(path);

    setState(() {
      _isRecording = true;
      _recordDuration = 0;
      _audioPosition = Duration.zero;
      _amplitudes = List.filled(30, 0.0);
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (Timer t) {
      if (mounted) {
        setState(() => _recordDuration++);
      }
    });

    _amplitudeSubscription =
        _audioService.amplitudeStream.listen((Amplitude amp) {
      if (mounted) {
        setState(() {
          double normalized = max(0.0, (amp.current + 50) / 50);

          _amplitudes.removeAt(0);
          _amplitudes.add(normalized);
        });
      }
    });
  }

  Future<void> _handleRecordStop(int index) async {
    _timer?.cancel();
    _amplitudeSubscription?.cancel();

    await _audioService.stopRecording();

    setState(() {
      _isRecording = false;
      _amplitudes = List.filled(30, 0.0);
    });

    final path =
        StorageService.getExpectedAudioPath(widget.threadDir, index);

    if (File(path).existsSync()) {
      await _audioService.setSource(path);

      setState(() => _audioPosition = Duration.zero);
    }
  }

  Future<void> _togglePlayback(int index) async {
    if (_isPlaying) {
      await _audioService.stopAudio();

      setState(() => _audioPosition = Duration.zero);
    } else {
      final path =
          StorageService.getExpectedAudioPath(widget.threadDir, index);

      if (File(path).existsSync()) {
        await _audioService.playAudio(path);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No recording found.'),
          ),
        );
      }
    }
  }

  String _formatTime(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, "0");

    String twoDigitMinutes =
        twoDigits(duration.inMinutes.remainder(60));

    String twoDigitSeconds =
        twoDigits(duration.inSeconds.remainder(60));

    return "$twoDigitMinutes:$twoDigitSeconds";
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AppProvider>(
      builder: (context, provider, child) {
        if (provider.sentences.isEmpty) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        }

        int index = provider.currentSentenceIndex;

        bool hasRecorded = File(
          StorageService.getExpectedAudioPath(
            widget.threadDir,
            index,
          ),
        ).existsSync();

        final screenWidth = MediaQuery.of(context).size.width;

        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Sentence ${index + 1} / ${provider.sentences.length}',
            ),
          ),

          body: Padding(
            padding: const EdgeInsets.all(20),

            child: Column(
              children: [

                // ===============================
                // LARGE RESPONSIVE TEXT AREA
                // ===============================

                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.45,

                  child: Center(
                    child: Container(
                      width: screenWidth * 0.90,

                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 30,
                      ),

                      decoration: BoxDecoration(
                        color: Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(22),

                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),

                      child: Column(
                        children: [

                          Expanded(
                            child: SingleChildScrollView(
                              physics:
                                  const BouncingScrollPhysics(),

                              child: Text(
                                provider.sentences[index],

                                textAlign: TextAlign.center,

                                style: TextStyle(
                                  fontSize:
                                      screenWidth < 600 ? 26 : 34,
                                  fontWeight: FontWeight.bold,
                                  height: 1.5,
                                  color: Colors.black87,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          const Text(
                            "💡 Tip: Scroll with one hand while holding the microphone button.",

                            textAlign: TextAlign.center,

                            style: TextStyle(
                              fontSize: 15,
                              color: Colors.black54,
                              fontStyle: FontStyle.italic,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 10),

                // ===============================
                // PLAYBACK BAR
                // ===============================

                SizedBox(
                  height: 60,

                  child: (hasRecorded && !_isRecording)
                      ? StreamBuilder<Duration>(
                          stream:
                              _audioService.positionStream,

                          builder: (context, snapshot) {
                            final position =
                                snapshot.data ??
                                    Duration.zero;

                            final currentMs = min(
                              position.inMilliseconds
                                  .toDouble(),
                              _audioDuration
                                  .inMilliseconds
                                  .toDouble(),
                            );

                            final maxMs =
                                _audioDuration
                                            .inMilliseconds >
                                        0
                                    ? _audioDuration
                                        .inMilliseconds
                                        .toDouble()
                                    : 1.0;

                            return Column(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              children: [
                                SliderTheme(
                                  data:
                                      SliderTheme.of(context)
                                          .copyWith(
                                    thumbShape:
                                        const RoundSliderThumbShape(
                                      enabledThumbRadius: 6,
                                    ),

                                    overlayShape:
                                        const RoundSliderOverlayShape(
                                      overlayRadius: 14,
                                    ),
                                  ),

                                  child: Slider(
                                    min: 0,
                                    max: maxMs,
                                    value: currentMs,
                                    onChanged: (value) {},
                                  ),
                                ),

                                Padding(
                                  padding:
                                      const EdgeInsets.symmetric(
                                    horizontal: 24,
                                  ),

                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .spaceBetween,

                                    children: [
                                      Text(
                                        _formatTime(position),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),

                                      Text(
                                        _formatTime(
                                            _audioDuration),
                                        style:
                                            const TextStyle(
                                          color:
                                              Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            );
                          },
                        )
                      : null,
                ),

                const SizedBox(height: 10),

                // ===============================
                // CONTROLS
                // ===============================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceEvenly,

                  children: [

                    // PLAY BUTTON

                    Opacity(
                      opacity:
                          hasRecorded && !_isRecording
                              ? 1.0
                              : 0.3,

                      child: IconButton(
                        iconSize: 52,

                        icon: Icon(
                          _isPlaying
                              ? Icons.stop_circle
                              : Icons.play_circle,
                        ),

                        color: Colors.blue,

                        onPressed:
                            (hasRecorded &&
                                    !_isRecording)
                                ? () =>
                                    _togglePlayback(index)
                                : null,
                      ),
                    ),

                    // RECORD BUTTON

                    GestureDetector(
                      onTapDown: (_) =>
                          _handleRecordStart(index),

                      onTapUp: (_) =>
                          _handleRecordStop(index),

                      onTapCancel: () =>
                          _handleRecordStop(index),

                      child: CircleAvatar(
                        radius: 42,

                        backgroundColor: _isRecording
                            ? Colors.red
                            : Colors.grey.shade400,

                        child: const Icon(
                          Icons.mic,
                          size: 42,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 8),

                Text(
                  _isRecording
                      ? "Recording..."
                      : "(Hold to record)",

                  style: const TextStyle(
                    color: Colors.grey,
                  ),
                ),

                // ===============================
                // VISUALIZER
                // ===============================

                SizedBox(
                  height: 70,

                  child: _isRecording
                      ? Column(
                          mainAxisAlignment:
                              MainAxisAlignment.center,

                          children: [

                            Text(
                              _formatTime(
                                Duration(
                                  seconds:
                                      _recordDuration,
                                ),
                              ),

                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight:
                                    FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,

                              crossAxisAlignment:
                                  CrossAxisAlignment.center,

                              children:
                                  _amplitudes.map((amp) {
                                return AnimatedContainer(
                                  duration:
                                      const Duration(
                                    milliseconds: 50,
                                  ),

                                  margin:
                                      const EdgeInsets
                                          .symmetric(
                                    horizontal: 2,
                                  ),

                                  width: 6,

                                  height:
                                      10 + (amp * 30),

                                  decoration:
                                      BoxDecoration(
                                    color:
                                        Colors.redAccent,

                                    borderRadius:
                                        BorderRadius
                                            .circular(
                                      10,
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        )
                      : null,
                ),

                const Spacer(),

                // ===============================
                // NAVIGATION
                // ===============================

                Row(
                  mainAxisAlignment:
                      MainAxisAlignment.spaceBetween,

                  children: [

                    ElevatedButton(
                      onPressed: index > 0
                          ? () {
                              _audioService
                                  .stopAudio();

                              provider
                                  .previousSentence();

                              setState(() =>
                                  _audioPosition =
                                      Duration.zero);
                            }
                          : null,

                      child: const Text('Previous'),
                    ),

                    ElevatedButton(
                      onPressed: index <
                              provider.sentences.length -
                                  1
                          ? () {
                              _audioService
                                  .stopAudio();

                              provider.nextSentence();

                              setState(() =>
                                  _audioPosition =
                                      Duration.zero);
                            }
                          : null,

                      child: const Text('Next'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}