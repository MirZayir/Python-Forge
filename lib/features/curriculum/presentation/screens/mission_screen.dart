import 'package:flutter/material.dart';

import '../../../../core/engine/answer_validator.dart';
import '../../../../core/engine/execution_manager.dart';
import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/streak_engine.dart';
import '../../../../core/progression/xp_manager.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/code_editor_widget.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/mission.dart';

/// Interactive mission screen supporting Code, MCQ, and Fill-in-the-Blank challenges.
class MissionScreen extends StatefulWidget {
  final Mission mission;

  const MissionScreen({super.key, required this.mission});

  @override
  State<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends State<MissionScreen> {
  // Vintage Retro Palette Constants
  static const Color _creamMatte = Color(0xFFE8D8C9);
  static const Color _slateBlue = Color(0xFF4B607F);
  static const Color _retroOrange = Color(0xFFF3701E);
  static const Color _textDark = Color(0xFF18181A);
  static const Color _textMutedDark = Color(0xFF5A5A60);

  late final TextEditingController _codeController;
  late final FocusNode _editorFocusNode;

  final ExecutionManager _executionManager = ExecutionManager();
  final ProgressManager _progressManager = ProgressManager();
  final AchievementEngine _achievementEngine = AchievementEngine();
  final CurriculumRepository _repository = CurriculumRepository();
  final StreakEngine _streakEngine = StreakEngine();

  String _outputText = 'Ready to execute...';
  bool _isRunning = false;
  int _attemptCount = 0;

  // State for MCQ and Fill-in-the-Blank mission types
  String? _selectedMcqOption;
  late final TextEditingController _blankInputController;

  @override
  void initState() {
    super.initState();

    _codeController = FixedPrefixCodeController(
      rawPrefix: widget.mission.starterCode,
      prefixStyle: AppTypography.code.copyWith(
        color: Colors.white.withValues(alpha: 0.38),
        fontSize: 14.0,
        height: 1.5,
      ),
      userTextStyle: AppTypography.code.copyWith(
        color: Colors.white,
        fontSize: 14.0,
        height: 1.5,
      ),
    );

    _blankInputController = TextEditingController();
    _editorFocusNode = FocusNode();
    _editorFocusNode.addListener(_onFocusChanged);
  }

  @override
  void dispose() {
    _editorFocusNode.removeListener(_onFocusChanged);
    _codeController.dispose();
    _blankInputController.dispose();
    _editorFocusNode.dispose();
    super.dispose();
  }

  void _onFocusChanged() {
    if (mounted) {
      setState(() {});
    }
  }

  /// Resolves the next sequential mission across all curriculum modules.
  Future<Mission?> _getNextMission() async {
    try {
      final curriculum = await _repository.getCurriculum();
      for (int i = 0; i < curriculum.modules.length; i++) {
        final module = curriculum.modules[i];
        for (int j = 0; j < module.missions.length; j++) {
          if (module.missions[j].id == widget.mission.id) {
            if (j + 1 < module.missions.length) {
              return module.missions[j + 1];
            }
            if (i + 1 < curriculum.modules.length &&
                curriculum.modules[i + 1].missions.isNotEmpty) {
              return curriculum.modules[i + 1].missions.first;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  Future<void> _submitAnswer() async {
    if (_isRunning) return;

    _editorFocusNode.unfocus();

    setState(() {
      _isRunning = true;
      _outputText = '> Evaluating answer...';
    });

    String submittedCode = _codeController.text;
    String executionOutput = '';

    if (widget.mission.type == MissionType.mcq) {
      submittedCode = _selectedMcqOption ?? '';
      executionOutput = _selectedMcqOption ?? 'No option selected';
    } else if (widget.mission.type == MissionType.fillInBlank) {
      submittedCode = _blankInputController.text.trim();
      executionOutput = submittedCode;
    } else {
      final res = await _executionManager.execute(_codeController.text);
      executionOutput = res.output;
    }

    if (!mounted) return;

    final validationResult = AnswerValidator.validate(
      fullCode: submittedCode,
      actualOutput: executionOutput,
      mission: widget.mission,
    );

    setState(() {
      _isRunning = false;
      _outputText = '$executionOutput\n\n${validationResult.message}';
      if (validationResult.status != ValidationStatus.correct) {
        _attemptCount++;
      }
    });

    if (validationResult.status == ValidationStatus.correct) {
      await _progressManager.completeMission(widget.mission.id);
      await _streakEngine.recordActivity();
      final newlyUnlocked = await _achievementEngine.evaluateAndUnlock();

      if (!mounted) return;

      final nextMission = await _getNextMission();

      if (!mounted) return;

      _showCompletionDialog(nextMission);

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
            backgroundColor: _textDark,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: _retroOrange.withValues(alpha: 0.5),
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

    final hintIndex = (_attemptCount > 0 ? _attemptCount - 1 : 0) %
        widget.mission.hints.length;
    final hintText = widget.mission.hints[hintIndex];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: _creamMatte,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lightbulb_rounded, color: _retroOrange),
                    const SizedBox(width: AppSpacing.small),
                    Text(
                      'Mission Hint',
                      style: AppTypography.title.copyWith(
                        color: _textDark,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  hintText,
                  style: AppTypography.body.copyWith(
                    color: _textMutedDark,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                GestureDetector(
                  onTap: () => Navigator.of(context).pop(),
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: _retroOrange,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Text(
                        'Got it',
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _showCompletionDialog(Mission? nextMission) {
    final xpReward = XpManager.rewardFor(widget.mission);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          backgroundColor: _creamMatte,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(28),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '🎉 Mission Complete!',
                  style: AppTypography.title.copyWith(
                    color: _textDark,
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small),
                Text(
                  'Great job completing this challenge.',
                  style: AppTypography.body.copyWith(color: _textMutedDark),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    color: _retroOrange.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    '+$xpReward XP',
                    style: AppTypography.code.copyWith(
                      color: _retroOrange,
                      fontWeight: FontWeight.w900,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),

                // Primary Button: Direct Next Mission Continuation
                if (nextMission != null) ...[
                  GestureDetector(
                    onTap: () {
                      Navigator.of(context).pop();
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (context) =>
                              MissionScreen(mission: nextMission),
                        ),
                      );
                    },
                    child: Container(
                      height: 50,
                      width: double.infinity,
                      decoration: BoxDecoration(
                        color: _retroOrange,
                        borderRadius: BorderRadius.circular(18),
                        boxShadow: [
                          BoxShadow(
                            color: _retroOrange.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Next Mission',
                              style: AppTypography.title.copyWith(
                                color: Colors.white,
                                fontSize: 16.0,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward_rounded,
                                color: Colors.white, size: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],

                // Secondary Button: Back to Dashboard
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: nextMission != null ? _slateBlue : _retroOrange,
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Center(
                      child: Text(
                        'Back to Dashboard',
                        style: AppTypography.title.copyWith(
                          color: Colors.white,
                          fontSize: 15.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
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
              color: _creamMatte, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          widget.mission.title,
          style: AppTypography.title.copyWith(
            color: _creamMatte,
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.large,
                vertical: AppSpacing.medium,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (widget.mission.description.isNotEmpty) ...[
                    Text(
                      widget.mission.description,
                      style: AppTypography.body.copyWith(
                        color: _creamMatte.withValues(alpha: 0.85),
                        height: 1.5,
                        fontSize: 14.0,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.medium),
                  ],

                  // Objective Bento Container Surface
                  Container(
                    padding: const EdgeInsets.all(16.0),
                    decoration: BoxDecoration(
                      color: _creamMatte,
                      borderRadius: BorderRadius.circular(22),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: _retroOrange,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Icon(
                            Icons.track_changes_rounded,
                            color: Colors.white,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            widget.mission.objective,
                            style: AppTypography.body.copyWith(
                              color: _textDark,
                              fontWeight: FontWeight.w800,
                              height: 1.4,
                              fontSize: 14.0,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.large),

                  // Dynamic Mission UI based on MissionType
                  if (widget.mission.type == MissionType.mcq)
                    _buildMcqView()
                  else if (widget.mission.type == MissionType.fillInBlank)
                    _buildFillInBlankView()
                  else
                    _buildCodeView(),

                  const SizedBox(height: AppSpacing.large),

                  // Bottom Action Buttons
                  Row(
                    children: [
                      if (widget.mission.hints.isNotEmpty) ...[
                        Material(
                          color: Colors.transparent,
                          child: InkWell(
                            onTap: _showHint,
                            borderRadius: BorderRadius.circular(20),
                            child: Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: _creamMatte,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: _retroOrange,
                                size: 24,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.medium),
                      ],
                      Expanded(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          height: 52,
                          decoration: BoxDecoration(
                            color: _isRunning
                                ? _creamMatte.withValues(alpha: 0.5)
                                : _retroOrange,
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: _isRunning
                                ? []
                                : [
                                    BoxShadow(
                                      color:
                                          _retroOrange.withValues(alpha: 0.35),
                                      blurRadius: 12,
                                      offset: const Offset(0, 4),
                                    )
                                  ],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _isRunning ? null : _submitAnswer,
                              borderRadius: BorderRadius.circular(20),
                              child: Center(
                                child: _isRunning
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            widget.mission.type ==
                                                    MissionType.code
                                                ? Icons.play_arrow_rounded
                                                : Icons.check_rounded,
                                            color: Colors.white,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.mission.type ==
                                                    MissionType.code
                                                ? 'Run Code'
                                                : 'Submit Answer',
                                            style: AppTypography.title.copyWith(
                                              color: Colors.white,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w800,
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
            ),
          ),
          if (widget.mission.type == MissionType.code &&
              _editorFocusNode.hasFocus)
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

  /// 1. Renders the standard Code Editor & Console layout
  Widget _buildCodeView() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            decoration: BoxDecoration(
              color: _creamMatte,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _editorFocusNode.hasFocus
                    ? _retroOrange
                    : Colors.transparent,
                width: 2.0,
              ),
            ),
            child: Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.code_rounded,
                          color: _textDark, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'EDITOR',
                        style: AppTypography.body.copyWith(
                          color: _textDark,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(24)),
                    child: CodeEditorWidget(
                      controller: _codeController,
                      focusNode: _editorFocusNode,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.medium),
        SizedBox(
          height: 120,
          child: Container(
            decoration: BoxDecoration(
              color: _creamMatte,
              borderRadius: BorderRadius.circular(22),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  child: Row(
                    children: [
                      const Icon(Icons.terminal_rounded,
                          color: _textDark, size: 16),
                      const SizedBox(width: 8),
                      Text(
                        'CONSOLE',
                        style: AppTypography.body.copyWith(
                          color: _textDark,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Container(
                    margin: const EdgeInsets.only(left: 4, right: 4, bottom: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0D0D0E),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 300),
                        child: Align(
                          key: ValueKey<String>(_outputText),
                          alignment: Alignment.topLeft,
                          child: Text(
                            _outputText,
                            style: AppTypography.code.copyWith(
                              fontSize: 13.0,
                              height: 1.4,
                              color: _outputText.contains('❌')
                                  ? AppColors.slagRed
                                  : (_outputText.contains('⚠️')
                                      ? const Color(0xFFF39C12)
                                      : (_outputText.contains('✅')
                                          ? const Color(0xFF1DD1A1)
                                          : _creamMatte.withValues(
                                              alpha: 0.85))),
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
      ],
    );
  }

  /// 2. Renders Multiple Choice (MCQ) option cards
  Widget _buildMcqView() {
    final options = widget.mission.mcqOptions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Select the correct answer:',
          style: AppTypography.body.copyWith(
            color: _creamMatte,
            fontWeight: FontWeight.w700,
            fontSize: 14.0,
          ),
        ),
        const SizedBox(height: 12),
        ...options.map((option) {
          final isSelected = _selectedMcqOption == option;
          return Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _selectedMcqOption = option;
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isSelected ? _retroOrange : _creamMatte,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isSelected ? _retroOrange : Colors.transparent,
                    width: 2.0,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: _retroOrange.withValues(alpha: 0.35),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : [],
                ),
                child: Row(
                  children: [
                    Icon(
                      isSelected
                          ? Icons.radio_button_checked_rounded
                          : Icons.radio_button_off_rounded,
                      color: isSelected ? Colors.white : _textDark,
                      size: 22,
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(
                        option,
                        style: AppTypography.code.copyWith(
                          color: isSelected ? Colors.white : _textDark,
                          fontSize: 14.0,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  /// 3. Renders Fill-in-the-Blank inline input card
  Widget _buildFillInBlankView() {
    return Container(
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: _creamMatte,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.edit_note_rounded, color: _textDark, size: 20),
              const SizedBox(width: 8),
              Text(
                'FILL IN THE BLANK',
                style: AppTypography.body.copyWith(
                  color: _textDark,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (widget.mission.starterCode.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14.0),
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                widget.mission.starterCode,
                style: AppTypography.code.copyWith(
                  color: Colors.white,
                  fontSize: 14.0,
                  height: 1.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          TextField(
            controller: _blankInputController,
            style: AppTypography.code.copyWith(
              color: _textDark,
              fontSize: 15.0,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              hintText: 'Type missing keyword or value...',
              hintStyle: TextStyle(
                color: _textMutedDark.withValues(alpha: 0.6),
                fontSize: 14.0,
              ),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _retroOrange, width: 2.0),
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
