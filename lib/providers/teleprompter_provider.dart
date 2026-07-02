import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../services/audio_service.dart';
import '../services/transcription_service.dart';
import '../services/scoring_service.dart';
import '../models/lesson.dart';
import '../models/practice_result.dart';
import 'progress_provider.dart';

class TeleprompterProvider with ChangeNotifier {
  final AudioService _audioService = AudioService();

  double _fontSize = 24.0;
  double _wpm = 140.0; // Words Per Minute (speed)
  bool _isPlaying = false;
  bool _isRecording = false;
  bool _isProcessingResult = false;
  TextAlign _textAlign = TextAlign.center;

  int _elapsedSeconds = 0;
  int _activeSentenceIndex = 0;
  double _currentSentenceProgress = 0.0; // 0.0 to 1.0 progress on active sentence

  List<String> _sentences = [];
  Timer? _timer;
  int _timerTicks = 0;
  VoidCallback? _onFinished;

  // Recording results paths and error handlers
  String? _recordingFilePath;
  String? _recordingError;

  double get fontSize => _fontSize;
  double get wpm => _wpm;
  bool get isPlaying => _isPlaying;
  bool get isRecording => _isRecording;
  TextAlign get textAlign => _textAlign;
  int get elapsedSeconds => _elapsedSeconds;
  int get activeSentenceIndex => _activeSentenceIndex;
  double get currentSentenceProgress => _currentSentenceProgress;
  List<String> get sentences => _sentences;
  String? get recordingFilePath => _recordingFilePath;
  String? get recordingError => _recordingError;

  void init(List<String> sentences, {VoidCallback? onFinished}) {
    _sentences = sentences;
    _activeSentenceIndex = 0;
    _currentSentenceProgress = 0.0;
    _elapsedSeconds = 0;
    _isPlaying = false;
    _isRecording = false;
    _recordingFilePath = null;
    _recordingError = null;
    _onFinished = onFinished;
    _stopTimer();
    _audioService.stopRecording().catchError((_) => null); // Safe cleanup
    notifyListeners();
  }

  void setFontSize(double size) {
    _fontSize = size.clamp(16.0, 40.0);
    notifyListeners();
  }

  void setWpm(double value) {
    _wpm = value.clamp(80.0, 250.0);
    notifyListeners();
  }

  void setTextAlign(TextAlign alignment) {
    _textAlign = alignment;
    notifyListeners();
  }

  Future<void> togglePlay() async {
    if (_sentences.isEmpty) return;
    _isPlaying = !_isPlaying;
    
    if (_isPlaying) {
      _startTimer();
      // If we are in recording mode, resume the hardware audio recording
      if (_isRecording) {
        try {
          await _audioService.resumeRecording();
        } catch (e) {
          _recordingError = 'Failed to resume recording: $e';
        }
      }
    } else {
      _pauseTimerIfNeeded();
      // If we are in recording mode, pause the hardware audio recording
      if (_isRecording) {
        try {
          await _audioService.pauseRecording();
        } catch (e) {
          _recordingError = 'Failed to pause recording: $e';
        }
      }
    }
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    if (_sentences.isEmpty) return;
    _recordingError = null;

    if (!_isRecording) {
      // Start dynamic audio recording
      try {
        final hasPermission = await _audioService.hasPermission();
        if (!hasPermission) {
          _recordingError = 'Microphone permission denied.';
          notifyListeners();
          return;
        }

        final path = await _audioService.getUniqueFilePath();
        await _audioService.startRecording(path);
        
        _recordingFilePath = path;
        _isRecording = true;
        _isPlaying = true;
        _startTimer();
      } catch (e) {
        _recordingError = 'Could not start recording: $e';
        _isRecording = false;
        _isPlaying = false;
      }
    } else {
      // Stop recording
      await stopAndSaveRecording();
    }
    notifyListeners();
  }

  Future<String?> stopAndSaveRecording() async {
    String? path;
    try {
      path = await _audioService.stopRecording();
      if (path != null) {
        _recordingFilePath = path;
      }
    } catch (e) {
      _recordingError = 'Failed to save audio file: $e';
    }
    _isRecording = false;
    _isPlaying = false;
    _stopTimer();
    notifyListeners();
    return path;
  }

  void jumpToSentence(int index) {
    if (_sentences.isEmpty) return;
    _activeSentenceIndex = index.clamp(0, _sentences.length - 1);
    _currentSentenceProgress = 0.0;
    notifyListeners();
  }

  Future<void> stopAll() async {
    _isPlaying = false;
    if (_isRecording) {
      await stopAndSaveRecording();
    } else {
      _stopTimer();
    }
    notifyListeners();
  }

  Future<void> reset() async {
    _isPlaying = false;
    _activeSentenceIndex = 0;
    _currentSentenceProgress = 0.0;
    _elapsedSeconds = 0;
    _stopTimer();
    
    if (_isRecording) {
      try {
        await _audioService.stopRecording();
      } catch (_) {}
      _isRecording = false;
    }
    _recordingFilePath = null;
    _recordingError = null;
    notifyListeners();
  }

  void _startTimer() {
    if (_timer != null) return;
    _timerTicks = 0;
    
    // Tick every 100ms for smooth speed tracking and sentence progress updates
    _timer = Timer.periodic(const Duration(milliseconds: 100), (timer) {
      if (!_isPlaying) return;

      _timerTicks++;
      if (_timerTicks % 10 == 0) {
        _elapsedSeconds++;
      }

      if (_activeSentenceIndex < _sentences.length) {
        final currentSentence = _sentences[_activeSentenceIndex];
        
        final wordCount = currentSentence
            .split(RegExp(r'\s+'))
            .where((w) => w.isNotEmpty)
            .length;

        final wordsPerSecond = _wpm / 60.0;
        double sentenceDurationSec = wordCount / wordsPerSecond;

        if (sentenceDurationSec < 1.8) {
          sentenceDurationSec = 1.8;
        }

        _currentSentenceProgress += 0.1 / sentenceDurationSec;

        if (_currentSentenceProgress >= 1.0) {
          _currentSentenceProgress = 0.0;
          if (_activeSentenceIndex < _sentences.length - 1) {
            _activeSentenceIndex++;
          } else {
            // Reached the end!
            stopAll();
            if (_onFinished != null) {
              _onFinished!();
            }
          }
        }
      }
      notifyListeners();
    });
  }

  void _pauseTimerIfNeeded() {
    if (!_isPlaying && !_isRecording) {
      _timer?.cancel();
      _timer = null;
    }
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
  }

  bool get isProcessingResult => _isProcessingResult;

  Future<PracticeResult?> finishAndScoreSession({
    required Lesson lesson,
    required ProgressProvider progressProvider,
  }) async {
    if (_isProcessingResult) return null;
    _isProcessingResult = true;
    _recordingError = null;
    notifyListeners();

    try {
      // 1. Stop recording and get path
      String? path = _recordingFilePath;
      if (_isRecording) {
        path = await stopAndSaveRecording();
      } else {
        await stopAll();
      }

      // Fallback for simulation / mock when microphone wasn't toggled
      if (path == null || path.isEmpty) {
        path = await _audioService.getUniqueFilePath();
        final file = File(path);
        await file.writeAsString('mock audio content');
      }

      // 2. Transcribe
      final transcriptionService = TranscriptionService();
      final transcript = await transcriptionService.transcribe(path, referenceText: lesson.content);

      // 3. Score
      final scoringService = ScoringService();
      final result = scoringService.score(
        lesson: lesson,
        transcript: transcript,
        sessionDuration: Duration(seconds: _elapsedSeconds),
        audioFilePath: path,
        targetWpm: _wpm.round(),
      );

      // 4. Save result
      progressProvider.saveResult(result);
      return result;
    } catch (e) {
      _recordingError = 'Processing failed: $e';
      print('Error in finishAndScoreSession: $e');
      rethrow;
    } finally {
      _isProcessingResult = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _audioService.dispose();
    super.dispose();
  }
}
