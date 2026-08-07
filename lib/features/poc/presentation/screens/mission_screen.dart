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
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../domain/models/mission.dart';

/// Milestone 1 - Phase 1: Editor Skeleton (Responsive Mission Editor & Keyboard Experience).
/// A robust structural UI layout for the interactive learning environment.
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
    // Rebuild the UI to conditionally show/hide the accessory bar
    setState(() {});
  }

  Future<void> _runCode() async {
    if (_isRunning) return;

    // Remove focus to dismiss the keyboard and accessory bar during execution
    _editorFocusNode.unfocus();

    setState(() {
      _isRunning = true;
      _outputText = '> Running...';
    });

    // Delegate execution to the ExecutionManager
    final executionResult =
        await _executionManager.execute(_codeController.text);

    if (!mounted) return;

    // Validate the user's code using the centralized AnswerValidator
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
      // Persist completion state through the centralized ProgressManager
      await _progressManager.completeMission(widget.mission.id);

      // Evaluate and fetch any newly unlocked achievements
      final newlyUnlocked = await _achievementEngine.evaluateAndUnlock();

      if (!mounted) return;

      _showCompletionDialog();

      // Display a SnackBar for each newly unlocked achievement
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

  void _showCompletionDialog() async {
    final xpReward = XpManager.rewardFor(widget.mission);
    final completed = await _progressManager.completedMissionCount();

    if (!mounted) return;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: AppColors.obsidian,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppRadius.medium),
            side: BorderSide(
              color: AppColors.forgeEmber.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.emoji_events,
                  color: AppColors.forgeEmber,
                  size: 60,
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  'Mission Complete!',
                  style: AppTypography.title.copyWith(
                    color: Colors.white,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Excellent work! Keep forging ahead.',
                  style: AppTypography.body.copyWith(
                    color: AppColors.syntaxGrey,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  decoration: BoxDecoration(
                    color: AppColors.temperGreen.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.medium),
                    border: Border.all(
                      color: AppColors.temperGreen.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        '+$xpReward XP',
                        style: AppTypography.title.copyWith(
                          color: AppColors.temperGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.small),
                      Text(
                        '$completed Mission${completed == 1 ? '' : 's'} Completed',
                        style: AppTypography.body.copyWith(
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Overall Progress',
                    style: AppTypography.body.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                ClipRRect(
                  borderRadius: BorderRadius.circular(AppRadius.small),
                  child: LinearProgressIndicator(
                    value: completed / 15,
                    minHeight: 10,
                    backgroundColor:
                        AppColors.syntaxGrey.withValues(alpha: 0.2),
                    valueColor: const AlwaysStoppedAnimation<Color>(
                      AppColors.temperGreen,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.small),
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    '$completed / 15 Missions',
                    style: AppTypography.body.copyWith(
                      color: AppColors.syntaxGrey,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                ForgeButton(
                  label: completed >= 15 ? 'Finish Module' : 'Continue',
                  onPressed: () {
                    Navigator.of(context).pop();

                    if (mounted) {
                      context.pop(true);
                    }
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
        children: [
          // Main Scrollable Editor Area
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final availableHeight = constraints.maxHeight;

                // Approximate height of static elements (Objective Card, Buttons, Spacings)
                const fixedElementsHeight = 260.0;

                // Determine remaining height to distribute to the Editor and Output Console.
                double remainingHeight = availableHeight - fixedElementsHeight;

                // Enforce a minimum height threshold to ensure the UI initiates scrolling
                // gracefully when the keyboard ascends rather than compressing code blocks to zero.
                if (remainingHeight < 250.0) {
                  remainingHeight = 250.0;
                }

                // Apportion 60% of flexible space to the editor, 40% to the console
                final editorHeight = remainingHeight * 0.6;
                final outputHeight = remainingHeight * 0.4;

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.medium),
                  child: Column(
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
                              style: AppTypography.body
                                  .copyWith(color: Colors.white),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Code Editor Container
                      SizedBox(
                        height: editorHeight,
                        child: CodeEditorWidget(
                          controller: _codeController,
                          focusNode: _editorFocusNode,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),

                      // Output Console Container
                      SizedBox(
                        height: outputHeight,
                        child: Container(
                          decoration: BoxDecoration(
                            color: AppColors.obsidian,
                            borderRadius:
                                BorderRadius.circular(AppRadius.medium),
                            border: Border.all(
                              color: AppColors.syntaxGrey.withOpacity(0.3),
                              width: 1.0,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Console Header
                              Padding(
                                padding: const EdgeInsets.only(
                                  left: AppSpacing.medium,
                                  top: AppSpacing.medium,
                                  right: AppSpacing.medium,
                                  bottom: AppSpacing.small,
                                ),
                                child: Text(
                                  'OUTPUT',
                                  style: AppTypography.body.copyWith(
                                    color: AppColors.syntaxGrey,
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ),
                              // Header Divider
                              Divider(
                                height: 1.0,
                                thickness: 1.0,
                                color: AppColors.syntaxGrey.withOpacity(0.3),
                              ),
                              // Console Text Area
                              Expanded(
                                child: Padding(
                                  padding:
                                      const EdgeInsets.all(AppSpacing.medium),
                                  child: SingleChildScrollView(
                                    child: AnimatedSwitcher(
                                      duration:
                                          const Duration(milliseconds: 300),
                                      child: Align(
                                        key: ValueKey<String>(_outputText),
                                        alignment: Alignment.topLeft,
                                        child: Text(
                                          _outputText,
                                          style: AppTypography.code.copyWith(
                                            color: _outputText.contains('❌')
                                                ? AppColors.slagRed
                                                : (_outputText.contains('✅')
                                                    ? AppColors.temperGreen
                                                    : AppColors.syntaxGrey),
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

                      // Action Buttons
                      Row(
                        children: [
                          if (widget.mission.hints.isNotEmpty) ...[
                            Expanded(
                              flex: 1,
                              child: ForgeButton(
                                label: 'Hint',
                                icon: const Icon(
                                  Icons.lightbulb_outline,
                                  color: AppColors.obsidian,
                                ),
                                onPressed: _showHint,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.medium),
                          ],
                          Expanded(
                            flex: 2,
                            child: ForgeButton(
                              label: _isRunning ? 'Running...' : 'Run Code',
                              icon: _isRunning
                                  ? null
                                  : const Icon(
                                      Icons.play_arrow_rounded,
                                      color: AppColors.obsidian,
                                    ),
                              onPressed: _isRunning ? null : _runCode,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                );
              },
            ),
          ),

          // Pinned Accessory Bar
          // Appears immediately above the keyboard for instant access, uncoupled from scroll offsets
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
