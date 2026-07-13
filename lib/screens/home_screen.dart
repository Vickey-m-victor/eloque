import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/lesson_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/progress_provider.dart';
import '../models/lesson.dart';
import '../widgets/lesson_card.dart';
import 'teleprompter_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkFirstRun();
    });
  }

  Future<void> _checkFirstRun() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
      if (!hasSeenOnboarding) {
        _showOnboardingDialog();
      }
    } catch (e) {
      debugPrint('Error checking onboarding: $e');
    }
  }

  void _showOnboardingDialog() {
    final TextEditingController controller = TextEditingController();
    final progressProvider = Provider.of<ProgressProvider>(context, listen: false);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final theme = Theme.of(context);
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          title: Row(
            children: [
              Icon(Icons.waving_hand_rounded, color: theme.colorScheme.primary),
              const SizedBox(width: 10),
              const Text('Welcome to Eloque!'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Let\'s customize your speech training. What is your name?',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                decoration: InputDecoration(
                  labelText: 'Your Name',
                  hintText: 'e.g., Alex',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  prefixIcon: const Icon(Icons.person_outline_rounded),
                ),
                textCapitalization: TextCapitalization.words,
                maxLength: 20,
                autofocus: true,
              ),
            ],
          ),
          actions: [
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () async {
                final name = controller.text.trim();
                final displayName = name.isNotEmpty ? name : 'Speaker';
                await progressProvider.updateUserName(displayName);
                
                try {
                  final prefs = await SharedPreferences.getInstance();
                  await prefs.setBool('has_seen_onboarding', true);
                } catch (e) {
                  debugPrint('Error saving onboarding flag: $e');
                }
                
                if (mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Welcome, $displayName! Let\'s level up your speaking.'),
                      behavior: SnackBarBehavior.floating,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  );
                }
              },
              child: const Text('Get Started'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final themeProvider = Provider.of<ThemeProvider>(context);
    final progressProvider = Provider.of<ProgressProvider>(context);

    // Get a couple of lessons for the Home screen suggestions
    final featuredLessons = lessonProvider.allLessons.take(2).toList();

    // Define a special Daily Challenge lesson object
    final dailyChallengeLesson = Lesson(
      id: 'challenge_day_1',
      title: 'Daily Challenge: The Power of Perseverance',
      description:
          'Practice this motivational message by Vincent van Gogh to improve your vocal projection and emotional resonance.',
      category: 'Inspirational Quotes',
      difficulty: 'Intermediate',
      estimatedMinutes: 1,
      content:
          'Great things are not done by impulse, but by a series of small things brought together. (Pause) Everyday, we take tiny steps. Each word we pronounce correctly, each phrase we practice with confidence, builds towards our fluency. Do not be discouraged by slow progress. Keep moving forward, keep speaking, and trust the process. You are getting better every single day.',
      track: LessonTrack.conversational,
    );

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.waves_rounded,
                color: theme.colorScheme.primary,
                size: 24,
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Eloque',
              style: theme.textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              themeProvider.isDarkMode
                  ? Icons.light_mode_rounded
                  : Icons.dark_mode_rounded,
              color: theme.colorScheme.onBackground,
            ),
            onPressed: () {
              themeProvider.toggleTheme();
            },
            tooltip: 'Toggle Theme',
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Greeting Section
              Text(
                'Welcome back, ${progressProvider.userName}! 👋',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Ready to level up your English speaking skills today?',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onBackground.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 24),

              // Statistics Section
              Row(
                children: [
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Streak',
                      value: '${progressProvider.streakDays} days',
                      icon: Icons.local_fire_department_rounded,
                      iconColor: const Color(0xFFFB923C), // Warm Orange
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Practice Time',
                      value: '${progressProvider.totalPracticeMinutes} mins',
                      icon: Icons.schedule_rounded,
                      iconColor: const Color(0xFF06B6D4), // Cyan
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildStatCard(
                      context,
                      title: 'Avg. Fluency',
                      value: '${progressProvider.averageFluencyScore}%',
                      icon: Icons.insights_rounded,
                      iconColor: const Color(0xFF10B981), // Emerald
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 28),

              // Daily Challenge Section
              Text(
                'Daily Challenge',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      theme.colorScheme.primary,
                      theme.colorScheme.secondary,
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withOpacity(0.3),
                      blurRadius: 16,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(24),
                  child: InkWell(
                    onTap: () {
                      lessonProvider.selectLesson(dailyChallengeLesson);
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const TeleprompterScreen(),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text(
                                  'CHALLENGE',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.0,
                                  ),
                                ),
                              ),
                              const Icon(
                                Icons.star_rounded,
                                color: Colors.amber,
                                size: 24,
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            '"Great things are not done by impulse, but by a series of small things..."',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontStyle: FontStyle.italic,
                              fontWeight: FontWeight.w600,
                              height: 1.4,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Vincent van Gogh',
                                style: TextStyle(
                                  color: Colors.white.withOpacity(0.8),
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Row(
                                children: const [
                                  Text(
                                    'Practice Now',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  SizedBox(width: 4),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    color: Colors.white,
                                    size: 16,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // Recommended Lessons Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recommended Lessons',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ...featuredLessons.map((lesson) {
                return LessonCard(
                  lesson: lesson,
                  onTap: () {
                    lessonProvider.selectLesson(lesson);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const TeleprompterScreen(),
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatCard(
    BuildContext context, {
    required String title,
    required String value,
    required IconData icon,
    required Color iconColor,
  }) {
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.onBackground.withOpacity(0.08),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onBackground.withOpacity(0.5),
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
