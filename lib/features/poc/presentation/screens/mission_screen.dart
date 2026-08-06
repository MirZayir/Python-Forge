import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/forge_button.dart';
import '../../../../core/widgets/forge_card.dart';
import '../../../../core/widgets/forge_scaffold.dart';
import '../../../../core/widgets/section_title.dart';
import '../../domain/models/mission.dart';

/// Interactive screen for a specific learning mission.
class MissionScreen extends ConsumerStatefulWidget {
  final Mission mission;

  const MissionScreen({super.key, required this.mission});

  @override
  ConsumerState<MissionScreen> createState() => _MissionScreenState();
}

class _MissionScreenState extends ConsumerState<MissionScreen> {
  final TextEditingController _codeController = TextEditingController();
  bool? _isCorrect;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  void _checkAnswer() {
    setState(() {
      _isCorrect = widget.mission.validateAnswer(_codeController.text);
    });
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
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SectionTitle(
              title: widget.mission.numberLabel,
              subtitle: widget.mission.title,
            ),
            const SizedBox(height: AppSpacing.large),
            ForgeCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Objective:',
                    style: AppTypography.title.copyWith(
                      color: AppColors.logicCyan,
                      fontSize: 16.0,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.small),
                  Text(
                    widget.mission.objective,
                    style: AppTypography.body.copyWith(color: Colors.white),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            Text(
              'Code Editor',
              style: AppTypography.title.copyWith(
                color: Colors.white,
                fontSize: 16.0,
              ),
            ),
            const SizedBox(height: AppSpacing.small),
            Container(
              decoration: BoxDecoration(
                color: AppColors.crucibleGrey,
                borderRadius: BorderRadius.circular(AppRadius.medium),
                border: Border.all(
                  color: _isCorrect == null
                      ? AppColors.syntaxGrey
                      : (_isCorrect!
                            ? AppColors.temperGreen
                            : AppColors.slagRed),
                  width: 1.0,
                ),
              ),
              padding: const EdgeInsets.all(AppSpacing.medium),
              child: TextField(
                controller: _codeController,
                maxLines: 4,
                minLines: 3,
                style: AppTypography.code.copyWith(color: Colors.white),
                cursorColor: AppColors.forgeEmber,
                decoration: InputDecoration(
                  hintText: '# Write your code here',
                  hintStyle: AppTypography.code.copyWith(
                    color: AppColors.syntaxGrey,
                  ),
                  border: InputBorder.none,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.large),
            SizedBox(
              width: double.infinity,
              child: ForgeButton(
                label: 'Check Answer',
                onPressed: _checkAnswer,
              ),
            ),
            if (_isCorrect != null) ...[
              const SizedBox(height: AppSpacing.large),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(AppSpacing.medium),
                decoration: BoxDecoration(
                  color: _isCorrect!
                      ? AppColors.temperGreen.withOpacity(0.15)
                      : AppColors.slagRed.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppRadius.medium),
                  border: Border.all(
                    color: _isCorrect!
                        ? AppColors.temperGreen
                        : AppColors.slagRed,
                    width: 1.0,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      _isCorrect!
                          ? Icons.check_circle_outline
                          : Icons.error_outline,
                      color: _isCorrect!
                          ? AppColors.temperGreen
                          : AppColors.slagRed,
                    ),
                    const SizedBox(width: AppSpacing.small),
                    Expanded(
                      child: Text(
                        _isCorrect!
                            ? 'Correct! Mission Complete.'
                            : 'Try Again',
                        style: AppTypography.body.copyWith(
                          color: _isCorrect!
                              ? AppColors.temperGreen
                              : AppColors.slagRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
