import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/question_editor_dialog.dart';
import '../models/game_model.dart';
import 'team_count_screen.dart';

class GameSetupScreen extends StatefulWidget {
  final String gameName;

  const GameSetupScreen({super.key, required this.gameName});

  @override
  State<GameSetupScreen> createState() => _GameSetupScreenState();
}

GameQuestionType _mapQuestionType(QuestionType t) {
  switch (t) {
    case QuestionType.normal:
      return GameQuestionType.normal;
    case QuestionType.bonus:
      return GameQuestionType.bonus;
    case QuestionType.cat:
      return GameQuestionType.cat;
  }
}

class _GameSetupScreenState extends State<GameSetupScreen> {
  static const List<int> _scores = [500, 1000, 1500, 2000, 2500];

  final List<String> _rounds = ['Раунд 1'];
  final List<int> _roundTimes = [60]; // seconds per round
  int _selectedRound = 0;

  // Per-round topics. Each round has its own list of topics.
  final List<List<_TopicRow>> _roundTopics = [
    [
      _TopicRow(name: 'Природа'),
      _TopicRow(name: 'Еда'),
      _TopicRow(name: 'Памятники'),
    ],
  ];

  List<_TopicRow> get _currentTopics => _roundTopics[_selectedRound];

  void _addRound() {
    setState(() {
      final num = _rounds.length + 1;
      _rounds.add('Раунд $num');
      _roundTimes.add(60);
      _roundTopics.add([_TopicRow(name: 'Тема 1')]);
      _selectedRound = _rounds.length - 1;
    });
  }

  void _addTopic() {
    setState(() {
      final num = _currentTopics.length + 1;
      _currentTopics.add(_TopicRow(name: 'Тема $num'));
    });
  }

  void _deleteTopic(int index) {
    setState(() {
      _currentTopics.removeAt(index);
    });
  }

  bool get _allQuestionsFilled {
    for (final topics in _roundTopics) {
      for (final topic in topics) {
        for (final q in topic.questions) {
          if (q == null || q.question.isEmpty) return false;
        }
      }
    }
    return true;
  }

  // Returns a human-readable description of the first unfilled cell found.
  String _firstMissingDescription() {
    for (int r = 0; r < _roundTopics.length; r++) {
      final topics = _roundTopics[r];
      for (int t = 0; t < topics.length; t++) {
        for (int s = 0; s < topics[t].questions.length; s++) {
          final q = topics[t].questions[s];
          if (q == null || q.question.isEmpty) {
            return '${_rounds[r]}, тема «${topics[t].name}», ${_scores[s]} очков';
          }
        }
      }
    }
    return '';
  }

  void _onSave() {
    if (!_allQuestionsFilled) {
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: const Color(0xFFFFF1E4),
          title: const Text(
            'Не все вопросы заполнены',
            style: TextStyle(
              color: Color(0xFF3A1800),
              fontWeight: FontWeight.w700,
            ),
          ),
          content: Text(
            'Заполните все вопросы перед сохранением.\n\nПервый незаполненный:\n${_firstMissingDescription()}',
            style: const TextStyle(color: Color(0xFF3A1800), fontSize: 16),
          ),
          actions: [
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFF863C15)),
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Понятно'),
            ),
          ],
        ),
      );
      return;
    }

    // Build GameModel from current state
    final game = GameModel(
      rounds: List.generate(_rounds.length, (r) {
        final topics = _roundTopics[r];
        return GameRoundModel(
          name: _rounds[r],
          timeSeconds: _roundTimes[r],
          topics: topics.map((t) {
            return GameTopicModel(
              name: t.name,
              questions: t.questions.map((q) {
                if (q == null) return null;
                return GameQuestionModel(
                  type: _mapQuestionType(q.type),
                  question: q.question,
                  answer: q.answer,
                );
              }).toList(),
            );
          }).toList(),
        );
      }),
    );

    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => TeamCountScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/bg.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TopBar(
                rounds: _rounds,
                times: _roundTimes,
                selectedRound: _selectedRound,
                onSelectRound: (i) => setState(() => _selectedRound = i),
                onAddRound: _addRound,
                onTimeChanged: (idx, secs) =>
                    setState(() => _roundTimes[idx] = secs),
                onSave: _onSave,
                canSave: _allQuestionsFilled,
              ),
              const SizedBox(height: 16),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _TopicsTable(
                    topics: _currentTopics,
                    scores: _scores,
                    onAddTopic: _addTopic,
                    onDeleteTopic: _deleteTopic,
                    onCellTap: (topicIdx, scoreIdx) async {
                      final existing =
                          _currentTopics[topicIdx].questions[scoreIdx];
                      final result = await showQuestionEditorDialog(
                        context,
                        score: _scores[scoreIdx],
                        existing: existing,
                      );
                      if (result != null && mounted) {
                        setState(() {
                          _currentTopics[topicIdx].questions[scoreIdx] =
                              result;
                        });
                      }
                    },
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Data ───────────────────────────────────────────────────────────────────

class _TopicRow {
  String name;
  // null = no question added yet
  List<QuestionData?> questions;

  _TopicRow({required this.name}) : questions = List.filled(5, null);
}

// ─── Top Bar ────────────────────────────────────────────────────────────────

class _TopBar extends StatefulWidget {
  final List<String> rounds;
  final List<int> times;
  final int selectedRound;
  final ValueChanged<int> onSelectRound;
  final VoidCallback onAddRound;
  final void Function(int idx, int secs) onTimeChanged;
  final VoidCallback onSave;
  final bool canSave;

  const _TopBar({
    required this.rounds,
    required this.times,
    required this.selectedRound,
    required this.onSelectRound,
    required this.onAddRound,
    required this.onTimeChanged,
    required this.onSave,
    required this.canSave,
  });

  @override
  State<_TopBar> createState() => _TopBarState();
}

class _TopBarState extends State<_TopBar> {
  int get _currentSeconds =>
      widget.times.length > widget.selectedRound
          ? widget.times[widget.selectedRound]
          : 60;

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(1, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  void _editTime() {
    int minutes = _currentSeconds ~/ 60;
    int secs = _currentSeconds % 60;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDlg) {
            return AlertDialog(
              backgroundColor: const Color(0xFFFFF1E4),
              title: const Text(
                'Время раунда',
                style: TextStyle(color: Color(0xFF3A1800)),
              ),
              content: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _TimeSpinner(
                    label: 'мин',
                    value: minutes,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setDlg(() => minutes = v),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8),
                    child: Text(
                      ':',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF3A1800),
                      ),
                    ),
                  ),
                  _TimeSpinner(
                    label: 'сек',
                    value: secs,
                    min: 0,
                    max: 59,
                    onChanged: (v) => setDlg(() => secs = v),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: const Text('Отмена'),
                ),
                FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF863C15),
                  ),
                  onPressed: () {
                    widget.onTimeChanged(
                        widget.selectedRound, minutes * 60 + secs);
                    Navigator.pop(ctx);
                  },
                  child: const Text('Сохранить'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Round cards
          ...widget.rounds.asMap().entries.map((entry) {
            final i = entry.key;
            final selected = i == widget.selectedRound;
            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () => widget.onSelectRound(i),
                child: selected
                    ? _ActiveRoundCard(
                        label: entry.value,
                        time: _formatTime(_currentSeconds),
                        onEditTime: _editTime,
                      )
                    : _InactiveRoundCard(label: entry.value),
              ),
            );
          }),

          // Add round button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: widget.onAddRound,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: const Color(0xFF9C532C),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.add, color: Colors.white, size: 28),
              ),
            ),
          ),

          const Spacer(),

          // Save button
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: GestureDetector(
              onTap: widget.onSave,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(
                  horizontal: 40,
                  vertical: 16,
                ),
                decoration: BoxDecoration(
                  gradient: widget.canSave
                      ? const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                        )
                      : const LinearGradient(
                          colors: [Color(0xFFBFBFBF), Color(0xFFAAAAAA)],
                        ),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Сохранить',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Active round card ───────────────────────────────────────────────────────

class _ActiveRoundCard extends StatelessWidget {
  final String label;
  final String time;
  final VoidCallback onEditTime;

  const _ActiveRoundCard({
    required this.label,
    required this.time,
    required this.onEditTime,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Round name pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 14),
            decoration: BoxDecoration(
              color: const Color(0xFF9C532C),
              borderRadius: BorderRadius.circular(50),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontFamily: 'SF Pro',
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.9,
                height: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 14),
          // Time row
          GestureDetector(
            onTap: onEditTime,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Время: $time',
                  style: const TextStyle(
                    color: Color(0xFF3A1800),
                    fontFamily: 'SF Pro',
                    fontSize: 22,
                    fontWeight: FontWeight.w500,
                    letterSpacing: -0.5,
                    height: 1.0,
                  ),
                ),
                const SizedBox(width: 10),
                SvgPicture.asset(
                  'assets/icons/edit.svg',
                  width: 22,
                  height: 22,
                  colorFilter: const ColorFilter.mode(
                    Color(0xFF3A1800),
                    BlendMode.srcIn,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Inactive round card ─────────────────────────────────────────────────────

class _InactiveRoundCard extends StatelessWidget {
  final String label;

  const _InactiveRoundCard({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: const Color(0xFF9C532C), width: 5),
        borderRadius: BorderRadius.circular(28),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF9C532C),
          fontFamily: 'SF Pro',
          fontSize: 28,
          fontWeight: FontWeight.w500,
          letterSpacing: -0.9,
          height: 1.0,
        ),
      ),
    );
  }
}

// ─── Time Spinner ────────────────────────────────────────────────────────────

class _TimeSpinner extends StatelessWidget {
  final String label;
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  const _TimeSpinner({
    required this.label,
    required this.value,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: () {
            if (value < max) onChanged(value + 1);
          },
          child: const Icon(Icons.keyboard_arrow_up, size: 32, color: Color(0xFF863C15)),
        ),
        Container(
          width: 64,
          alignment: Alignment.center,
          child: Text(
            value.toString().padLeft(2, '0'),
            style: const TextStyle(
              fontSize: 36,
              fontWeight: FontWeight.w600,
              color: Color(0xFF3A1800),
            ),
          ),
        ),
        GestureDetector(
          onTap: () {
            if (value > min) onChanged(value - 1);
          },
          child: const Icon(Icons.keyboard_arrow_down, size: 32, color: Color(0xFF863C15)),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF3A1800),
          ),
        ),
      ],
    );
  }
}

// ─── Topics Table ────────────────────────────────────────────────────────────

class _TopicsTable extends StatelessWidget {
  final List<_TopicRow> topics;
  final List<int> scores;
  final VoidCallback onAddTopic;
  final void Function(int) onDeleteTopic;
  final void Function(int topicIdx, int scoreIdx) onCellTap;

  const _TopicsTable({
    required this.topics,
    required this.scores,
    required this.onAddTopic,
    required this.onDeleteTopic,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          _TableHeader(scores: scores),
          const Divider(height: 1, color: Color(0xFFE8CCAB)),
          // Topic rows
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: topics.length + 1,
              separatorBuilder: (_, __) =>
                  const Divider(height: 1, color: Color(0xFFE8CCAB)),
              itemBuilder: (context, i) {
                if (i == topics.length) {
                  return _AddTopicRow(onTap: onAddTopic);
                }
                return _TopicTableRow(
                  topic: topics[i],
                  scores: scores,
                  onDelete: () => onDeleteTopic(i),
                  onCellTap: (scoreIdx) => onCellTap(i, scoreIdx),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TableHeader extends StatelessWidget {
  final List<int> scores;

  const _TableHeader({required this.scores});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: const Text(
              'Темы',
              style: TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 20,
                fontWeight: FontWeight.w700,
                letterSpacing: -0.4,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ...scores.map(
            (s) => Expanded(
              child: Center(
                child: Text(
                  s.toString(),
                  style: const TextStyle(
                    color: Color(0xFF3A1800),
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.4,
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 44),
        ],
      ),
    );
  }
}

class _TopicTableRow extends StatelessWidget {
  final _TopicRow topic;
  final List<int> scores;
  final VoidCallback onDelete;
  final void Function(int) onCellTap;

  const _TopicTableRow({
    required this.topic,
    required this.scores,
    required this.onDelete,
    required this.onCellTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        children: [
          SizedBox(
            width: 160,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: const Color(0xFFFFE4C4),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                topic.name,
                style: const TextStyle(
                  color: Color(0xFF3A1800),
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.3,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
          const SizedBox(width: 12),
          ...List.generate(scores.length, (i) {
            final question = topic.questions[i];
            final hasQuestion = question != null &&
                question.question.isNotEmpty;
            return Expanded(
              child: Center(
                child: GestureDetector(
                  onTap: () => onCellTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: hasQuestion
                          ? const Color(0xFFFFDDB8)
                          : const Color(0xFF863C15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      hasQuestion ? Icons.check : Icons.add,
                      color: hasQuestion
                          ? const Color(0xFF863C15)
                          : const Color(0xFFFFFFFF),
                      size: 24,
                    ),
                  ),
                ),
              ),
            );
          }),
          SizedBox(
            width: 44,
            child: GestureDetector(
              onTap: onDelete,
              child: SvgPicture.asset(
                'assets/icons/delete.svg',
                width: 26,
                height: 26,
                colorFilter: const ColorFilter.mode(
                  Color(0xFF3A1800),
                  BlendMode.srcIn,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AddTopicRow extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTopicRow({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: 160,
          height: 48,
          decoration: BoxDecoration(
            color: const Color(0xFF863C15),
            borderRadius: BorderRadius.circular(14),
          ),
          child: const Icon(Icons.add, color: Colors.white, size: 26),
        ),
      ),
    );
  }
}
