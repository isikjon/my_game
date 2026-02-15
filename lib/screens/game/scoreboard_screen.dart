import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../models/team_model.dart';

class ScoreboardScreen extends StatelessWidget {
  final List<TeamModel> teams;

  const ScoreboardScreen({
    super.key,
    required this.teams,
  });

  @override
  Widget build(BuildContext context) {
    final sortedTeams = List<TeamModel>.from(teams)
      ..sort((a, b) => b.score.compareTo(a.score));

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.gameBackgroundStart,
              AppColors.gameBackgroundEnd,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Итоги раунда',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.questionTextColor,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: sortedTeams.asMap().entries.map((entry) {
                      final index = entry.key;
                      final team = entry.value;
                      final isWinner = index == 0;
                      
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                          ),
                          child: _buildTeamCard(team, isWinner),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTeamCard(TeamModel team, bool isWinner) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: isWinner
                ? AppColors.warning
                : AppColors.categoryCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            '${team.score}',
            style: AppTextStyles.h3.copyWith(
              color: AppColors.questionTextColor,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.center,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: double.infinity,
              aspectRatio: 1,
              decoration: BoxDecoration(
                color: AppColors.categoryCard,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                Icons.people_outline,
                size: 60,
                color: AppColors.questionTextColor,
              ),
            ),
            if (isWinner)
              Positioned(
                bottom: -8,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: AppColors.warning,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emoji_events,
                    color: AppColors.questionTextColor,
                    size: 24,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.sm,
            vertical: AppSpacing.md,
          ),
          decoration: BoxDecoration(
            color: AppColors.categoryCard,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            team.name,
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.questionTextColor,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

