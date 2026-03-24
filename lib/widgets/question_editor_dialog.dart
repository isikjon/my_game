import 'package:flutter/material.dart';

// ─── Model ───────────────────────────────────────────────────────────────────

enum QuestionType { normal, bonus, cat }

class QuestionData {
  final QuestionType type;
  final String question;
  final String answer;

  const QuestionData({
    required this.type,
    required this.question,
    required this.answer,
  });
}

// ─── Entry point ─────────────────────────────────────────────────────────────

Future<QuestionData?> showQuestionEditorDialog(
  BuildContext context, {
  required int score,
  QuestionData? existing,
}) async {
  // If editing existing — skip type selection and go straight to editor.
  QuestionType? type;
  if (existing != null) {
    type = existing.type;
  } else {
    type = await _showTypeDialog(context);
    if (type == null) return null;
  }

  if (!context.mounted) return null;

  return showGeneralDialog<QuestionData>(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, __) => _QuestionAnswerDialog(
      score: score,
      type: type!,
      initialQuestion: existing?.question ?? '',
      initialAnswer: existing?.answer ?? '',
    ),
  );
}

// ─── Step 1: Question type ────────────────────────────────────────────────────

Future<QuestionType?> _showTypeDialog(BuildContext context) {
  return showGeneralDialog<QuestionType>(
    context: context,
    barrierDismissible: true,
    barrierLabel: 'Close',
    barrierColor: Colors.black.withValues(alpha: 0.72),
    transitionDuration: const Duration(milliseconds: 280),
    transitionBuilder: (_, anim, __, child) => FadeTransition(
      opacity: CurvedAnimation(parent: anim, curve: Curves.easeOut),
      child: ScaleTransition(
        scale: Tween(begin: 0.92, end: 1.0).animate(
          CurvedAnimation(parent: anim, curve: Curves.easeOutCubic),
        ),
        child: child,
      ),
    ),
    pageBuilder: (ctx, _, __) => const _QuestionTypeDialog(),
  );
}

class _QuestionTypeDialog extends StatelessWidget {
  const _QuestionTypeDialog();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 28),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Выберите тип вопроса',
                    style: TextStyle(
                      color: Color(0xFF3A1800),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          color: Color(0xFF3A1800), size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: _TypeCard(
                      imagePath: 'assets/images/q_normal.png',
                      label: 'Обычный',
                      onTap: () =>
                          Navigator.pop(context, QuestionType.normal),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      imagePath: 'assets/images/q_bonus.png',
                      label: 'Бонус',
                      onTap: () =>
                          Navigator.pop(context, QuestionType.bonus),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _TypeCard(
                      imagePath: 'assets/images/q_cat.png',
                      label: 'Кот в мешке',
                      onTap: () =>
                          Navigator.pop(context, QuestionType.cat),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TypeCard extends StatelessWidget {
  final String imagePath;
  final String label;
  final VoidCallback onTap;

  const _TypeCard({
    required this.imagePath,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Image.asset(imagePath, width: 72, height: 72, fit: BoxFit.contain),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 15,
                fontWeight: FontWeight.w600,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Steps 2+3: Question & answer editor ─────────────────────────────────────

class _QuestionAnswerDialog extends StatefulWidget {
  final int score;
  final QuestionType type;
  final String initialQuestion;
  final String initialAnswer;

  const _QuestionAnswerDialog({
    required this.score,
    required this.type,
    required this.initialQuestion,
    required this.initialAnswer,
  });

  @override
  State<_QuestionAnswerDialog> createState() => _QuestionAnswerDialogState();
}

class _QuestionAnswerDialogState extends State<_QuestionAnswerDialog> {
  bool _showAnswer = false;
  late final TextEditingController _questionCtrl;
  late final TextEditingController _answerCtrl;

  @override
  void initState() {
    super.initState();
    _questionCtrl = TextEditingController(text: widget.initialQuestion);
    _answerCtrl = TextEditingController(text: widget.initialAnswer);
  }

  @override
  void dispose() {
    _questionCtrl.dispose();
    _answerCtrl.dispose();
    super.dispose();
  }

  void _save() {
    Navigator.pop(
      context,
      QuestionData(
        type: widget.type,
        question: _questionCtrl.text.trim(),
        answer: _answerCtrl.text.trim(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 40),
          padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E4),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    _showAnswer ? 'Ответ' : 'Вопрос на ${widget.score}',
                    style: TextStyle(
                      color: const Color(0xFF3A1800),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.4,
                      decoration: _showAnswer
                          ? TextDecoration.underline
                          : TextDecoration.none,
                      decorationColor: const Color(0xFF3A1800),
                      decorationThickness: 2,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    behavior: HitTestBehavior.opaque,
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          color: Color(0xFF3A1800), size: 26),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Text area — question
              if (!_showAnswer)
                Container(
                  key: const ValueKey('question'),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDEB8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _questionCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Введите вопрос',
                      hintStyle: TextStyle(
                        color: const Color(0xFF3A1800).withValues(alpha: 0.4),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF3A1800),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              // Text area — answer
              if (_showAnswer)
                Container(
                  key: const ValueKey('answer'),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFDEB8),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: TextField(
                    controller: _answerCtrl,
                    maxLines: 5,
                    decoration: InputDecoration(
                      hintText: 'Введите правильный ответ',
                      hintStyle: TextStyle(
                        color: const Color(0xFF3A1800).withValues(alpha: 0.4),
                        fontSize: 17,
                        fontWeight: FontWeight.w400,
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.all(18),
                    ),
                    style: const TextStyle(
                      color: Color(0xFF3A1800),
                      fontSize: 17,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () =>
                          setState(() => _showAnswer = !_showAnswer),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE8841A),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Ответ',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _save,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF863C15),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(50),
                        ),
                      ),
                      child: const Text(
                        'Сохранить',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.3,
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
    );
  }
}
