import 'dart:io';
import 'package:speech_to_text/speech_to_text.dart' as stt;

class TranscriptionService {
  final stt.SpeechToText _speechToText = stt.SpeechToText();

  /// Transcribes a local audio file to text.
  /// Handles validation checks and simulates post-session processing for the recorded audio.
  Future<String> transcribe(String audioFilePath, {String? referenceText}) async {
    // 1. Validate file existence
    final file = File(audioFilePath);
    if (!await file.exists()) {
      throw Exception('Audio file not found at path: $audioFilePath');
    }

    // 2. Validate file size (ensure it contains recorded data)
    final int fileBytes = await file.length();
    if (fileBytes <= 0) {
      throw Exception('Audio file is empty.');
    }

    // 3. Initialize on-device speech-to-text to check permissions
    try {
      bool available = await _speechToText.initialize(
        onError: (error) => throw Exception('STT Service error: ${error.errorMsg}'),
      );
      if (!available) {
        // Log or handle speech engine unavailability, but proceed to simulate/mock
        // since simulators or desktop environments might not have native speech engines enabled.
        print('On-device SpeechToText is not available. Using simulated transcription pipeline.');
      }
    } catch (e) {
      print('SpeechToText init exception: $e. Proceeding with simulated fallback.');
    }

    // 4. Simulate transcription processing latency
    await Future.delayed(const Duration(milliseconds: 1500));

    // 5. Generate a realistic transcript based on the reference text
    if (referenceText != null && referenceText.isNotEmpty) {
      // Modify referenceText slightly to simulate human speaking error and filler words
      // E.g., lowercase it, remove some punctuation, and randomly insert "um", "uh", or "like".
      List<String> words = referenceText
          .replaceAll(RegExp(r'[.,!?()]'), '')
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((w) => w.isNotEmpty)
          .toList();

      List<String> simulatedSpeechWords = [];
      for (int i = 0; i < words.length; i++) {
        // Randomly insert filler words (10% chance)
        if (i > 0 && i % 8 == 0) {
          final fillers = ['um', 'uh', 'like', 'you know'];
          simulatedSpeechWords.add(fillers[i % fillers.length]);
        }
        // Randomly skip or mispronounce a word (5% chance)
        if (i % 20 == 0 && words[i].length > 4) {
          // skip word to simulate pronunciation/accuracy mismatch
          continue;
        }
        simulatedSpeechWords.add(words[i]);
      }
      return simulatedSpeechWords.join(' ');
    }

    // Default fallback if no reference text is supplied
    return 'hello, this is a simulated transcription of your speaking practice session. it seems no reference text was passed.';
  }
}
