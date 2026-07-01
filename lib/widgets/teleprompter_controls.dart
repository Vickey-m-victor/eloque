import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/teleprompter_provider.dart';

class TeleprompterControls extends StatelessWidget {
  final VoidCallback? onResetPressed;

  const TeleprompterControls({
    super.key,
    this.onResetPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = Provider.of<TeleprompterProvider>(context);
    final isDark = theme.brightness == Brightness.dark;

    final totalSentences = provider.sentences.length;
    final currentIndex = provider.activeSentenceIndex;
    final progress = totalSentences > 0 ? (currentIndex + 1) / totalSentences : 0.0;

    final containerBg = isDark ? const Color(0xFF111726).withOpacity(0.95) : Colors.white.withOpacity(0.95);
    final borderColor = isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08);
    final shadowColor = isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.06);
    final handleColor = isDark ? Colors.white.withOpacity(0.15) : Colors.black.withOpacity(0.15);
    final labelColor = isDark ? Colors.white60 : Colors.black54;
    final textTitleColor = isDark ? Colors.white70 : const Color(0xFF0F172A);
    final iconMutedColor = isDark ? Colors.white38 : Colors.black38;

    return Container(
      decoration: BoxDecoration(
        color: containerBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: shadowColor,
            blurRadius: 24,
            offset: const Offset(0, -8),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle indicator
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: handleColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Reading sentence progress bar
          if (totalSentences > 0) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Reading Progress',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: labelColor,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'Sentence ${currentIndex + 1} of $totalSentences',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.primary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                backgroundColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
                minHeight: 4,
              ),
            ),
            const SizedBox(height: 20),
          ],

          // Speed (WPM) Slider controls
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Speed (WPM)',
                style: theme.textTheme.titleSmall?.copyWith(
                  color: textTitleColor,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: theme.colorScheme.primary.withOpacity(0.25), width: 1),
                ),
                child: Text(
                  '${provider.wpm.toInt()} WPM',
                  style: TextStyle(
                    color: theme.colorScheme.primary,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Icon(Icons.speed_outlined, color: iconMutedColor, size: 18),
              Expanded(
                child: Slider(
                  value: provider.wpm,
                  min: 80.0,
                  max: 250.0,
                  divisions: 17,
                  activeColor: theme.colorScheme.primary,
                  inactiveColor: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05),
                  onChanged: (val) {
                    provider.setWpm(val);
                  },
                ),
              ),
              Icon(Icons.rocket_launch_outlined, color: iconMutedColor, size: 18),
            ],
          ),
          const SizedBox(height: 16),

          // Action Buttons (Reset, Play/Pause/Resume, Settings placeholder or Mic toggle)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              // Reset Button
              _buildRoundButton(
                context,
                icon: Icons.replay_rounded,
                tooltip: 'Reset Teleprompter',
                backgroundColor: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04),
                iconColor: isDark ? Colors.white70 : Colors.black54,
                onTap: () {
                  provider.reset();
                  if (onResetPressed != null) {
                    onResetPressed!();
                  }
                },
              ),

              // Play / Pause central button
              GestureDetector(
                onTap: () => provider.togglePlay(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  height: 68,
                  width: 68,
                  decoration: BoxDecoration(
                    color: provider.isPlaying 
                        ? const Color(0xFFEF4444) // red for pause
                        : theme.colorScheme.primary, // violet for play
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: (provider.isPlaying ? const Color(0xFFEF4444) : theme.colorScheme.primary)
                            .withOpacity(0.35),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Icon(
                    provider.isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
                    color: Colors.white,
                    size: 36,
                  ),
                ),
              ),

              // Mock Voice Recording simulation for UI
              _buildRoundButton(
                context,
                icon: provider.isRecording ? Icons.mic_rounded : Icons.mic_none_rounded,
                tooltip: 'Simulate Recording',
                backgroundColor: provider.isRecording
                    ? const Color(0xFFEF4444).withOpacity(0.15)
                    : (isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.04)),
                iconColor: provider.isRecording ? const Color(0xFFEF4444) : (isDark ? Colors.white70 : Colors.black54),
                onTap: () => provider.toggleRecording(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRoundButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required Color backgroundColor,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: ClipOval(
        child: Material(
          color: backgroundColor,
          child: InkWell(
            onTap: onTap,
            child: SizedBox(
              width: 52,
              height: 52,
              child: Icon(
                icon,
                color: iconColor,
                size: 24,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
