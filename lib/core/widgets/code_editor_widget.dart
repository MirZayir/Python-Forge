import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/settings_service.dart';
import '../theme/app_colors.dart';

/// Python syntax highlighting controller for user-typed code.
class PythonCodeController extends TextEditingController {
  final TextStyle userTextStyle;

  PythonCodeController({
    required this.userTextStyle,
    super.text,
  });

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    return TextSpan(children: _tokenizePython(text, userTextStyle));
  }

  List<InlineSpan> _tokenizePython(String input, TextStyle baseStyle) {
    if (input.isEmpty) return [];

    final List<InlineSpan> spans = [];

    final RegExp syntaxPattern = RegExp(
      r'(#.*)|' // Group 1: Comments
      r'(".*?"|'
      "'.*?'"
      r')|' // Group 2: Strings
      r'(\b\d+(?:\.\d+)?\b)|' // Group 3: Numbers
      r'(\b(?:def|class|return|if|elif|else|while|for|in|try|except|import|as|from|break|continue|pass|True|False|None|and|or|not|is)\b)|' // Group 4: Keywords
      r'(\b(?:print|len|type|int|str|float|list|dict|range)\b)', // Group 5: Built-ins
    );

    int lastMatchEnd = 0;

    for (final Match match in syntaxPattern.allMatches(input)) {
      if (match.start > lastMatchEnd) {
        spans.add(TextSpan(
          text: input.substring(lastMatchEnd, match.start),
          style: baseStyle,
        ));
      }

      final String matchedText = match.group(0)!;
      TextStyle tokenStyle = baseStyle;

      if (match.group(1) != null) {
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF757575),
          fontFamily: 'monospace',
        );
      } else if (match.group(2) != null) {
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        );
      } else if (match.group(3) != null) {
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFFD84315),
          fontWeight: FontWeight.bold,
          fontFamily: 'monospace',
        );
      } else if (match.group(4) != null) {
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF6A1B9A),
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        );
      } else if (match.group(5) != null) {
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF1565C0),
          fontWeight: FontWeight.w900,
          fontFamily: 'monospace',
        );
      }

      spans.add(TextSpan(text: matchedText, style: tokenStyle));
      lastMatchEnd = match.end;
    }

    if (lastMatchEnd < input.length) {
      spans.add(TextSpan(
        text: input.substring(lastMatchEnd),
        style: baseStyle,
      ));
    }

    return spans;
  }
}

/// Neubrutalist code editor with horizontal scrolling, translucent placeholder, and synced line numbers.
class CodeEditorWidget extends StatefulWidget {
  final TextEditingController controller;
  final FocusNode focusNode;
  final String? hintText;

  const CodeEditorWidget({
    super.key,
    required this.controller,
    required this.focusNode,
    this.hintText,
  });

  @override
  State<CodeEditorWidget> createState() => _CodeEditorWidgetState();
}

class _CodeEditorWidgetState extends State<CodeEditorWidget> {
  final SettingsService _settingsService = SettingsService();

  double get _fontSize => SettingsService.editorFontSize.value;

  @override
  void initState() {
    super.initState();
    _settingsService.getEditorFontSize();
    SettingsService.editorFontSize.addListener(_onSettingsChange);
    widget.controller.addListener(_onTextChange);
  }

  @override
  void dispose() {
    SettingsService.editorFontSize.removeListener(_onSettingsChange);
    widget.controller.removeListener(_onTextChange);
    super.dispose();
  }

  void _onSettingsChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _onTextChange() {
    if (mounted) {
      setState(() {});
    }
  }

  void _focusEditor() {
    widget.focusNode.requestFocus();
    SystemChannels.textInput.invokeMethod('TextInput.show');
  }

  @override
  Widget build(BuildContext context) {
    final double lineHeight = _fontSize * 1.5;
    final int typedLines = '\n'.allMatches(widget.controller.text).length + 1;
    final int totalGutterLines = math.max(typedLines + 2, 3);

    return GestureDetector(
      onTap: _focusEditor,
      behavior: HitTestBehavior.opaque,
      child: Container(
        color: AppColors.cardWhite,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight,
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Line Numbers Gutter
                    GestureDetector(
                      onTap: _focusEditor,
                      behavior: HitTestBehavior.opaque,
                      child: Container(
                        width: 40,
                        padding: const EdgeInsets.symmetric(vertical: 12.0),
                        decoration: const BoxDecoration(
                          color: AppColors.bgCream,
                          border: Border(
                            right: BorderSide(
                              color: AppColors.borderBlack,
                              width: 2.0,
                            ),
                          ),
                        ),
                        child: Column(
                          children: List.generate(totalGutterLines, (index) {
                            final bool isTypedLine = index < typedLines;
                            return SizedBox(
                              height: lineHeight,
                              child: Center(
                                child: Text(
                                  '${index + 1}',
                                  style: TextStyle(
                                    fontFamily: 'monospace',
                                    fontSize: _fontSize * 0.85,
                                    fontWeight: FontWeight.bold,
                                    color: isTypedLine
                                        ? AppColors.borderBlack
                                        : AppColors.borderBlack
                                            .withValues(alpha: 0.3),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ),
                      ),
                    ),
                    // Non-wrapping Code Text Field with Horizontal Scroll
                    Expanded(
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        physics: const BouncingScrollPhysics(),
                        // A bounded width is required: inside a horizontal
                        // viewport an unbounded TextField makes InputDecorator
                        // assert during layout, which blanks the whole screen.
                        child: SizedBox(
                          width: math.max(
                            constraints.maxWidth - 40,
                            600.0,
                          ),
                          child: TextField(
                            controller: widget.controller,
                            focusNode: widget.focusNode,
                            maxLines: null,
                            keyboardType: TextInputType.multiline,
                            autocorrect: false,
                            enableSuggestions: false,
                            style: TextStyle(
                              fontFamily: 'monospace',
                              fontSize: _fontSize,
                              color: AppColors.borderBlack,
                              fontWeight: FontWeight.bold,
                              height: 1.5,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.hintText,
                              hintMaxLines: 1,
                              hintStyle: TextStyle(
                                fontFamily: 'monospace',
                                fontSize: math.min(_fontSize, 11.0),
                                color: const Color(0xFF757575)
                                    .withValues(alpha: 0.6),
                                height: 1.5,
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 12,
                              ),
                              border: InputBorder.none,
                              isDense: true,
                            ),
                            scrollPhysics: const NeverScrollableScrollPhysics(),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Quick symbol accessory bar shown above soft keyboard during coding missions.
class CodeEditorAccessoryBar extends StatelessWidget {
  final TextEditingController controller;

  const CodeEditorAccessoryBar({
    super.key,
    required this.controller,
  });

  void _insertSymbol(String symbol) {
    final text = controller.text;
    final selection = controller.selection;
    final start = selection.start >= 0 ? selection.start : text.length;
    final end = selection.end >= 0 ? selection.end : text.length;

    final newText = text.replaceRange(start, end, symbol);
    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: start + symbol.length),
    );
  }

  @override
  Widget build(BuildContext context) {
    final symbols = [
      '    ',
      ':',
      '=',
      '()',
      '""',
      "''",
      '[]',
      '{}',
      '+',
      'def ',
      'return ',
      'print()'
    ];

    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.borderBlack, width: 2.0),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowBlack,
            offset: Offset(2, 2),
            blurRadius: 0,
          ),
        ],
      ),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
        itemCount: symbols.length,
        itemBuilder: (context, index) {
          final sym = symbols[index];
          final label = sym == '    ' ? 'TAB' : sym;

          return Padding(
            padding: const EdgeInsets.only(right: 6.0),
            child: GestureDetector(
              onTap: () => _insertSymbol(sym),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10),
                decoration: BoxDecoration(
                  color: AppColors.bgCream,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderBlack, width: 1.5),
                ),
                child: Center(
                  child: Text(
                    label,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                      color: AppColors.borderBlack,
                    ),
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
