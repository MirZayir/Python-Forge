import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_button.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';

/// Milestone 1 - Phase 1: Editor Skeleton (Line Number Gutter).
/// A structural UI layout for the interactive learning environment.
class MissionScreen extends StatefulWidget {
  final Mission mission;

  const MissionScreen({super.key, required this.mission});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  late final TextEditingController _codeController;
  late final ScrollController _editorScrollController;
  late final ScrollController _gutterScrollController;

  static const platform = MethodChannel('python_forge/native');

  String _outputText = 'Ready to execute...';
  bool _isRunning = false;

  int _lineCount = 1;
  int _currentLine = 1;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: 'print("Hello, World!")');
    _editorScrollController = ScrollController();
    _gutterScrollController = ScrollController();

    _codeController.addListener(_onTextChanged);
    _editorScrollController.addListener(_syncScroll);

    // Initialize line count and active line
    _onTextChanged();
  }

  @override
  void dispose() {
    _codeController.removeListener(_onTextChanged);
    _editorScrollController.removeListener(_syncScroll);

    _codeController.dispose();
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
    final text = _codeController.text;
    final lines = '\n'.allMatches(text).length + 1;

    final selection = _codeController.selection;
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

  Future<void> _runCode() async {
    if (_isRunning) return;

    setState(() {
      _isRunning = true;
      _outputText = 'Running...';
    });

    try {
      // Invoke the native MethodChannel
      final String result = await platform.invokeMethod('getNativeMessage');

      if (!mounted) return;

      setState(() {
        _isRunning = false;
        _outputText = result;
      });
    } on PlatformException catch (e) {
      if (!mounted) return;

      setState(() {
        _isRunning = false;
        _outputText =
            "Failed to communicate with native layer: '${e.message}'.";
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => context.pop(),
        ),
        title: Text(
          '${widget.mission.numberLabel}: ${widget.mission.title}',
          style: AppTypography.title.copyWith(color: Colors.white),
        ),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Mission Objective
          ForgeCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Objective',
                  style: AppTypography.body.copyWith(
                    color: AppColors.logicCyan,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: AppSpacing.micro),
                Text(
                  widget.mission.objective,
                  style: AppTypography.body.copyWith(color: Colors.white),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Code Editor Container
          Expanded(
            flex: 3,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.crucibleGrey,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: AppColors.syntaxGrey.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.symmetric(vertical: AppSpacing.medium),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Line Number Gutter
                  Container(
                    width: 48.0,
                    color: AppColors.crucibleGrey,
                    child: ListView.builder(
                      controller: _gutterScrollController,
                      padding: EdgeInsets.zero,
                      physics:
                          const NeverScrollableScrollPhysics(), // Managed by _syncScroll
                      itemCount: _lineCount,
                      itemBuilder: (context, index) {
                        final lineNumber = index + 1;
                        final isCurrent = lineNumber == _currentLine;

                        return Container(
                          height: 24.0, // Fixed height per line
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isCurrent
                                ? AppColors.obsidian.withOpacity(0.3)
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
                        );
                      },
                    ),
                  ),
                  const SizedBox(width: AppSpacing.small),

                  // Text Editor
                  Expanded(
                    child: TextField(
                      controller: _codeController,
                      scrollController: _editorScrollController,
                      maxLines: null,
                      expands: true,
                      keyboardType: TextInputType.multiline,
                      autocorrect: false,
                      enableSuggestions: false,
                      textCapitalization: TextCapitalization.none,
                      style: AppTypography.code.copyWith(
                        color: Colors.white,
                        fontSize: 14.0,
                        height: 24.0 /
                            14.0, // Perfectly aligns with 24.0 height in gutter
                      ),
                      cursorColor: AppColors.forgeEmber,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        contentPadding:
                            EdgeInsets.only(right: AppSpacing.medium),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.medium),

          // Output Console Container
          Expanded(
            flex: 2,
            child: Container(
              decoration: BoxDecoration(
                color: AppColors.obsidian,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: AppColors.syntaxGrey.withOpacity(0.3),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Output',
                    style: AppTypography.body.copyWith(
                      color: AppColors.syntaxGrey,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Expanded(
                    child: SingleChildScrollView(
                      child: Text(
                        _outputText,
                        style: AppTypography.code.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.large),

          // Primary Run Button
          ForgeButton(
            label: _isRunning ? 'Running...' : 'Run Code',
            icon: _isRunning
                ? null
                : const Icon(
                    Icons.play_arrow_rounded,
                    color: AppColors.obsidian,
                  ),
            onPressed: _isRunning ? null : _runCode,
          ),
        ],
      ),
    );
  }
}
