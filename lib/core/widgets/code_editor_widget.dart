import 'package:flutter/material.dart';

import '../services/settings_service.dart';
import '../theme/app_colors.dart';

/// Controller that maintains a fixed uneditable prefix for starter code
/// while applying real-time Python syntax highlighting to user input.
class FixedPrefixCodeController extends TextEditingController {
  final String rawPrefix;
  final TextStyle prefixStyle;
  final TextStyle userTextStyle;

  FixedPrefixCodeController({
    required this.rawPrefix,
    required this.prefixStyle,
    required this.userTextStyle,
    String? text,
  }) : super(text: text ?? rawPrefix);

  @override
  TextSpan buildTextSpan({
    required BuildContext context,
    TextStyle? style,
    required bool withComposing,
  }) {
    if (rawPrefix.isNotEmpty && text.startsWith(rawPrefix)) {
      final userText = text.substring(rawPrefix.length);
      return TextSpan(
        children: [
          TextSpan(text: rawPrefix, style: prefixStyle),
          ..._tokenizePython(userText, userTextStyle),
        ],
      );
    }

    return TextSpan(children: _tokenizePython(text, userTextStyle));
  }

  List<InlineSpan> _tokenizePython(String input, TextStyle baseStyle) {
    if (input.isEmpty) return [];

    final List<InlineSpan> spans = [];

    // Syntax matching regex rules
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
        // Comment (# comment)
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF757575),
          fontStyle: FontStyle.italic,
        );
      } else if (match.group(2) != null) {
        // String ("hello" / 'world')
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF2E7D32),
          fontWeight: FontWeight.bold,
        );
      } else if (match.group(3) != null) {
        // Number (123, 3.14)
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFFD84315),
          fontWeight: FontWeight.bold,
        );
      } else if (match.group(4) != null) {
        // Keyword (def, class, if, return)
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF6A1B9A),
          fontWeight: FontWeight.w900,
        );
      } else if (match.group(5) != null) {
        // Built-in function (print, len, type)
        tokenStyle = baseStyle.copyWith(
          color: const Color(0xFF1565C0),
          fontWeight: FontWeight.w900,
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

/// Neubrutalist code editor widget with dynamic font scaling support.
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
  final SettingsService _settingsService = SettingsService();
  double _fontSize = 14.0;

  @override
  void initState() {
    super.initState();
    _loadFontSize();
  }

  Future<void> _loadFontSize() async {
    final size = await _settingsService.getEditorFontSize();
    if (mounted) {
      setState(() {
        _fontSize = size;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.cardWhite,
      child: TextField(
        controller: widget.controller,
        focusNode: widget.focusNode,
        maxLines: null,
        expands: true,
        keyboardType: TextInputType.multiline,
        autocorrect: false,
        enableSuggestions: false,
        style: TextStyle(
          fontFamily: 'monospace',
          fontSize: _fontSize,
          color: AppColors.borderBlack,
          height: 1.5,
        ),
        decoration: const InputDecoration(
          contentPadding: EdgeInsets.all(12),
          border: InputBorder.none,
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
