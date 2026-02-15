import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../widgets/app_button.dart';

class ModeSelectionScreen extends StatelessWidget {
  const ModeSelectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppColors.primary,
              AppColors.secondary,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.quiz,
                  size: 100,
                  color: AppColors.surface,
                ),
                const SizedBox(height: AppSpacing.xl),
                Text(
                  'Своя Игра',
                  style: AppTextStyles.h1.copyWith(
                    color: AppColors.surface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: AppSpacing.xxl),
                AppButton(
                  text: 'Режим администрирования',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/admin');
                  },
                  backgroundColor: AppColors.accent,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'Режим ведущего',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/host');
                  },
                  backgroundColor: AppColors.warning,
                ),
                const SizedBox(height: AppSpacing.md),
                AppButton(
                  text: 'Режим демонстрации',
                  onPressed: () {
                    Navigator.pushReplacementNamed(context, '/display');
                  },
                  backgroundColor: AppColors.secondary,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

