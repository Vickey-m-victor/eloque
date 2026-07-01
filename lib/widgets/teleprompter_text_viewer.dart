import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/teleprompter_provider.dart';

class TeleprompterTextViewer extends StatefulWidget {
  const TeleprompterTextViewer({super.key});

  @override
  State<TeleprompterTextViewer> createState() => _TeleprompterTextViewerState();
}

class _TeleprompterTextViewerState extends State<TeleprompterTextViewer> {
  final ScrollController _scrollController = ScrollController();
  late List<GlobalKey> _keys;
  int _lastIndex = -1;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<TeleprompterProvider>(context, listen: false);
    _keys = List.generate(provider.sentences.length, (_) => GlobalKey());
  }

  void _scrollToActive(int index) {
    if (index < 0 || index >= _keys.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final targetContext = _keys[index].currentContext;
      if (targetContext != null) {
        Scrollable.ensureVisible(
          targetContext,
          alignment: 0.35, // Align with the guide lines at 35% viewport height
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<TeleprompterProvider>(context);
    final theme = Theme.of(context);

    // Sync keys length in case sentences updated
    if (_keys.length != provider.sentences.length) {
      _keys = List.generate(provider.sentences.length, (_) => GlobalKey());
      _lastIndex = -1; // reset trigger
    }

    if (provider.activeSentenceIndex != _lastIndex) {
      _lastIndex = provider.activeSentenceIndex;
      _scrollToActive(_lastIndex);
    }

    return ListView.builder(
      controller: _scrollController,
      // Huge padding on top/bottom so first/last sentence can be centered on screen
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: MediaQuery.of(context).size.height * 0.35,
      ),
      itemCount: provider.sentences.length,
      itemBuilder: (context, index) {
        final sentence = provider.sentences[index];
        final isActive = index == provider.activeSentenceIndex;
        final isPassed = index < provider.activeSentenceIndex;

        // Custom fading levels for premium visual hierarchy
        double textOpacity = 0.35;
        if (isActive) {
          textOpacity = 1.0;
        } else if (isPassed) {
          textOpacity = 0.18; // Preceding read text is dimmer
        }

        // Use electric cyan/violet accent for highlighted text
        final Color textColor = isActive
            ? theme.colorScheme.primary
            : theme.colorScheme.onBackground.withOpacity(textOpacity);

        final FontWeight fontWeight = isActive ? FontWeight.w800 : FontWeight.w500;

        return GestureDetector(
          key: _keys[index],
          onTap: () {
            // Tapping a sentence jumps to it manually
            provider.jumpToSentence(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
            margin: const EdgeInsets.symmetric(vertical: 2),
            decoration: BoxDecoration(
              color: isActive 
                  ? theme.colorScheme.primary.withOpacity(0.08) 
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              sentence,
              textAlign: provider.textAlign,
              style: TextStyle(
                fontSize: provider.fontSize,
                fontWeight: fontWeight,
                color: textColor,
                height: 1.5,
              ),
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
