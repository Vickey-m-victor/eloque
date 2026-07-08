import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/lesson_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/progress_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String _userName = 'English Learner';
  int _dailyGoalMinutes = 15; // default daily goal

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      setState(() {
        _userName = prefs.getString('user_name') ?? 'English Learner';
        _dailyGoalMinutes = prefs.getInt('daily_goal_minutes') ?? 15;
      });
    } catch (e) {
      debugPrint('Error loading preferences: $e');
    }
  }

  Future<void> _saveUserName(String name) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_name', name);
    } catch (e) {
      debugPrint('Error saving username: $e');
    }
  }

  Future<void> _saveDailyGoal(int minutes) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('daily_goal_minutes', minutes);
    } catch (e) {
      debugPrint('Error saving daily goal: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final lessonProvider = Provider.of<LessonProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);

    // Calculate level based on completed lessons
    final int userLevel = 1 + (progressProvider.completedLessonsCount ~/ 3);
    final int nextLevelLessons = (userLevel * 3);
    final int prevLevelLessons = (userLevel - 1) * 3;
    final double levelProgress = ((progressProvider.completedLessonsCount - prevLevelLessons) / 3).clamp(0.0, 1.0);

    // Calculate daily goal progress
    final double dailyGoalProgress = (progressProvider.totalPracticeMinutes / _dailyGoalMinutes).clamp(0.0, 1.0);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Profile & Settings',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_rounded),
            tooltip: 'Edit Profile Name',
            onPressed: _showEditNameDialog,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 1. Profile Header Widget
              _buildProfileHeader(theme, userLevel, levelProgress),
              const SizedBox(height: 24),

              // 2. Statistics Grid
              _buildStatsGrid(context, progressProvider, theme),
              const SizedBox(height: 28),

              // 3. Daily Practice Goal
              _buildDailyGoalCard(theme, dailyGoalProgress),
              const SizedBox(height: 28),

              // 4. Settings Section
              Text(
                'Application Settings',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              _buildSettingsCard(context, themeProvider, theme, isDark),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProfileHeader(ThemeData theme, int level, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with gradient border
          Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
              ),
            ),
            child: CircleAvatar(
              radius: 36,
              backgroundColor: theme.colorScheme.background,
              child: Text(
                _userName.isNotEmpty ? _userName[0].toUpperCase() : 'U',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: theme.colorScheme.primary,
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          // User Details & Level Progress
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _userName,
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'Level $level Speaker',
                    style: TextStyle(
                      color: theme.colorScheme.primary,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                // Level progress bar
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 6,
                          backgroundColor: theme.colorScheme.surfaceVariant,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(BuildContext context, ProgressProvider provider, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Your Statistics',
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                theme,
                title: 'Streak Days',
                value: '${provider.streakDays}',
                icon: Icons.local_fire_department_rounded,
                iconColor: const Color(0xFFFB923C),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                theme,
                title: 'Lessons Completed',
                value: '${provider.completedLessonsCount}',
                icon: Icons.check_circle_rounded,
                iconColor: const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: _buildStatTile(
                theme,
                title: 'Practice Mins',
                value: '${provider.totalPracticeMinutes}',
                icon: Icons.schedule_rounded,
                iconColor: const Color(0xFF06B6D4),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatTile(
                theme,
                title: 'Avg. Fluency',
                value: '${provider.averageFluencyScore}%',
                icon: Icons.insights_rounded,
                iconColor: theme.colorScheme.primary,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatTile(
    ThemeData theme, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: iconColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w800,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyGoalCard(ThemeData theme, double progress) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withOpacity(0.08),
            theme.colorScheme.secondary.withOpacity(0.08),
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.primary.withOpacity(0.15),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Practice Goal',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Set your target daily minutes',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onBackground.withOpacity(0.6),
                    ),
                  ),
                ],
              ),
              // Circular progress indicator
              SizedBox(
                height: 48,
                width: 48,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: progress,
                      backgroundColor: theme.colorScheme.primary.withOpacity(0.1),
                      color: theme.colorScheme.primary,
                      strokeWidth: 5,
                    ),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Goal Selector Chips
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [5, 10, 15, 30].map((minutes) {
              final isSelected = _dailyGoalMinutes == minutes;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: ChoiceChip(
                    label: Text('$minutes min'),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) {
                        setState(() {
                          _dailyGoalMinutes = minutes;
                        });
                        _saveDailyGoal(minutes);
                      }
                    },
                    selectedColor: theme.colorScheme.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(
    BuildContext context,
    ThemeProvider themeProvider,
    ThemeData theme,
    bool isDark,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withOpacity(0.4),
        ),
      ),
      child: Column(
        children: [
          // Theme Toggle Row
          ListTile(
            leading: Icon(
              isDark ? Icons.dark_mode_rounded : Icons.light_mode_rounded,
              color: theme.colorScheme.primary,
            ),
            title: const Text(
              'Dark Mode',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            trailing: Switch(
              value: themeProvider.themeMode == ThemeMode.dark,
              onChanged: (value) {
                themeProvider.toggleTheme();
              },
            ),
          ),
          Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.4), height: 1),
          // Audio Storage info tile
          ListTile(
            leading: Icon(Icons.audio_file_rounded, color: theme.colorScheme.secondary),
            title: const Text(
              'Audio File Storage',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Saved inside App Documents'),
            trailing: const Icon(Icons.info_outline_rounded),
            onTap: () {
              showDialog(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text('Audio Storage Info'),
                  content: const Text(
                    'Your practice voice recordings are stored locally on your device in your private Documents directory as premium M4A files for compatibility and speech quality control.',
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
          ),
          Divider(color: theme.colorScheme.outlineVariant.withOpacity(0.4), height: 1),
          // About App Tile
          ListTile(
            leading: const Icon(Icons.info_outline_rounded, color: Colors.blueGrey),
            title: const Text(
              'About Eloque',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: const Text('Version 1.0.0'),
            onTap: () {
              showAboutDialog(
                context: context,
                applicationName: 'Eloque',
                applicationVersion: '1.0.0',
                applicationIcon: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Icon(Icons.waves_rounded, color: theme.colorScheme.primary, size: 40),
                ),
                children: const [
                  Text(
                    'Eloque is an advanced agentic teleprompter and speech fluency coaching application designed to help you practice presentation and speech clarity.',
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  void _showEditNameDialog() {
    final TextEditingController controller = TextEditingController(text: _userName);
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Edit Profile Name'),
          content: TextField(
            controller: controller,
            decoration: const InputDecoration(
              hintText: 'Enter name',
            ),
            autofocus: true,
            maxLength: 20,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
             ElevatedButton(
              onPressed: () {
                final trimmed = controller.text.trim();
                if (trimmed.isNotEmpty) {
                  setState(() {
                    _userName = trimmed;
                  });
                  _saveUserName(trimmed);
                }
                Navigator.pop(context);
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }
}
