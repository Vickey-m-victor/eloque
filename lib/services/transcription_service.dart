import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class TranscriptionService {
  /// Transcribes a local audio file to text.
  /// If an OpenAI API key is found in SharedPreferences, it queries the Whisper API.
  /// Otherwise, it falls back to a realistic simulated transcription.
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

    // 3. Check for API key
    String apiKey = '';
    try {
      final prefs = await SharedPreferences.getInstance();
      apiKey = prefs.getString('openai_api_key') ?? '';
    } catch (e) {
      debugPrint('Error accessing SharedPreferences: $e');
    }

    if (apiKey.isNotEmpty) {
      return await _transcribeWithWhisper(file, apiKey);
    } else {
      return await _transcribeSimulated(referenceText);
    }
  }

  /// Sends the audio file to OpenAI's Whisper API.
  Future<String> _transcribeWithWhisper(File file, String apiKey) async {
    try {
      final url = Uri.parse('https://api.openai.com/v1/audio/transcriptions');
      final request = http.MultipartRequest('POST', url)
        ..headers['Authorization'] = 'Bearer $apiKey'
        ..fields['model'] = 'whisper-1'
        ..files.add(await http.MultipartFile.fromPath(
          'file',
          file.path,
        ));

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final Map<String, dynamic> jsonResponse = jsonDecode(response.body);
        return jsonResponse['text'] ?? '';
      } else {
        final Map<String, dynamic> errorBody = jsonDecode(response.body);
        final errorMessage = errorBody['error']?['message'] ?? 'Unknown error';
        throw Exception('Whisper API Error (${response.statusCode}): $errorMessage');
      }
    } catch (e) {
      debugPrint('Whisper transcription failed: $e. Falling back to simulation.');
      rethrow;
    }
  }

  /// Simulated transcription pipeline fallback.
  Future<String> _transcribeSimulated(String? referenceText) async {
    // Simulate transcription processing latency
    await Future.delayed(const Duration(milliseconds: 1500));

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

    return 'hello, this is a simulated transcription of your speaking practice session. it seems no reference text was passed.';
  }
}
