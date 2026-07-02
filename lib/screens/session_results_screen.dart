import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:audioplayers/audioplayers.dart';
import '../models/practice_result.dart';
import '../models/lesson.dart';
import '../providers/teleprompter_provider.dart';

class SessionResultsScreen extends StatefulWidget {
  final PracticeResult result;
  final Lesson lesson;

  const SessionResultsScreen({
    super.key,
    required this.result,
    required this.lesson,
  });

  @override
  State<SessionResultsScreen> createState() => _SessionResultsScreenState();
}

class _SessionResultsScreenState extends State<SessionResultsScreen> {
  late final AudioPlayer _audioPlayer;
  PlayerState _playerState = PlayerState.stopped;
  Duration _duration = Duration.zero;
  Duration _position = Duration.zero;

  bool _isPlayerInitialized = false;
  String? _playerError;

  @override
  void initState() {
    super.initState();
    _initAudioPlayer();
  }

  Future<void> _initAudioPlayer() async {
    _audioPlayer = AudioPlayer();
    try {
      if (widget.result.audioFilePath.isNotEmpty &&
          await File(widget.result.audioFilePath).exists()) {
        await _audioPlayer.setSource(DeviceFileSource(widget.result.audioFilePath));
        _isPlayerInitialized = true;
      } else {
        _playerError = 'Audio file not found or empty';
      }
    } catch (e) {
      _playerError = 'Failed to load audio: $e';
    }

    _audioPlayer.onPlayerStateChanged.listen((state) {
      if (mounted) {
        setState(() {
          _playerState = state;
        });
      }
    });

    _audioPlayer.onDurationChanged.listen((duration) {
      if (mounted) {
        setState(() {
          _duration = duration;
        });
      }
    });

    _audioPlayer.onPositionChanged.listen((position) {
      if (mounted) {
        setState(() {
          _position = position;
        });
      }
    });
  }

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _togglePlayback() async {
    if (!_isPlayerInitialized) return;
    try {
      if (_playerState == PlayerState.playing) {
        await _audioPlayer.pause();
      } else {
        await _audioPlayer.resume();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback error: $e')),
        );
      }
    }
  }

  String _formatDuration(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = duration.inSeconds % 60;
    return '$minutes:${seconds.toString().padLeft(2, '0')}';
  }

  String _getPaceLabel(int actualWpm) {
    if (actualWpm < 110) return 'Too Slow 🐢';
    if (actualWpm < 130) return 'Slow 🚶';
    if (actualWpm <= 160) return 'Perfect Pace 🎯';
    if (actualWpm < 180) return 'Fast 🏃';
    return 'Too Fast ⚡';
  }

  Color _getPaceColor(int actualWpm) {
    if (actualWpm < 110 || actualWpm > 180) return const Color(0xFFEF4444); // Red
    if (actualWpm < 130 || actualWpm > 160) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFF10B981); // Emerald
  }

  String _getFluencyDescription(double score) {
    if (score >= 90) return 'Elite Speaker 🌟';
    if (score >= 80) return 'Excellent Fluency ✨';
    if (score >= 70) return 'Good Progress 👍';
    if (score >= 50) return 'Developing Speaker 🌱';
    return 'Needs More Practice 💪';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isDark ? const Color(0xFF070B13) : const Color(0xFFF8FAFC);
    final cardBg = isDark ? const Color(0xFF151D30) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF475569);

    final isConversational = widget.lesson.track == LessonTrack.conversational;

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: scaffoldBg,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textColor),
          titleTextStyle: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Practice Performance'),
          automaticallyImplyLeading: false,
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 1. Overall Score Ring Gauge Card
                _buildFluencyGaugeCard(cardBg, textColor, subTextColor, theme),

                const SizedBox(height: 16),

                // 2. Metrics Breakdown Row/Grid
                Row(
                  children: [
                    if (isConversational) ...[
                      Expanded(
                        child: _buildMetricCard(
                          cardBg: cardBg,
                          textColor: textColor,
                          title: 'Accuracy',
                          value: '${widget.result.accuracyScore.round()}%',
                          subtitle: widget.result.accuracyScore >= 85 ? 'Highly Accurate' : 'Mind the script',
                          icon: Icons.check_circle_outline_rounded,
                          iconColor: const Color(0xFF10B981),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _buildMetricCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        title: 'Speaking Pace',
                        value: '${widget.result.actualWpm} WPM',
                        subtitle: _getPaceLabel(widget.result.actualWpm),
                        icon: Icons.speed_rounded,
                        iconColor: _getPaceColor(widget.result.actualWpm),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: _buildMetricCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        title: 'Filler Words',
                        value: '${widget.result.fillerWordCount}',
                        subtitle: widget.result.fillerWordCount == 0
                            ? 'Excellent Control!'
                            : '${widget.result.fillerWordCount} filler(s) detected',
                        icon: Icons.record_voice_over_rounded,
                        iconColor: widget.result.fillerWordCount == 0
                            ? const Color(0xFF10B981)
                            : const Color(0xFFEC4899),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildMetricCard(
                        cardBg: cardBg,
                        textColor: textColor,
                        title: 'Duration',
                        value: _formatDuration(widget.result.sessionDuration),
                        subtitle: 'Total speaking time',
                        icon: Icons.timer_outlined,
                        iconColor: const Color(0xFF06B6D4),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                // 3. Audio Playback Component Card
                _buildAudioPlayerCard(cardBg, textColor, subTextColor, theme),

                const SizedBox(height: 16),

                // 4. Highlighted Transcript View Card
                _buildTranscriptCard(cardBg, textColor, subTextColor, theme),

                const SizedBox(height: 24),

                // 5. Action Buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () {
                          // Try Again: reset provider state and navigate back
                          Provider.of<TeleprompterProvider>(context, listen: false).reset();
                          Navigator.pop(context);
                        },
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          side: BorderSide(
                            color: theme.colorScheme.primary.withOpacity(0.5),
                          ),
                        ),
                        child: Text(
                          'Try Again',
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          // Reset prompter and go back to navigation / root
                          Provider.of<TeleprompterProvider>(context, listen: false).reset();
                          Navigator.of(context).popUntil((route) => route.isFirst);
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: theme.colorScheme.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          elevation: 0,
                        ),
                        child: const Text(
                          'Done',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFluencyGaugeCard(
    Color cardBg,
    Color textColor,
    Color subTextColor,
    ThemeData theme,
  ) {
    final isConversational = widget.lesson.track == LessonTrack.conversational;
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text(
              'Fluency Score',
              style: TextStyle(
                color: subTextColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
                letterSpacing: 0.5,
              ),
            ),
            const SizedBox(height: 20),
            TweenAnimationBuilder<double>(
              tween: Tween<double>(begin: 0, end: widget.result.fluencyScore),
              duration: const Duration(milliseconds: 1200),
              curve: Curves.easeOutCubic,
              builder: (context, value, child) {
                return Stack(
                  alignment: Alignment.center,
                  children: [
                    SizedBox(
                      width: 160,
                      height: 160,
                      child: CustomPaint(
                        painter: ScoreGaugePainter(
                          score: value,
                          primaryColor: theme.colorScheme.primary,
                          trackColor: theme.colorScheme.primary.withOpacity(0.08),
                        ),
                      ),
                    ),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '${value.round()}%',
                          style: TextStyle(
                            color: textColor,
                            fontSize: 38,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Outfit',
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _getFluencyDescription(widget.result.fluencyScore),
                          style: TextStyle(
                            color: theme.colorScheme.primary,
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 8),
            Text(
              'Your fluency score was calculated using pace and filler words${isConversational ? ' weighted alongside text match accuracy' : ''}.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: subTextColor.withOpacity(0.8),
                fontSize: 12.5,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricCard({
    required Color cardBg,
    required Color textColor,
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color iconColor,
  }) {
    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: textColor.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Icon(icon, color: iconColor, size: 20),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: TextStyle(
                color: textColor,
                fontSize: 22,
                fontWeight: FontWeight.bold,
                fontFamily: 'Outfit',
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: iconColor,
                fontSize: 11,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioPlayerCard(
    Color cardBg,
    Color textColor,
    Color subTextColor,
    ThemeData theme,
  ) {
    if (_playerError != null) {
      return Card(
        color: cardBg,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              const Icon(Icons.info_outline_rounded, color: Colors.amber),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Audio playback unavailable: $_playerError',
                  style: TextStyle(color: subTextColor, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      );
    }

    final isPlaying = _playerState == PlayerState.playing;
    final totalDurationMs = _duration.inMilliseconds;
    final currentPosMs = _position.inMilliseconds;
    final double sliderValue = (totalDurationMs > 0)
        ? (currentPosMs / totalDurationMs).clamp(0.0, 1.0)
        : 0.0;

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Listen to Your Recording',
              style: TextStyle(
                color: textColor,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                GestureDetector(
                  onTap: _togglePlayback,
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 26,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    children: [
                      SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          trackHeight: 4,
                          thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 6),
                          overlayShape: const RoundSliderOverlayShape(overlayRadius: 14),
                          activeTrackColor: theme.colorScheme.primary,
                          inactiveTrackColor: theme.colorScheme.primary.withOpacity(0.12),
                          thumbColor: theme.colorScheme.primary,
                        ),
                        child: Slider(
                          value: sliderValue,
                          onChanged: (val) {
                            if (_isPlayerInitialized && totalDurationMs > 0) {
                              final seekTo = Duration(milliseconds: (val * totalDurationMs).round());
                              _audioPlayer.seek(seekTo);
                            }
                          },
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              _formatDuration(_position),
                              style: TextStyle(color: subTextColor, fontSize: 11),
                            ),
                            Text(
                              _formatDuration(_duration),
                              style: TextStyle(color: subTextColor, fontSize: 11),
                            ),
                          ],
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTranscriptCard(
    Color cardBg,
    Color textColor,
    Color subTextColor,
    ThemeData theme,
  ) {
    final isDark = theme.brightness == Brightness.dark;
    final transcript = widget.result.transcript;
    if (transcript.isEmpty) {
      return Card(
        color: cardBg,
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Center(
            child: Text('No transcript available'),
          ),
        ),
      );
    }

    // Identify filler words and highlight them in the text
    final List<String> words = transcript.split(RegExp(r'\s+'));
    final List<TextSpan> textSpans = [];

    final fillerList = ['um', 'uh', 'like', 'you', 'know'];

    for (int i = 0; i < words.length; i++) {
      final word = words[i];
      final cleanWord = word.replaceAll(RegExp(r'[.,!?()]'), '').toLowerCase();

      bool isFiller = false;
      // Handle simple word fillers
      if (fillerList.contains(cleanWord)) {
        isFiller = true;
      }
      
      // Also handle "you know" phrase by checking next word
      if (cleanWord == 'you' && i + 1 < words.length) {
        final nextClean = words[i + 1].replaceAll(RegExp(r'[.,!?()]'), '').toLowerCase();
        if (nextClean == 'know') {
          isFiller = true;
        }
      } else if (cleanWord == 'know' && i > 0) {
        final prevClean = words[i - 1].replaceAll(RegExp(r'[.,!?()]'), '').toLowerCase();
        if (prevClean == 'you') {
          isFiller = true;
        }
      }

      if (isFiller) {
        textSpans.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(
              color: theme.colorScheme.tertiary,
              fontWeight: FontWeight.bold,
              backgroundColor: theme.colorScheme.tertiary.withOpacity(0.12),
            ),
          ),
        );
      } else {
        textSpans.add(
          TextSpan(
            text: '$word ',
            style: TextStyle(color: textColor.withOpacity(0.85)),
          ),
        );
      }
    }

    return Card(
      color: cardBg,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Speech Transcript',
                  style: TextStyle(
                    color: textColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                if (widget.result.fillerWordCount > 0)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.tertiary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Highlights: Fillers',
                      style: TextStyle(
                        color: theme.colorScheme.tertiary,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              constraints: const BoxConstraints(maxHeight: 180),
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.background,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
                ),
              ),
              child: SingleChildScrollView(
                child: RichText(
                  text: TextSpan(
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.5,
                      fontFamily: 'PlusJakartaSans',
                    ),
                    children: textSpans,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ScoreGaugePainter extends CustomPainter {
  final double score; // 0 to 100
  final Color primaryColor;
  final Color trackColor;

  ScoreGaugePainter({
    required this.score,
    required this.primaryColor,
    required this.trackColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (min(size.width, size.height) / 2) - 10;
    const strokeWidth = 12.0;

    // Track arc
    final trackPaint = Paint()
      ..color = trackColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    // 240 degrees gauge (starts at 150 deg, spans 240 deg)
    final startAngle = 150 * pi / 180;
    final sweepAngle = 240 * pi / 180;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      sweepAngle,
      false,
      trackPaint,
    );

    // Score arc
    final scoreSweepAngle = (score / 100.0) * sweepAngle;
    final scorePaint = Paint()
      ..shader = SweepGradient(
        colors: [
          primaryColor.withOpacity(0.4),
          primaryColor,
        ],
        stops: const [0.0, 1.0],
        startAngle: startAngle,
        endAngle: startAngle + sweepAngle,
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      startAngle,
      scoreSweepAngle,
      false,
      scorePaint,
    );
  }

  @override
  bool shouldRepaint(covariant ScoreGaugePainter oldDelegate) {
    return oldDelegate.score != score ||
        oldDelegate.primaryColor != primaryColor ||
        oldDelegate.trackColor != trackColor;
  }
}
