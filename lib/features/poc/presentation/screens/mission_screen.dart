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

/// Milestone 1 - Phase 1: Editor Skeleton (Achievement Engine Integration).
/// A structural UI layout for the interactive learning environment.
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
    _codeController = TextEditingController(text: 'print("Hello, World!")');
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
                  'You wrote your first Python program.',
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
            child: CodeEditorWidget(
              controller: _codeController,
              focusNode: _editorFocusNode,
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
                      padding: const EdgeInsets.all(AppSpacing.medium),
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 300),
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

          // Render the accessory bar whenever the editor is focused
          if (_editorFocusNode.hasFocus)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.medium),
              child: CodeEditorAccessoryBar(controller: _codeController),
            ),
        ],
      ),
    );
  }
}
