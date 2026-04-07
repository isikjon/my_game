import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'play_question_screen.dart';
import 'scoreboard_screen.dart';

class PlayGameBoardScreen extends StatefulWidget {
  final GameModel game;
  final List<String> teams;

  const PlayGameBoardScreen({
    super.key,
    required this.game,
    required this.teams,
  });

  @override
  State<PlayGameBoardScreen> createState() => _PlayGameBoardScreenState();
}

class _PlayGameBoardScreenState extends State<PlayGameBoardScreen> {
  static const List<int> _scores = [500, 1000, 1500, 2000, 2500];

  int _currentRound = 0;
  late Map<String, int> _teamScores;
  // usedQuestions[topicIdx][scoreIdx]
  late List<List<bool>> _used;

  GameRoundModel get _round =>
      widget.game.rounds[_currentRound];

  @override
  void initState() {
    super.initState();
    _teamScores = {for (final t in widget.teams) t: 0};
    _initRoundState();
  }

  void _initRoundState() {
    _used = List.generate(
      _round.topics.length,
      (_) => List.filled(5, false),
    );
  }

  Future<void> _onCellTap(int topicIdx, int scoreIdx) async {
    if (_used[topicIdx][scoreIdx]) return;

    final question = _round.topics[topicIdx].questions[scoreIdx];
    if (question == null) return;

    final winner = await Navigator.push<String?>(
      context,
      MaterialPageRoute(
        builder: (_) => PlayQuestionScreen(
          question: question.question,
          answer: question.answer,
          timerSeconds: _round.timeSeconds,
          teams: widget.teams,
          scoreValue: _scores[scoreIdx],
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _used[topicIdx][scoreIdx] = true;
      if (winner != null && winner.isNotEmpty) {
        _teamScores[winner] = (_teamScores[winner] ?? 0) + _scores[scoreIdx];
      }
    });
  }

  void _onResults() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ScoreboardScreen(
          teams: widget.teams,
          scores: _teamScores,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final topics = _round.topics;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.05,
                  vertical: constraints.maxHeight * 0.08,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Round tabs (if more than 1)
                        if (widget.game.rounds.length > 1) ...[
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: List.generate(
                              widget.game.rounds.length,
                              (ri) => Padding(
                                padding: EdgeInsets.only(
                                    right: ri < widget.game.rounds.length - 1
                                        ? 16
                                        : 0),
                                child: GestureDetector(
                                  onTap: () {
                                    if (ri == _currentRound) return;
                                    setState(() {
                                      _currentRound = ri;
                                      _initRoundState();
                                    });
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 32, vertical: 14),
                                    decoration: BoxDecoration(
                                      color: ri == _currentRound
                                          ? const Color(0xFF863C15)
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(50),
                                      border: ri != _currentRound
                                          ? Border.all(
                                              color: const Color(0xFF863C15),
                                              width: 3)
                                          : null,
                                    ),
                                    child: Text(
                                      widget.game.rounds[ri].name,
                                      style: TextStyle(
                                        color: ri == _currentRound
                                            ? Colors.white
                                            : const Color(0xFF863C15),
                                        fontSize: 24,
                                        fontWeight: FontWeight.w600,
                                        letterSpacing: -0.4,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 30),
                        ],
                        // Grid
                        ...List.generate(topics.length, (ti) {
                          return Padding(
                            padding: EdgeInsets.only(
                              bottom: ti < topics.length - 1 ? 20.0 : 0,
                            ),
                            child: _GridRow(
                              categoryName: topics[ti].name,
                              scores: _scores,
                              usedScores: _used[ti],
                              onScoreTap: (si) => _onCellTap(ti, si),
                            ),
                          );
                        }),
                        const SizedBox(height: 40),
                        // Итоги button
                        GestureDetector(
                          onTap: _onResults,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 80, vertical: 22),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE8841A),
                              borderRadius: BorderRadius.circular(50),
                            ),
                            child: const Text(
                              'Итоги',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.w700,
                                letterSpacing: -0.6,
                                height: 1.0,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ─── Grid row ────────────────────────────────────────────────────────────────

class _GridRow extends StatelessWidget {
  final String categoryName;
  final List<int> scores;
  final List<bool> usedScores;
  final void Function(int) onScoreTap;

  const _GridRow({
    required this.categoryName,
    required this.scores,
    required this.usedScores,
    required this.onScoreTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Category name
        Container(
          width: 280,
          height: 90,
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBF7),
            borderRadius: BorderRadius.circular(22),
          ),
          alignment: Alignment.center,
          child: Text(
            categoryName,
            style: const TextStyle(
              color: Color(0xFF3A1800),
              fontSize: 28,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.5,
              height: 1.0,
            ),
          ),
        ),
        const SizedBox(width: 20),
        // Score buttons
        ...List.generate(scores.length, (si) {
          final used = usedScores[si];
          return Padding(
            padding: EdgeInsets.only(right: si < scores.length - 1 ? 16 : 0),
            child: GestureDetector(
              onTap: used ? null : () => onScoreTap(si),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                width: 140,
                height: 90,
                decoration: BoxDecoration(
                  color: used
                      ? const Color(0xFFD4B89A)
                      : const Color(0xFF863C15),
                  borderRadius: BorderRadius.circular(22),
                ),
                alignment: Alignment.center,
                child: Text(
                  scores[si].toString(),
                  style: TextStyle(
                    color: used
                        ? const Color(0xFFB89070)
                        : const Color(0xFFFFFFFF),
                    fontSize: 32,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          );
        }),
      ],
    );
  }
}
