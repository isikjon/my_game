import 'dart:async';
import 'package:flutter/material.dart';
import '../widgets/score_assignment_dialog.dart';

class PlayQuestionScreen extends StatefulWidget {
  final String question;
  final String answer;
  final int timerSeconds;
  final List<String> teams;
  final int scoreValue;

  const PlayQuestionScreen({
    super.key,
    required this.question,
    required this.answer,
    required this.timerSeconds,
    required this.teams,
    required this.scoreValue,
  });

  @override
  State<PlayQuestionScreen> createState() => _PlayQuestionScreenState();
}

class _PlayQuestionScreenState extends State<PlayQuestionScreen> {
  late int _seconds;
  Timer? _timer;
  bool _answerRevealed = false;
  bool _scoringTriggered = false;

  @override
  void initState() {
    super.initState();
    _seconds = widget.timerSeconds;
    _startTimer();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_seconds > 0) {
        setState(() => _seconds--);
      } else {
        _timer?.cancel();
        _triggerScoring();
      }
    });
  }

  Future<void> _triggerScoring() async {
    if (_scoringTriggered || !mounted) return;
    _scoringTriggered = true;
    _timer?.cancel();

    final team = await showScoreAssignmentDialog(
      context,
      teams: widget.teams,
      scoreValue: widget.scoreValue,
    );

    if (mounted) Navigator.pop(context, team);
  }

  String get _formattedTime {
    final m = (_seconds ~/ 60).toString().padLeft(2, '0');
    final s = (_seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      child: Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 720),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 32),
                padding: const EdgeInsets.fromLTRB(48, 40, 48, 40),
                decoration: BoxDecoration(
                  color: const Color(0xFFFFF1E4),
                  borderRadius: BorderRadius.circular(40),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Timer pill
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 32, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFDEB8),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: Text(
                        _formattedTime,
                        style: TextStyle(
                          color: _seconds <= 10
                              ? const Color(0xFFCC3300)
                              : const Color(0xFF3A1800),
                          fontSize: 32,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Question text
                    Text(
                      widget.question,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Color(0xFF3A1800),
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 36),
                    // Answer section
                    if (!_answerRevealed)
                      Wrap(
                        alignment: WrapAlignment.center,
                        spacing: 16,
                        runSpacing: 12,
                        children: [
                          // Reveal answer button
                          ElevatedButton(
                            onPressed: () =>
                                setState(() => _answerRevealed = true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFD566),
                              foregroundColor: const Color(0xFF3A1800),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 40, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              'Показать ответ',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                          // Skip to scoring
                          ElevatedButton(
                            onPressed: _triggerScoring,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF863C15),
                              foregroundColor: Colors.white,
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 32, vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(50),
                              ),
                            ),
                            child: const Text(
                              'Далее →',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                letterSpacing: -0.3,
                              ),
                            ),
                          ),
                        ],
                      ),
                    if (_answerRevealed) ...[
                      // Answer pill
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 40, vertical: 18),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFD566),
                          borderRadius: BorderRadius.circular(50),
                        ),
                        child: Text(
                          widget.answer,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFF3A1800),
                            fontSize: 24,
                            fontWeight: FontWeight.w700,
                            letterSpacing: -0.4,
                            height: 1.0,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      ElevatedButton(
                        onPressed: _triggerScoring,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF863C15),
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 48, vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(50),
                          ),
                        ),
                        child: const Text(
                          'Далее →',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    ),
    );
  }
}
