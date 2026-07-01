import 'dart:math';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../providers/teleprompter_provider.dart';
import '../widgets/teleprompter_controls.dart';
import '../widgets/teleprompter_text_viewer.dart';

class TeleprompterScreen extends StatefulWidget {
  const TeleprompterScreen({super.key});

  @override
  State<TeleprompterScreen> createState() => _TeleprompterScreenState();
}

class _TeleprompterScreenState extends State<TeleprompterScreen> with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();

    // Initialize provider with current lesson's sentences
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
      final teleprompterProvider = Provider.of<TeleprompterProvider>(context, listen: false);
      final selectedLesson = lessonProvider.selectedLesson;
      
      if (selectedLesson != null) {
        teleprompterProvider.init(
          selectedLesson.sentences,
          onFinished: _handleFinished,
        );
      }
    });

    // Animation for voice visualizer waves during simulated recording
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  void _handleFinished() {
    if (!mounted) return;
    
    final teleprompterProvider = Provider.of<TeleprompterProvider>(context, listen: false);
    final lessonProvider = Provider.of<LessonProvider>(context, listen: false);
    final lesson = lessonProvider.selectedLesson;

    if (lesson == null) return;

    // Make sure we stop everything
    teleprompterProvider.stopAll();

    // Generate random realistic metrics for MVP feedback
    final random = Random();
    final fluencyScore = 82 + random.nextInt(16); // 82 - 97%
    final accuracyScore = 80 + random.nextInt(18); // 80 - 97%
    final elapsedMin = max(1, (teleprompterProvider.elapsedSeconds / 60).ceil());

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          contentPadding: const EdgeInsets.all(24),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.emoji_events_rounded,
                  color: theme.colorScheme.primary,
                  size: 48,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Practice Complete!',
                style: theme.textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Here is your preliminary AI speech feedback:',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricDial(context, label: 'Fluency', value: '$fluencyScore%'),
                  _buildMetricDial(context, label: 'Accuracy', value: '$accuracyScore%'),
                ],
              ),
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceVariant.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(Icons.mic_none_rounded, color: theme.colorScheme.primary, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Pace felt natural (~${teleprompterProvider.wpm.toInt()} WPM). Nice flow between sentences.',
                        style: theme.textTheme.bodySmall?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
              if (teleprompterProvider.recordingFilePath != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.folder_open_rounded, color: Colors.amber[700], size: 16),
                          const SizedBox(width: 6),
                          const Text(
                            'Saved Recording File:',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        teleprompterProvider.recordingFilePath!,
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'monospace',
                          color: theme.colorScheme.onBackground.withOpacity(0.6),
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        teleprompterProvider.reset();
                        Navigator.pop(context);
                      },
                      child: const Text('Try Again'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.colorScheme.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      onPressed: () {
                        lessonProvider.completeLesson(lesson.id, elapsedMin, fluencyScore);
                        teleprompterProvider.reset();
                        Navigator.pop(context); // Close dialog
                        Navigator.pop(context); // Go back to library
                      },
                      child: const Text('Save & Exit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMetricDial(BuildContext context, {required String label, required String value}) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Text(
          value,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.w800,
            color: theme.colorScheme.primary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: theme.colorScheme.onBackground.withOpacity(0.5),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final teleprompterProvider = Provider.of<TeleprompterProvider>(context);
    final lesson = lessonProvider.selectedLesson;

    if (lesson == null) {
      return const Scaffold(
        body: Center(child: Text('No lesson selected')),
      );
    }

    final isDark = theme.brightness == Brightness.dark;
    final scaffoldBg = isDark ? const Color(0xFF070B13) : const Color(0xFFF8FAFC);
    final textThemeColor = isDark ? Colors.white : const Color(0xFF0F172A);

    return Theme(
      data: theme.copyWith(
        scaffoldBackgroundColor: scaffoldBg,
        appBarTheme: AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: textThemeColor),
          titleTextStyle: TextStyle(color: textThemeColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(lesson.category),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => _showSettingsBottomSheet(context),
              tooltip: 'Prompter Settings',
            ),
          ],
        ),
        body: Stack(
          children: [
            // Prompter Script List Text Viewer
            const Positioned.fill(
              child: TeleprompterTextViewer(),
            ),

            // Top Gradient Fade Overlay (covers upper text list)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scaffoldBg, scaffoldBg.withOpacity(0.0)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // Bottom Gradient Fade Overlay (above the bottom dock)
            Positioned(
              bottom: 200,
              left: 0,
              right: 0,
              height: 140,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [scaffoldBg.withOpacity(0.0), scaffoldBg],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
              ),
            ),

            // Midline Focus Guide Brackets (Centered exactly at 35% viewport height to frame the highlighted text)
            Positioned(
              left: 12,
              right: 12,
              top: MediaQuery.of(context).size.height * 0.35 - 65,
              height: 130,
              child: IgnorePointer(
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.symmetric(
                      horizontal: BorderSide(
                        color: theme.colorScheme.primary.withOpacity(isDark ? 0.18 : 0.3),
                        width: 1.5,
                      ),
                    ),
                    color: theme.colorScheme.primary.withOpacity(isDark ? 0.02 : 0.04),
                  ),
                ),
              ),
            ),

            // Top Status Panel (Duration & REC animation)
            Positioned(
              top: 10,
              left: 20,
              right: 20,
              child: Column(
                children: [
                  if (teleprompterProvider.recordingError != null)
                    Container(
                      margin: const EdgeInsets.only(bottom: 10),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.red.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline_rounded, color: Colors.red, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              teleprompterProvider.recordingError!,
                              style: const TextStyle(color: Colors.red, fontSize: 11, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Elapsed Timer
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.06) : Colors.black.withOpacity(0.04),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08), 
                            width: 1,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.timer_rounded, color: Color(0xFF06B6D4), size: 16),
                            const SizedBox(width: 6),
                            Text(
                              _formatDuration(teleprompterProvider.elapsedSeconds),
                              style: TextStyle(
                                color: textThemeColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // Recording Status Indicator
                      if (teleprompterProvider.isRecording)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.15),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.3), width: 1),
                          ),
                          child: Row(
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: Color(0xFFEF4444),
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'REC',
                                style: TextStyle(
                                  color: Color(0xFFEF4444),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  // Voice Recording Waveform Simulation
                  if (teleprompterProvider.isRecording)
                    AnimatedBuilder(
                      animation: _waveController,
                      builder: (context, child) {
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(15, (index) {
                            final amplitude = 5 + sin(_waveController.value * 2 * pi + index) * 14 + Random().nextInt(8);
                            return Container(
                              margin: const EdgeInsets.symmetric(horizontal: 2.5),
                              width: 3.5,
                              height: max(4.0, amplitude),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.secondary.withOpacity(0.85),
                                borderRadius: BorderRadius.circular(2),
                              ),
                            );
                          }),
                        );
                      },
                    ),
                ],
              ),
            ),

            // Teleprompter Controls Panel Dock
            const Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: TeleprompterControls(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int seconds) {
    final int mins = seconds ~/ 60;
    final int secs = seconds % 60;
    return '${mins.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  void _showSettingsBottomSheet(BuildContext context) {
    final theme = Theme.of(context);
    final teleprompterProvider = Provider.of<TeleprompterProvider>(context, listen: false);
    final isDark = theme.brightness == Brightness.dark;
    
    final sheetBg = isDark ? const Color(0xFF111726) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subTextColor = isDark ? Colors.white70 : const Color(0xFF334155);
    final iconColor = isDark ? Colors.white70 : const Color(0xFF475569);

    showModalBottomSheet(
      context: context,
      backgroundColor: sheetBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setStateSheet) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: isDark ? Colors.white.withOpacity(0.2) : Colors.black.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Prompter Layout Settings',
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  const SizedBox(height: 24),

                  // Font Size
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Font Size',
                        style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
                      ),
                      Row(
                        children: [
                          IconButton(
                            icon: Icon(Icons.remove_circle_outline, color: iconColor),
                            onPressed: () {
                              teleprompterProvider.setFontSize(teleprompterProvider.fontSize - 2);
                              setStateSheet(() {});
                            },
                          ),
                          Text(
                            '${teleprompterProvider.fontSize.toInt()}',
                            style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: iconColor),
                            onPressed: () {
                              teleprompterProvider.setFontSize(teleprompterProvider.fontSize + 2);
                              setStateSheet(() {});
                            },
                          ),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Text Alignment
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Text Alignment',
                        style: TextStyle(color: subTextColor, fontWeight: FontWeight.bold),
                      ),
                      ToggleButtons(
                        isSelected: [
                          teleprompterProvider.textAlign == TextAlign.left,
                          teleprompterProvider.textAlign == TextAlign.center,
                          teleprompterProvider.textAlign == TextAlign.right,
                        ],
                        onPressed: (index) {
                          TextAlign align = TextAlign.center;
                          if (index == 0) align = TextAlign.left;
                          if (index == 2) align = TextAlign.right;
                          teleprompterProvider.setTextAlign(align);
                          setStateSheet(() {});
                        },
                        color: isDark ? Colors.white38 : Colors.black38,
                        selectedColor: isDark ? Colors.white : theme.colorScheme.primary,
                        fillColor: theme.colorScheme.primary.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                        constraints: const BoxConstraints(minWidth: 46, minHeight: 36),
                        children: const [
                          Icon(Icons.format_align_left_rounded, size: 20),
                          Icon(Icons.format_align_center_rounded, size: 20),
                          Icon(Icons.format_align_right_rounded, size: 20),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
