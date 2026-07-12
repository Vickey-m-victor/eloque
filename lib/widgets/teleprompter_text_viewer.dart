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
          alignment: 0.42,
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
    final mediaQuery = MediaQuery.of(context);
    final maxContentWidth = mediaQuery.size.width - 48;

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
      // Extra padding so the active sentence can sit inside the center spotlight.
      padding: EdgeInsets.symmetric(
        horizontal: 24,
        vertical: MediaQuery.of(context).size.height * 0.28,
      ),
      itemCount: provider.sentences.length,
      itemBuilder: (context, index) {
        final sentence = provider.sentences[index];
        final isActive = index == provider.activeSentenceIndex;
        final isPassed = index < provider.activeSentenceIndex;
        final effectiveFontSize = isActive
            ? _getAdaptiveFontSize(
                sentence,
                provider.fontSize,
                maxContentWidth,
                provider.textAlign,
              )
            : provider.fontSize;

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

        final FontWeight fontWeight = isActive
            ? FontWeight.w800
            : FontWeight.w500;

        return GestureDetector(
          key: _keys[index],
          onTap: () {
            // Tapping a sentence jumps to it manually
            provider.jumpToSentence(index);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            margin: EdgeInsets.symmetric(
              vertical: isActive ? 12 : 4,
              horizontal: isActive ? 0 : 8,
            ),
            padding: EdgeInsets.symmetric(
              vertical: isActive ? 18 : 10,
              horizontal: isActive ? 22 : 12,
            ),
            decoration: BoxDecoration(
              color: isActive
                  ? theme.colorScheme.primary.withOpacity(0.14)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(isActive ? 28 : 16),
              border: isActive
                  ? Border.all(
                      color: theme.colorScheme.primary.withOpacity(0.18),
                      width: 1,
                    )
                  : null,
              boxShadow: isActive
                  ? [
                      BoxShadow(
                        color: theme.colorScheme.primary.withOpacity(0.12),
                        blurRadius: 24,
                        offset: const Offset(0, 8),
                      ),
                    ]
                  : null,
            ),
            child: AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 250),
              style: TextStyle(
                fontSize: isActive ? effectiveFontSize + 2 : effectiveFontSize,
                fontWeight: fontWeight,
                color: textColor,
                height: isActive ? 1.22 : 1.45,
              ),
              child: Text(
                sentence,
                textAlign: isActive ? TextAlign.center : provider.textAlign,
                maxLines: isActive ? 4 : 3,
                overflow: TextOverflow.ellipsis,
                softWrap: true,
              ),
            ),
          ),
        );
      },
    );
  }

  double _getAdaptiveFontSize(
    String sentence,
    double baseFontSize,
    double maxWidth,
    TextAlign alignment,
  ) {
    final words = sentence
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .length;
    final longSentencePenalty = words > 12 ? (words - 12) * 0.7 : 0.0;
    final widthPenalty = maxWidth < 460 ? (460 - maxWidth) * 0.09 : 0.0;
    final alignmentBonus =
        alignment == TextAlign.left || alignment == TextAlign.right
        ? 0.75
        : 0.0;

    return (baseFontSize - longSentencePenalty - widthPenalty + alignmentBonus)
        .clamp(17.0, baseFontSize);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
