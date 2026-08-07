import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// A professional code editor featuring line numbers and monospace typography.
class ForgeCodeEditor extends StatefulWidget {
  final TextEditingController controller;

  const ForgeCodeEditor({super.key, required this.controller});

  @override
  State<ForgeCodeEditor> createState() => _ForgeCodeEditorState();
}

class _ForgeCodeEditorState extends State<ForgeCodeEditor> {
  int _lineCount = 1;

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_updateLineCount);
    _updateLineCount();
  }

  @override
  void dispose() {
    widget.controller.removeListener(_updateLineCount);
    super.dispose();
  }

  void _updateLineCount() {
    final count = '\n'.allMatches(widget.controller.text).length + 1;
    if (count != _lineCount) {
      setState(() {
        _lineCount = count;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.obsidian,
      child: SingleChildScrollView(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Line Numbers Gutter
            Container(
              width: 48,
              padding: const EdgeInsets.symmetric(vertical: 16.0),
              color: AppColors.crucibleGrey.withValues(alpha: 0.3),
              child: Column(
                children: List.generate(_lineCount, (index) {
                  return SizedBox(
                    height: 24.0, // Fixed physical line height
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: AppTypography.code.copyWith(
                          color: AppColors.syntaxGrey,
                          fontSize: 14.0,
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),
            // The Code Editor
            Expanded(
              child: TextField(
                controller: widget.controller,
                maxLines: null,
                keyboardType: TextInputType.multiline,
                autocorrect: false,
                enableSuggestions: false,
                textCapitalization: TextCapitalization.none,
                style: AppTypography.code.copyWith(
                  color: Colors.white,
                  fontSize: 14.0,
                  height:
                      24.0 / 14.0, // Aligns perfectly with line number height
                ),
                cursorColor: AppColors.forgeEmber,
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(
                    vertical: 16.0,
                    horizontal: 16.0,
                  ),
                  isDense: true,
                ),
                // Disable internal scrolling so the parent SingleChildScrollView
                // perfectly syncs the text and the line numbers.
                scrollPhysics: const NeverScrollableScrollPhysics(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// The tactile accessory bar pinned above the keyboard.
class EditorAccessoryBar extends StatelessWidget {
  final TextEditingController controller;

  const EditorAccessoryBar({super.key, required this.controller});

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
        border: Border(
          top: BorderSide(color: AppColors.obsidian, width: 1.0),
        ),
      ),
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppSpacing.small),
        children: [
          _AccessoryKey(label: 'Tab', onTap: () => _insertText('    ')),
          _AccessoryKey(label: '()', onTap: () => _insertText('()', offset: 1)),
          _AccessoryKey(label: '[]', onTap: () => _insertText('[]', offset: 1)),
          _AccessoryKey(label: ':', onTap: () => _insertText(':')),
          _AccessoryKey(label: '=', onTap: () => _insertText(' = ')),
          _AccessoryKey(label: '""', onTap: () => _insertText('""', offset: 1)),
          _AccessoryKey(label: "''", onTap: () => _insertText("''", offset: 1)),
        ],
      ),
    );
  }
}

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
