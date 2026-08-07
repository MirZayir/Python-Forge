import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/execution/execution_manager.dart';
import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/xp_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/validation/answer_validator.dart';
import '../../../../core/widgets/code_editor_widget.dart';
import '../../../../core/widgets/forge_button.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';

/// Milestone 1 - Phase 1: Editor Skeleton (Premium UI Redesign).
/// A robust, modern, and visually polished layout for the interactive learning environment.
class MissionScreen extends StatefulWidget {
  final Mission mission;

  const MissionScreen({super.key, required this.mission});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  late final TextEditingController _codeController;
  late final FocusNode _editorFocusNode;

  final ExecutionManager _executionManager = ExecutionManager();
  final ProgressManager _progressManager = ProgressManager();
  final AchievementEngine _achievementEngine = AchievementEngine();

  String _outputText = 'Ready to execute...';
  bool _isRunning = false;

  @override
  void initState() {
    super.initState();
    _codeController = TextEditingController(text: widget.mission.starterCode);
    _editorFocusNode = FocusNode();

    _editorFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _editorFocusNode.removeListener(_onFocusChanged);
    _codeController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    setState(() {});
  }

  Future<void> _runCode() async {
    if (_isRunning) return;

    _editorFocusNode.unfocus();

    setState(() {
      _isRunning = true;
      _outputText = '> Running...';
    });

    final executionResult =
        await _executionManager.execute(_codeController.text);

    if (!mounted) return;

    final isCorrect =
        AnswerValidator.validate(_codeController.text, widget.mission);

    setState(() {
      _isRunning = false;
      if (isCorrect) {
        _outputText = '${executionResult.output}\n\n✅ Mission Complete!';
      } else {
        _outputText = '${executionResult.output}\n\n❌ Not quite.\nTry again.';
      }
    });

    if (isCorrect) {
      await _progressManager.completeMission(widget.mission.id);
      final newlyUnlocked = await _achievementEngine.evaluateAndUnlock();

      if (!mounted) return;

      _showCompletionDialog();

      for (final achievement in newlyUnlocked) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '🏆 Achievement Unlocked!\n${achievement.title}',
              style: AppTypography.body.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.obsidian,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppRadius.medium),
              side: BorderSide(
                color: AppColors.temperGreen.withOpacity(0.5),
                width: 1.0,
              ),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  void _showHint() {
    if (widget.mission.hints.isEmpty) return;

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.obsidian,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            side: BorderSide(
              color: AppColors.logicCyan.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb, color: AppColors.forgeEmber),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      'Mission Hint',
                      style: AppTypography.title.copyWith(color: Colors.white),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  widget.mission.hints.first,
                  style:
                      AppTypography.body.copyWith(color: AppColors.syntaxGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                ForgeButton(
                  label: 'Got it',
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog() {
    final xpReward = XpManager.rewardFor(widget.mission);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.obsidian,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            side: BorderSide(
              color: AppColors.forgeEmber.withOpacity(0.5),
              width: 1.0,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎉 Mission Complete!',
                  style: AppTypography.title.copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Great job completing this challenge.',
                  style:
                      AppTypography.body.copyWith(color: AppColors.syntaxGrey),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.temperGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppRadius.small),
                    border: Border.all(
                      color: AppColors.temperGreen.withOpacity(0.5),
                    ),
                  ),
                  child: Text(
                    '+$xpReward XP',
                    style: AppTypography.code.copyWith(
                      color: AppColors.temperGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 18.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                ForgeButton(
                  label: 'Continue',
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ForgeScaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.mission.title,
          style:
              AppTypography.title.copyWith(color: Colors.white, fontSize: 18),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;

                const fixedElementsHeight = 280.0;

                double remainingHeight = availableHeight - fixedElementsHeight;
                if (remainingHeight < 250.0) {
                  remainingHeight = 250.0;
                }

                final editorHeight = remainingHeight * 0.65;
                final outputHeight = remainingHeight * 0.35;

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.large,
                      vertical: AppSpacing.medium),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Lesson Intro
                      if (widget.mission.description.isNotEmpty) ...[
                        Text(
                          widget.mission.description,
                          style: AppTypography.body.copyWith(
                            color: AppColors.syntaxGrey,
                            height: 1.5,
                            fontSize: 15.0,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.medium),
                      ],

                      // Challenge Objective
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 300),
                        padding: const EdgeInsets.all(AppSpacing.medium),
                        decoration: BoxDecoration(
                          color: AppColors.logicCyan.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(
                            color: AppColors.logicCyan.withOpacity(0.3),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(Icons.track_changes_rounded,
                                color: AppColors.logicCyan, size: 22),
                            const SizedBox(width: AppSpacing.medium),
                            Expanded(
                              child: Text(
                                widget.mission.objective,
                                style: AppTypography.body.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w500,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),

                      // Code Editor Container
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 250),
                        height: editorHeight,
                        decoration: BoxDecoration(
                          color: const Color(0xFF161618), // Deep IDE tone
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          border: Border.all(
                            color: _editorFocusNode.hasFocus
                                ? AppColors.logicCyan.withOpacity(0.6)
                                : Colors.white.withOpacity(0.08),
                            width: 1.5,
                          ),
                          boxShadow: _editorFocusNode.hasFocus
                              ? [
                                  BoxShadow(
                                    color:
                                        AppColors.logicCyan.withOpacity(0.15),
                                    blurRadius: 12,
                                    offset: const Offset(0, 4),
                                  )
                                ]
                              : [],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(AppRadius.medium),
                          child: CodeEditorWidget(
                            controller: _codeController,
                            focusNode: _editorFocusNode,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Output Terminal
                      SizedBox(
                        height: outputHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color:
                                const Color(0xFF09090A), // Pure terminal black
                            borderRadius:
                                BorderRadius.circular(AppRadius.medium),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.06)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.medium,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.04),
                                  borderRadius: const BorderRadius.vertical(
                                    top: Radius.circular(AppRadius.medium),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.terminal_rounded,
                                        color: AppColors.syntaxGrey, size: 14),
                                    const SizedBox(width: 6),
                                    Text(
                                      'CONSOLE',
                                      style: AppTypography.body.copyWith(
                                        color: AppColors.syntaxGrey,
                                        fontSize: 10.0,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 1.5,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.medium),
                                  child: SingleChildScrollView(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      switchInCurve: Curves.easeOut,
                                      switchOutCurve: Curves.easeIn,
                                      child: Align(
                                        key: ValueKey<String>(_outputText),
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          _outputText,
                                          style: AppTypography.code.copyWith(
                                            fontSize: 13.0,
                                            height: 1.5,
                                            color: _outputText.contains('❌')
                                                ? AppColors.slagRed
                                                : (_outputText.contains('✅')
                                                    ? AppColors.temperGreen
                                                    : AppColors.syntaxGrey
                                                        .withOpacity(0.9)),
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.large),

                      // Action Buttons Row
                      Row(
                        children: [
                          if (widget.mission.hints.isNotEmpty) ...[
                            Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: _showHint,
                                borderRadius:
                                    BorderRadius.circular(AppRadius.large),
                                splashColor:
                                    AppColors.forgeEmber.withOpacity(0.2),
                                highlightColor:
                                    AppColors.forgeEmber.withOpacity(0.1),
                                child: Container(
                                  height: 56,
                                  width: 56,
                                  decoration: BoxDecoration(
                                    borderRadius:
                                        BorderRadius.circular(AppRadius.large),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.15),
                                      width: 1.5,
                                    ),
                                  ),
                                  child: const Icon(
                                    Icons.lightbulb_outline_rounded,
                                    color: AppColors.forgeEmber,
                                    size: 26,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: AppSpacing.medium),
                          ],
                          Expanded(
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 250),
                              height: 56,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: _isRunning
                                      ? [
                                          AppColors.syntaxGrey.withOpacity(0.5),
                                          AppColors.syntaxGrey.withOpacity(0.5),
                                        ]
                                      : [
                                          AppColors.temperGreen,
                                          const Color(
                                              0xFF238548), // Slightly darker green for depth
                                        ],
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                ),
                                borderRadius:
                                    BorderRadius.circular(AppRadius.large),
                                boxShadow: _isRunning
                                    ? []
                                    : [
                                        BoxShadow(
                                          color: AppColors.temperGreen
                                              .withOpacity(0.3),
                                          blurRadius: 16,
                                          offset: const Offset(0, 6),
                                        )
                                      ],
                              ),
                              child: Material(
                                color: Colors.transparent,
                                child: InkWell(
                                  onTap: _isRunning ? null : _runCode,
                                  borderRadius:
                                      BorderRadius.circular(AppRadius.large),
                                  child: Center(
                                    child: _isRunning
                                        ? const SizedBox(
                                            height: 24,
                                            width: 24,
                                            child: CircularProgressIndicator(
                                              color: Colors.white,
                                              strokeWidth: 2.5,
                                            ),
                                          )
                                        : Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: [
                                              const Icon(
                                                  Icons.play_arrow_rounded,
                                                  color: Colors.white,
                                                  size: 28),
                                              const SizedBox(width: 8),
                                              Text(
                                                'Run Code',
                                                style: AppTypography.title
                                                    .copyWith(
                                                  color: Colors.white,
                                                  fontSize: 18.0,
                                                  fontWeight: FontWeight.w700,
                                                ),
                                              ),
                                            ],
                                          ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.medium),
                    ],
                  ),
                );
              },
            ),
          ),
          if (_editorFocusNode.hasFocus)
            Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.medium,
                right: AppSpacing.medium,
                bottom: AppSpacing.medium,
              ),
              child: CodeEditorAccessoryBar(controller: _codeController),
            ),
        ],
      ),
    );
  }
}
