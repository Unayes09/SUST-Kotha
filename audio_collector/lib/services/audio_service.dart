import 'package:record/record.dart';
import 'package:audioplayers/audioplayers.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();
  final AudioPlayer _player = AudioPlayer();

  Future<bool> hasPermission() async {
    return await _recorder.hasPermission();
  }

  // Add this method to expose the live volume levels
  Stream<Amplitude> get amplitudeStream {
    // Updates the visualizer every 50 milliseconds for smooth animation
    return _recorder.onAmplitudeChanged(const Duration(milliseconds: 50));
  }

  Future<void> startRecording(String path) async {
    if (await hasPermission()) {
      const config = RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 44100,
        numChannels: 1, // Mono for acoustic models
      );
      await _recorder.start(config, path: path);
    }
  }

  Future<void> stopRecording() async {
    await _recorder.stop();
  }

  Future<void> playAudio(String path) async {
    // I removed the 'const' keyword here:
    await _player.setAudioContext(AudioContext(
      android: AudioContextAndroid(
        isSpeakerphoneOn: true,
        stayAwake: true,
      ),
    ));
    
    // Set the update interval (This makes the slider glide smoothly)
    await _player.setReleaseMode(ReleaseMode.stop);
    
    await _player.play(DeviceFileSource(path));
  }

  Future<void> stopAudio() async {
    await _player.stop();
  }
  
  Stream<PlayerState> get playerStateStream => _player.onPlayerStateChanged;
  // Add these three streams to your AudioService
  Stream<Duration> get positionStream => _player.onPositionChanged;
  Stream<Duration> get durationStream => _player.onDurationChanged;
  
  // Optional but helpful: allows setting the source without auto-playing to get duration
  Future<void> setSource(String path) async {
    await _player.setSourceDeviceFile(path);
  }

  void dispose() {
    _recorder.dispose();
    _player.dispose();
  }
}