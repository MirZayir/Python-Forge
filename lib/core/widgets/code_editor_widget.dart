import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Performance-optimized TextEditingController that locks template starter code
/// as a translucent, non-erasable placeholder and forces cursor to line 2.
class FixedPrefixCodeController extends TextEditingController {
  final String rawPrefix;
  final TextStyle prefixStyle;
  final TextStyle userTextStyle;

  late final String prefix;
  bool _isEnforcing = false;

  FixedPrefixCodeController({
    required this.rawPrefix,
    required this.prefixStyle,
    required this.userTextStyle,
  })  : prefix = rawPrefix.endsWith('\n') ? rawPrefix : '$rawPrefix\n',
        super(text: rawPrefix.endsWith('\n') ? rawPrefix : '$rawPrefix\n') {
    addListener(_enforcePrefix);
  }

  void _enforcePrefix() {
    if (prefix.isEmpty || _isEnforcing) return;

    if (!text.startsWith(prefix)) {
      _isEnforcing = true;
      // If template comment was modified or deleted, restore prefix
      String userPart = '';
      if (text.length > prefix.length) {
        userPart = text.substring(text.length - (text.length - prefix.length));
      }
      value = TextEditingValue(
        text: prefix + userPart,
        selection:
            TextSelection.collapsed(offset: prefix.length + userPart.length),
      );
      _isEnforcing = false;
    } else if (selection.start < prefix.length ||
        selection.end < prefix.length) {
      // Lock cursor position to after the template prefix (Line 2)
      final newStart =
          selection.start < prefix.length ? prefix.length : selection.start;
      final newEnd =
          selection.end < prefix.length ? prefix.length : selection.end;
      _isEnforcing = true;
      selection = TextSelection(baseOffset: newStart, extentOffset: newEnd);
      _isEnforcing = false;
    }
  }

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (prefix.isEmpty || !text.startsWith(prefix)) {
      return TextSpan(text: text, style: userTextStyle);
    }

    final userPart = text.substring(prefix.length);

    return TextSpan(
      children: [
        TextSpan(text: prefix, style: prefixStyle),
        TextSpan(text: userPart, style: userTextStyle),
      ],
    );
  }
}

/// Interactive code editor with line numbering gutter and predictive typing enabled.
class CodeEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;

  const CodeEditorWidget({
    super.key,
    required this.controller,
    required this.focusNode,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, child) {
        final text = widget.controller.text;
        final lineCount = text.split('\n').length;
        // Always display at least 3 lines, and keep 1 extra line ready ahead
        final displayLineCount = (lineCount + 1) < 3 ? 3 : (lineCount + 1);

        return Container(
          color: const Color(0xFF181A20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Line Number Gutter
              Container(
                width: 38,
                padding: const EdgeInsets.only(
                    top: 12.0, bottom: 12.0, left: 6.0, right: 8.0),
                decoration: BoxDecoration(
                  color: const Color(0xFF14151A),
                  border: Border(
                    right: BorderSide(
                      color: Colors.white.withValues(alpha: 0.08),
                      width: 1.0,
                    ),
                  ),
                ),
                child: AnimatedBuilder(
                  animation: _scrollController,
                  builder: (context, _) {
                    final double offset = _scrollController.hasClients
                        ? _scrollController.offset
                        : 0.0;
                    return Transform.translate(
                      offset: Offset(0, -offset),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: List.generate(displayLineCount, (index) {
                          final lineNumber = index + 1;
                          final isStarterLine = index == 0;
                          return SizedBox(
                            height:
                                21.0, // Matches 14.0 * 1.5 line height of text editor
                            child: Text(
                              '$lineNumber',
                              style: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: 12.0,
                                fontWeight: FontWeight.w600,
                                color: isStarterLine
                                    ? Colors.white.withValues(alpha: 0.25)
                                    : Colors.white.withValues(alpha: 0.5),
                              ),
                            ),
                          );
                        }),
                      ),
                    );
                  },
                ),
              ),

              // Code Text Input Field
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: TextField(
                    controller: widget.controller,
                    focusNode: widget.focusNode,
                    scrollController: _scrollController,
                    maxLines: null,
                    expands: true,
                    keyboardType: TextInputType.multiline,
                    textInputAction: TextInputAction.newline,
                    enableSuggestions: true,
                    autocorrect: true,
                    style: AppTypography.code.copyWith(
                      color: Colors.white,
                      fontSize: 14.0,
                      height: 1.5,
                    ),
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      errorBorder: InputBorder.none,
                      disabledBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                      hintText: 'Write your Python code here...',
                      hintStyle: TextStyle(color: AppColors.syntaxGrey),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

/// Accessory toolbar pinned above the keyboard for typing special programming symbols.
class CodeEditorAccessoryBar extends StatelessWidget {
  final TextEditingController controller;

  const CodeEditorAccessoryBar({super.key, required this.controller});

  void _insertText(String text) {
    final selection = controller.selection;
    final currentText = controller.text;

    if (selection.isValid) {
      final newText = currentText.replaceRange(
        selection.start,
        selection.end,
        text,
      );
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(
          offset: selection.start + text.length,
        ),
      );
    } else {
      controller.text += text;
    }
  }

  @override
  Widget build(BuildContext context) {
    final symbols = ['Tab', '()', '[]', '{}', ':', '=', '"', "'", '_', '+'];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: const Color(0xFF1E2026),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
      ),
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        itemCount: symbols.length,
        separatorBuilder: (context, index) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final symbol = symbols[index];
          return InkWell(
            onTap: () {
              if (symbol == 'Tab') {
                _insertText('    ');
              } else {
                _insertText(symbol);
              }
            },
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text(
                  symbol,
                  style: AppTypography.code.copyWith(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
