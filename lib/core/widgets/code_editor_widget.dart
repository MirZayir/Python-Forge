import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A reusable, professional code editor widget with line numbers and Python auto-indent.
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
  late final ScrollController _editorScrollController;
  late final ScrollController _gutterScrollController;

  int _lineCount = 1;
  int _currentLine = 1;

  @override
  void initState() {
    super.initState();
    _editorScrollController = ScrollController();
    _gutterScrollController = ScrollController();

    widget.controller.addListener(_onTextChanged);
    _editorScrollController.addListener(_syncScroll);

    // Initialize line count and active line
    _onTextChanged();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _editorScrollController.removeListener(_syncScroll);

    _editorScrollController.dispose();
    _gutterScrollController.dispose();
    super.dispose();
  }

  void _syncScroll() {
    if (_editorScrollController.hasClients &&
        _gutterScrollController.hasClients) {
      _gutterScrollController.jumpTo(_editorScrollController.offset);
    }
  }

  void _onTextChanged() {
    final text = widget.controller.text;
    final lines = '\n'.allMatches(text).length + 1;

    final selection = widget.controller.selection;
    int current = 1;
    if (selection.isValid &&
        selection.baseOffset >= 0 &&
        selection.baseOffset <= text.length) {
      final textBeforeCursor = text.substring(0, selection.baseOffset);
      current = '\n'.allMatches(textBeforeCursor).length + 1;
    }

    if (_lineCount != lines || _currentLine != current) {
      setState(() {
        _lineCount = lines;
        _currentLine = current;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.crucibleGrey,
        borderRadius: BorderRadius.circular(AppRadius.medium),
        border: Border.all(
          color: AppColors.syntaxGrey.withValues(alpha: 0.3),
          width: 1.0,
        ),
      ),
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Background Layer: Gutter and Current Line Highlight
          ListView.builder(
            controller: _gutterScrollController,
            padding: EdgeInsets.zero,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _lineCount,
            itemBuilder: (context, index) {
              final lineNumber = index + 1;
              final isCurrent = lineNumber == _currentLine;

              return Row(
                children: [
                  // Gutter
                  Container(
                    width: 48.0,
                    height: 24.0, // Fixed height per line
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isCurrent
                          ? AppColors.obsidian.withValues(alpha: 0.3)
                          : Colors.transparent,
                      border: Border(
                        left: BorderSide(
                          color: isCurrent
                              ? AppColors.logicCyan
                              : Colors.transparent,
                          width: 2.0,
                        ),
                      ),
                    ),
                    child: Text(
                      '$lineNumber',
                      style: AppTypography.code.copyWith(
                        color: isCurrent
                            ? AppColors.logicCyan
                            : AppColors.syntaxGrey,
                        fontSize: 14.0,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),
                  // Active Line Background Highlight
                  Expanded(
                    child: Container(
                      height: 24.0,
                      color: isCurrent
                          ? AppColors.forgeEmber.withValues(alpha: 0.1)
                          : Colors.transparent,
                    ),
                  ),
                ],
              );
            },
          ),

          // Foreground Layer: Text Editor
          Positioned(
            left: 48.0 + AppSpacing.small,
            top: 0,
            bottom: 0,
            right: 0,
            child: TextField(
              controller: widget.controller,
              scrollController: _editorScrollController,
              focusNode: widget.focusNode,
              maxLines: null,
              expands: true,
              keyboardType: TextInputType.multiline,
              autocorrect: false,
              enableSuggestions: false,
              textCapitalization: TextCapitalization.none,
              inputFormatters: [
                _PythonIndentFormatter(),
              ],
              style: AppTypography.code.copyWith(
                color: Colors.white,
                fontSize: 14.0,
                height: 24.0 / 14.0, // Aligns with 24.0 height in gutter
              ),
              cursorColor: AppColors.forgeEmber,
              decoration: const InputDecoration(
                border: InputBorder.none,
                contentPadding: EdgeInsets.only(right: AppSpacing.medium),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// The horizontal accessory bar docked directly above the system keyboard.
class CodeEditorAccessoryBar extends StatelessWidget {
  final TextEditingController controller;

  const CodeEditorAccessoryBar({super.key, required this.controller});

  void _insertText(String text, {int offset = 0}) {
    HapticFeedback.lightImpact();

    final int start = controller.selection.baseOffset;
    final int end = controller.selection.extentOffset;

    if (start < 0 || end < 0) {
      controller.text += text;
      controller.selection = TextSelection.collapsed(
        offset: controller.text.length - offset,
      );
      return;
    }

    final int realStart = start < end ? start : end;
    final int realEnd = start < end ? end : start;
    final String currentText = controller.text;

    final String newText = currentText.substring(0, realStart) +
        text +
        currentText.substring(realEnd);

    controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(
        offset: realStart + text.length - offset,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48.0,
      width: double.infinity,
      decoration: const BoxDecoration(
        color: AppColors.crucibleGrey,
        borderRadius: BorderRadius.all(Radius.circular(AppRadius.medium)),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
        children: [
          _AccessoryKey(label: 'Tab', onTap: () => _insertText('    ')),
          _AccessoryKey(label: '()', onTap: () => _insertText('()', offset: 1)),
          _AccessoryKey(label: '[]', onTap: () => _insertText('[]', offset: 1)),
          _AccessoryKey(label: '{}', onTap: () => _insertText('{}', offset: 1)),
          _AccessoryKey(label: ':', onTap: () => _insertText(':')),
          _AccessoryKey(label: '=', onTap: () => _insertText(' = ')),
          _AccessoryKey(label: '"', onTap: () => _insertText('""', offset: 1)),
          _AccessoryKey(label: "'", onTap: () => _insertText("''", offset: 1)),
          _AccessoryKey(label: ',', onTap: () => _insertText(', ')),
          _AccessoryKey(label: '.', onTap: () => _insertText('.')),
        ],
      ),
    );
  }
}

/// A tactile button representing a single key in the accessory bar.
class _AccessoryKey extends StatelessWidget {
  final String label;
  final VoidCallback onTap;

  const _AccessoryKey({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 4.0,
        vertical: 6.0,
      ),
      child: Material(
        color: AppColors.obsidian,
        borderRadius: BorderRadius.circular(AppRadius.small),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppRadius.small),
          child: Container(
            constraints: const BoxConstraints(minWidth: 40.0),
            padding: const EdgeInsets.symmetric(horizontal: 12.0),
            alignment: Alignment.center,
            child: Text(
              label,
              style: AppTypography.code.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Custom formatter that automatically applies Python indentation rules.
class _PythonIndentFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    if (newValue.text.length - oldValue.text.length == 1) {
      final int newOffset = newValue.selection.baseOffset;

      if (newOffset > 0 && newValue.text[newOffset - 1] == '\n') {
        final String textBeforeNewline =
            newValue.text.substring(0, newOffset - 1);
        final String lastLine = textBeforeNewline.split('\n').last;

        if (lastLine.trimRight().endsWith(':')) {
          final String existingIndent =
              RegExp(r'^\s*').firstMatch(lastLine)?.group(0) ?? '';
          final String insertString = '$existingIndent    ';

          final String newText =
              newValue.text.replaceRange(newOffset, newOffset, insertString);
          return TextEditingValue(
            text: newText,
            selection: TextSelection.collapsed(
                offset: newOffset + insertString.length),
          );
        } else {
          final String existingIndent =
              RegExp(r'^\s*').firstMatch(lastLine)?.group(0) ?? '';
          if (existingIndent.isNotEmpty) {
            final String newText = newValue.text
                .replaceRange(newOffset, newOffset, existingIndent);
            return TextEditingValue(
              text: newText,
              selection: TextSelection.collapsed(
                  offset: newOffset + existingIndent.length),
            );
          }
        }
      }
    }
    return newValue;
  }
}
