import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../models/question_model.dart';
import '../../config/app_mode.dart';

class QuestionScreen extends StatefulWidget {
  final QuestionModel question;
  final VoidCallback? onShowAnswer;
  final VoidCallback? onCorrect;
  final VoidCallback? onIncorrect;
  final bool showAnswer;
  final int? timeRemaining;

  const QuestionScreen({
    super.key,
    required this.question,
    this.onShowAnswer,
    this.onCorrect,
    this.onIncorrect,
    this.showAnswer = false,
    this.timeRemaining,
  });

  @override
  State<QuestionScreen> createState() => _QuestionScreenState();
}

class _QuestionScreenState extends State<QuestionScreen> {
  int? _currentTime;
  bool _isTimerRunning = false;

  @override
  void initState() {
    super.initState();
    _currentTime = widget.timeRemaining ?? 35;
    if (AppModeConfig.isHostMode) {
      _startTimer();
    }
  }

  void _startTimer() {
    if (_isTimerRunning) return;
    _isTimerRunning = true;
    Future.doWhile(() async {
      await Future.delayed(const Duration(seconds: 1));
      if (mounted && _currentTime != null && _currentTime! > 0) {
        setState(() {
          _currentTime = _currentTime! - 1;
        });
        return true;
      }
      return false;
    });
  }

  String _formatTime(int seconds) {
    final minutes = seconds ~/ 60;
    final secs = seconds % 60;
    return '${minutes.toString().padLeft(2, '0')}:${secs.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
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
            child: Center(
              child: Container(
                width: double.infinity,
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(AppSpacing.xl),
                decoration: BoxDecoration(
                  color: AppColors.questionScreenCard,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentTime != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.lg,
                          vertical: AppSpacing.md,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.timerBackground,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _formatTime(_currentTime!),
                          style: AppTextStyles.h2.copyWith(
                            color: AppColors.questionTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    const SizedBox(height: AppSpacing.xl),
                    Expanded(
                      child: Center(
                        child: SingleChildScrollView(
                          child: Text(
                            widget.showAnswer
                                ? widget.question.answer
                                : widget.question.text,
                            style: AppTextStyles.h2.copyWith(
                              color: AppColors.questionTextColor,
                              fontWeight: FontWeight.bold,
                              height: 1.3,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                    Icon(
                      Icons.help_outline,
                      size: 80,
                      color: AppColors.questionTextColor,
                    ),
                    if (AppModeConfig.isHostMode && !widget.showAnswer && widget.onShowAnswer != null) ...[
                      const SizedBox(height: AppSpacing.xl),
                      ElevatedButton(
                        onPressed: widget.onShowAnswer,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.timerBackground,
                          foregroundColor: AppColors.questionTextColor,
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.xl,
                            vertical: AppSpacing.lg,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Text(
                          'Показать ответ',
                          style: AppTextStyles.button.copyWith(
                            color: AppColors.questionTextColor,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                    if (AppModeConfig.isHostMode && widget.showAnswer) ...[
                      const SizedBox(height: AppSpacing.xl),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onCorrect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: AppColors.surface,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Правильно',
                                style: AppTextStyles.button.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(
                            child: ElevatedButton(
                              onPressed: widget.onIncorrect,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.error,
                                foregroundColor: AppColors.surface,
                                padding: const EdgeInsets.symmetric(
                                  vertical: AppSpacing.lg,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: Text(
                                'Неправильно',
                                style: AppTextStyles.button.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
