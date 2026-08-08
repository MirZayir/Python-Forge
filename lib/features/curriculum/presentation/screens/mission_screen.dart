import 'package:flutter/material.dart';

import '../../../../core/engine/answer_validator.dart';
import '../../../../core/engine/execution_manager.dart';
import '../../../../core/progression/achievement_engine.dart';
import '../../../../core/progression/progress_manager.dart';
import '../../../../core/progression/streak_engine.dart';
import '../../../../core/progression/xp_manager.dart';
import '../../../../core/services/haptic_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/widgets/code_editor_widget.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../data/repositories/curriculum_repository.dart';
import '../../domain/models/mission.dart';

/// Neubrutalist mission screen supporting Code, MCQ, and Fill-in-the-Blank challenges.
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
  final CurriculumRepository _repository = CurriculumRepository();
  final StreakEngine _streakEngine = StreakEngine();

  String _outputText = 'Ready to execute...';
  bool _isRunning = false;
  int _attemptCount = 0;

  String? _selectedMcqOption;
  late final TextEditingController _blankInputController;

  @override
  void initState() {
    super.initState();

    _codeController = FixedPrefixCodeController(
      rawPrefix: widget.mission.starterCode,
      prefixStyle: const TextStyle(
        color: Color(0xFF888888),
        fontFamily: 'monospace',
        fontSize: 14.0,
        height: 1.5,
      ),
      userTextStyle: const TextStyle(
        color: AppColors.borderBlack,
        fontFamily: 'monospace',
        fontSize: 14.0,
        fontWeight: FontWeight.bold,
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
      HapticService.successPattern();
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
              style: const TextStyle(
                color: AppColors.borderBlack,
                fontWeight: FontWeight.bold,
              ),
            ),
            backgroundColor: AppColors.neuYellow,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: const BorderSide(color: AppColors.borderBlack, width: 2.0),
            ),
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } else if (validationResult.status == ValidationStatus.methodWarning) {
      HapticService.mediumImpact();
    } else {
      HapticService.heavyImpact();
    }
  }

  void _showHint() {
    HapticService.lightImpact();
    if (widget.mission.hints.isEmpty) return;

    final hintIndex = (_attemptCount > 0 ? _attemptCount - 1 : 0) %
        widget.mission.hints.length;
    final hintText = widget.mission.hints[hintIndex];

    showDialog(
      context: context,
      builder: (context) {
        return Dialog(
          backgroundColor: AppColors.bgCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: const BorderSide(color: AppColors.borderBlack, width: 3.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: const [
                    Icon(Icons.lightbulb_rounded,
                        color: AppColors.borderBlack, size: 24),
                    SizedBox(width: AppSpacing.small),
                    Text(
                      'Mission Hint',
                      style: TextStyle(
                        color: AppColors.borderBlack,
                        fontSize: 18.0,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.medium),
                Text(
                  hintText,
                  style: const TextStyle(
                    color: Color(0xFF4A4A4A),
                    fontSize: 14.0,
                    fontWeight: FontWeight.w600,
                    height: 1.4,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 48,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.neuYellow,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Got it',
                        style: TextStyle(
                          color: AppColors.borderBlack,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w900,
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
          backgroundColor: AppColors.bgCream,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: AppColors.borderBlack, width: 3.0),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.large),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  '🎉 Mission Complete!',
                  style: TextStyle(
                    color: AppColors.borderBlack,
                    fontSize: 22.0,
                    fontWeight: FontWeight.w900,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.small),
                const Text(
                  'Great job completing this challenge.',
                  style: TextStyle(
                      color: Color(0xFF555555), fontWeight: FontWeight.w600),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.large),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.large,
                    vertical: AppSpacing.small,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.neuYellow,
                    borderRadius: BorderRadius.circular(14),
                    border:
                        Border.all(color: AppColors.borderBlack, width: 2.0),
                  ),
                  child: Text(
                    '+$xpReward XP',
                    style: const TextStyle(
                      color: AppColors.borderBlack,
                      fontWeight: FontWeight.w900,
                      fontSize: 20.0,
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.large),
                if (nextMission != null) ...[
                  GestureDetector(
                    onTap: () {
                      HapticService.lightImpact();
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
                        color: AppColors.neuGreen,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                            color: AppColors.borderBlack, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: const [
                          Text(
                            'Next Mission',
                            style: TextStyle(
                              color: AppColors.borderBlack,
                              fontSize: 16.0,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward_rounded,
                              color: AppColors.borderBlack, size: 20),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.medium),
                ],
                GestureDetector(
                  onTap: () {
                    HapticService.lightImpact();
                    Navigator.of(context).pop();
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    height: 50,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppColors.cardWhite,
                      borderRadius: BorderRadius.circular(14),
                      border:
                          Border.all(color: AppColors.borderBlack, width: 2.5),
                    ),
                    child: const Center(
                      child: Text(
                        'Back to Dashboard',
                        style: TextStyle(
                          color: AppColors.borderBlack,
                          fontSize: 15.0,
                          fontWeight: FontWeight.w900,
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
        backgroundColor: AppColors.bgCream,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        leading: GestureDetector(
          onTap: () {
            HapticService.lightImpact();
            Navigator.of(context).pop();
          },
          child: Container(
            margin: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBlack,
                  offset: Offset(2, 2),
                  blurRadius: 0,
                ),
              ],
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColors.borderBlack,
              size: 20,
            ),
          ),
        ),
        title: Text(
          widget.mission.title,
          style: const TextStyle(
            color: AppColors.borderBlack,
            fontSize: 18,
            fontWeight: FontWeight.w900,
          ),
        ),
      ),
      body: Container(
        color: AppColors.bgCream,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(AppSpacing.large),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (widget.mission.description.isNotEmpty) ...[
                      Text(
                        widget.mission.description,
                        style: const TextStyle(
                          color: Color(0xFF4A4A4A),
                          height: 1.4,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.medium),
                    ],

                    // Objective Box
                    Container(
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardWhite,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: AppColors.borderBlack, width: 2.5),
                        boxShadow: const [
                          BoxShadow(
                            color: AppColors.shadowBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
                          ),
                        ],
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: AppColors.neuYellow,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                  color: AppColors.borderBlack, width: 2.0),
                            ),
                            child: const Icon(
                              Icons.track_changes_rounded,
                              color: AppColors.borderBlack,
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              widget.mission.objective,
                              style: const TextStyle(
                                color: AppColors.borderBlack,
                                fontWeight: FontWeight.w900,
                                height: 1.4,
                                fontSize: 14.0,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.large),

                    if (widget.mission.type == MissionType.mcq)
                      _buildMcqView()
                    else if (widget.mission.type == MissionType.fillInBlank)
                      _buildFillInBlankView()
                    else
                      _buildCodeView(),

                    const SizedBox(height: AppSpacing.large),

                    // Action Buttons
                    Row(
                      children: [
                        if (widget.mission.hints.isNotEmpty) ...[
                          GestureDetector(
                            onTap: _showHint,
                            child: Container(
                              height: 52,
                              width: 52,
                              decoration: BoxDecoration(
                                color: AppColors.cardWhite,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.borderBlack, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowBlack,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.lightbulb_outline_rounded,
                                color: AppColors.borderBlack,
                                size: 24,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.medium),
                        ],
                        Expanded(
                          child: GestureDetector(
                            onTap: _isRunning ? null : _submitAnswer,
                            child: Container(
                              height: 52,
                              decoration: BoxDecoration(
                                color: _isRunning
                                    ? Colors.grey
                                    : AppColors.neuGreen,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(
                                    color: AppColors.borderBlack, width: 2.5),
                                boxShadow: const [
                                  BoxShadow(
                                    color: AppColors.shadowBlack,
                                    offset: Offset(3, 3),
                                    blurRadius: 0,
                                  ),
                                ],
                              ),
                              child: Center(
                                child: _isRunning
                                    ? const SizedBox(
                                        height: 22,
                                        width: 22,
                                        child: CircularProgressIndicator(
                                          color: AppColors.borderBlack,
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
                                            color: AppColors.borderBlack,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 8),
                                          Text(
                                            widget.mission.type ==
                                                    MissionType.code
                                                ? 'Run Code'
                                                : 'Submit Answer',
                                            style: const TextStyle(
                                              color: AppColors.borderBlack,
                                              fontSize: 16.0,
                                              fontWeight: FontWeight.w900,
                                            ),
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      ),
    );
  }

  Widget _buildCodeView() {
    return Column(
      children: [
        SizedBox(
          height: 200,
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.cardWhite,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBlack,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.neuYellow,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(13)),
                    border: Border(
                        bottom: BorderSide(
                            color: AppColors.borderBlack, width: 2.5)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.code_rounded,
                          color: AppColors.borderBlack, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'EDITOR',
                        style: TextStyle(
                          color: AppColors.borderBlack,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        bottom: Radius.circular(13)),
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
              color: const Color(0xFF18181A),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.borderBlack, width: 2.5),
              boxShadow: const [
                BoxShadow(
                  color: AppColors.shadowBlack,
                  offset: Offset(4, 4),
                  blurRadius: 0,
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                    color: AppColors.borderBlack,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(13)),
                  ),
                  child: Row(
                    children: const [
                      Icon(Icons.terminal_rounded,
                          color: AppColors.neuYellow, size: 16),
                      SizedBox(width: 8),
                      Text(
                        'CONSOLE',
                        style: TextStyle(
                          color: AppColors.neuYellow,
                          fontSize: 11.0,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: SingleChildScrollView(
                      child: Text(
                        _outputText,
                        style: TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13.0,
                          height: 1.4,
                          color: _outputText.contains('❌')
                              ? AppColors.slagRed
                              : (_outputText.contains('⚠️')
                                  ? const Color(0xFFF39C12)
                                  : (_outputText.contains('✅')
                                      ? AppColors.neuGreen
                                      : Colors.white)),
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

  Widget _buildMcqView() {
    final options = widget.mission.mcqOptions ?? [];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Select the correct answer:',
          style: TextStyle(
            color: AppColors.borderBlack,
            fontWeight: FontWeight.w900,
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
                HapticService.selectionClick();
                setState(() {
                  _selectedMcqOption = option;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.neuYellow : AppColors.cardWhite,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderBlack, width: 2.5),
                  boxShadow: isSelected
                      ? const [
                          BoxShadow(
                            color: AppColors.shadowBlack,
                            offset: Offset(3, 3),
                            blurRadius: 0,
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
                      color: AppColors.borderBlack,
                      size: 22,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option,
                        style: const TextStyle(
                          color: AppColors.borderBlack,
                          fontSize: 14.0,
                          fontWeight: FontWeight.w900,
                          fontFamily: 'monospace',
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

  Widget _buildFillInBlankView() {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.cardWhite,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.borderBlack, width: 2.5),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadowBlack,
            offset: Offset(4, 4),
            blurRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Icon(Icons.edit_note_rounded,
                  color: AppColors.borderBlack, size: 20),
              SizedBox(width: 8),
              Text(
                'FILL IN THE BLANK',
                style: TextStyle(
                  color: AppColors.borderBlack,
                  fontSize: 11.0,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (widget.mission.starterCode.isNotEmpty) ...[
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: const Color(0xFF181A20),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderBlack, width: 2.0),
              ),
              child: Text(
                widget.mission.starterCode,
                style: const TextStyle(
                  color: Colors.white,
                  fontFamily: 'monospace',
                  fontSize: 14.0,
                  height: 1.4,
                ),
              ),
            ),
            const SizedBox(height: 14),
          ],
          TextField(
            controller: _blankInputController,
            style: const TextStyle(
              color: AppColors.borderBlack,
              fontFamily: 'monospace',
              fontSize: 15.0,
              fontWeight: FontWeight.w900,
            ),
            decoration: InputDecoration(
              hintText: 'Type missing keyword or value...',
              hintStyle: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 14.0,
              ),
              filled: true,
              fillColor: AppColors.bgCream,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.borderBlack, width: 2.0),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.borderBlack, width: 2.5),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
