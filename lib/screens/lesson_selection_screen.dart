import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/lesson_provider.dart';
import '../widgets/lesson_card.dart';
import '../models/lesson.dart';
import 'teleprompter_screen.dart';

class LessonSelectionScreen extends StatelessWidget {
  const LessonSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final lessonProvider = Provider.of<LessonProvider>(context);
    final lessons = lessonProvider.lessons;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Practice Library',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Track Selector
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12, bottom: 8),
              child: Text(
                'Practice Track',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  _buildTrackButton(
                    theme,
                    label: 'Conversational',
                    icon: Icons.chat_bubble_outline_rounded,
                    selected: lessonProvider.selectedTrack == LessonTrack.conversational,
                    onTap: () {
                      if (lessonProvider.selectedTrack == LessonTrack.conversational) {
                        lessonProvider.selectTrack(null);
                      } else {
                        lessonProvider.selectTrack(LessonTrack.conversational);
                      }
                    },
                  ),
                  const SizedBox(width: 12),
                  _buildTrackButton(
                    theme,
                    label: 'Interview Prep',
                    icon: Icons.work_outline_rounded,
                    selected: lessonProvider.selectedTrack == LessonTrack.interviewPrep,
                    onTap: () {
                      if (lessonProvider.selectedTrack == LessonTrack.interviewPrep) {
                        lessonProvider.selectTrack(null);
                      } else {
                        lessonProvider.selectTrack(LessonTrack.interviewPrep);
                      }
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            // Category Selector
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
              child: Text(
                'Category',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: lessonProvider.categories.length,
                itemBuilder: (context, index) {
                  final category = lessonProvider.categories[index];
                  final isSelected = lessonProvider.selectedCategory == category;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(category),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          lessonProvider.selectCategory(category);
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : theme.colorScheme.onBackground,
                      ),
                    ),
                  );
                },
              ),
            ),

            // Difficulty Selector
            Padding(
              padding: const EdgeInsets.only(left: 20, top: 12, bottom: 4),
              child: Text(
                'Difficulty',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            SizedBox(
              height: 52,
              child: ListView.builder(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                scrollDirection: Axis.horizontal,
                itemCount: lessonProvider.difficulties.length,
                itemBuilder: (context, index) {
                  final difficulty = lessonProvider.difficulties[index];
                  final isSelected = lessonProvider.selectedDifficulty == difficulty;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: ChoiceChip(
                      label: Text(difficulty),
                      selected: isSelected,
                      onSelected: (selected) {
                        if (selected) {
                          lessonProvider.selectDifficulty(difficulty);
                        }
                      },
                      selectedColor: theme.colorScheme.primary,
                      labelStyle: TextStyle(
                        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        color: isSelected ? Colors.white : theme.colorScheme.onBackground,
                      ),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Lessons List
            Expanded(
              child: lessons.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.search_off_rounded,
                            size: 64,
                            color: theme.colorScheme.onBackground.withOpacity(0.3),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No lessons match the criteria',
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: theme.colorScheme.onBackground.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Try changing category or difficulty filters.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onBackground.withOpacity(0.4),
                            ),
                          ),
                        ],
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      itemCount: lessons.length,
                      itemBuilder: (context, index) {
                        final lesson = lessons[index];
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
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrackButton(
    ThemeData theme, {
    required String label,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: selected ? theme.colorScheme.primary : theme.colorScheme.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                color: selected ? Colors.white : theme.colorScheme.onBackground,
                size: 18,
              ),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : theme.colorScheme.onBackground,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
