import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioService {
  final AudioRecorder _recorder = AudioRecorder();

  Future<bool> hasPermission() async {
    try {
      return await _recorder.hasPermission();
    } catch (e) {
      return false;
    }
  }

  Future<void> startRecording(String filePath) async {
    final bool permissionGranted = await _recorder.hasPermission();
    if (!permissionGranted) {
      throw Exception('Microphone permission not granted.');
    }

    // Configure recording settings: High-compatibility AAC LC codec, mono, 44.1kHz
    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.aacLc,
        bitRate: 128000,
        sampleRate: 44100,
        numChannels: 1,
      ),
      path: filePath,
    );
  }

  Future<void> pauseRecording() async {
    if (await _recorder.isRecording()) {
      await _recorder.pause();
    }
  }

  Future<void> resumeRecording() async {
    if (await _recorder.isPaused()) {
      await _recorder.resume();
    }
  }

  Future<String?> stopRecording() async {
    return await _recorder.stop();
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<bool> isPaused() async {
    return await _recorder.isPaused();
  }

  /// Exposes a utility method to fetch a clean, platform-specific local documents path to save .m4a files.
  Future<String> getUniqueFilePath() async {
    final Directory appDirectory = await getApplicationDocumentsDirectory();
    final String timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    return '${appDirectory.path}/eloque_recording_$timestamp.m4a';
  }

  void dispose() {
    _recorder.dispose();
  }
}
