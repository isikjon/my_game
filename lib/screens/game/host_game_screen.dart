import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../models/game_model.dart';
import '../../models/team_model.dart';
import '../../models/round_model.dart';
import '../../models/topic_model.dart';
import '../../models/question_model.dart';
import '../../config/app_mode.dart';
import 'question_screen.dart';

class HostGameScreen extends StatefulWidget {
  final GameModel? game;

  const HostGameScreen({super.key, this.game});

  @override
  State<HostGameScreen> createState() => _HostGameScreenState();
}

class _HostGameScreenState extends State<HostGameScreen> {
  GameModel? _currentGame;
  String? _selectedQuestionId;
  bool _showAnswer = false;

  @override
  void initState() {
    super.initState();
    _currentGame = widget.game ?? _createDemoGame();
    AppModeConfig.setMode(AppMode.host);
  }

  GameModel _createDemoGame() {
    return GameModel(
      id: 'demo',
      name: 'Демо игра',
      rounds: [
        RoundModel(
          id: 'round1',
          name: 'Первый раунд',
          number: 1,
          topics: [
            TopicModel(
              id: 'topic1',
              name: 'Природа',
              questions: List.generate(5, (i) => QuestionModel(
                id: 'q1_${i + 1}',
                text: 'Вопрос о природе ${i + 1}',
                answer: 'Ответ ${i + 1}',
                points: [500, 1000, 1500, 2000, 2500][i],
              )),
            ),
            TopicModel(
              id: 'topic2',
              name: 'Еда',
              questions: List.generate(5, (i) => QuestionModel(
                id: 'q2_${i + 1}',
                text: 'Вопрос о еде ${i + 1}',
                answer: 'Ответ ${i + 1}',
                points: [500, 1000, 1500, 2000, 2500][i],
              )),
            ),
            TopicModel(
              id: 'topic3',
              name: 'Памятники',
              questions: List.generate(5, (i) => QuestionModel(
                id: 'q3_${i + 1}',
                text: 'Вопрос о памятниках ${i + 1}',
                answer: 'Ответ ${i + 1}',
                points: [500, 1000, 1500, 2000, 2500][i],
              )),
            ),
            TopicModel(
              id: 'topic4',
              name: 'История',
              questions: List.generate(5, (i) => QuestionModel(
                id: 'q4_${i + 1}',
                text: 'Вопрос об истории ${i + 1}',
                answer: 'Ответ ${i + 1}',
                points: [500, 1000, 1500, 2000, 2500][i],
              )),
            ),
            TopicModel(
              id: 'topic5',
              name: 'Книги',
              questions: List.generate(5, (i) => QuestionModel(
                id: 'q5_${i + 1}',
                text: 'Вопрос о книгах ${i + 1}',
                answer: 'Ответ ${i + 1}',
                points: [500, 1000, 1500, 2000, 2500][i],
              )),
            ),
          ],
        ),
      ],
      teams: [
        TeamModel(id: 'team1', name: 'Команда 1', score: 0),
        TeamModel(id: 'team2', name: 'Команда 2', score: 0),
        TeamModel(id: 'team3', name: 'Команда 3', score: 0),
      ],
    );
  }

  void _selectQuestion(String questionId) {
    final question = _findQuestion(questionId);
    if (question != null && !question.isAnswered) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => QuestionScreen(
            question: question,
            onShowAnswer: () {
              setState(() {
                _showAnswer = true;
              });
            },
            onCorrect: () {
              _awardPoints(questionId, question.points);
              Navigator.pop(context);
            },
            onIncorrect: () {
              Navigator.pop(context);
            },
            showAnswer: _showAnswer,
            timeRemaining: 35,
          ),
        ),
      ).then((_) {
        setState(() {
          _showAnswer = false;
        });
      });
    }
  }

  QuestionModel? _findQuestion(String questionId) {
    for (final round in _currentGame!.rounds) {
      for (final topic in round.topics) {
        for (final question in topic.questions) {
          if (question.id == questionId) {
            return question;
          }
        }
      }
    }
    return null;
  }

  void _awardPoints(String questionId, int points) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Присудить очки'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _currentGame!.teams.map((team) {
            return ListTile(
              title: Text(team.name),
              subtitle: Text('Текущие очки: ${team.score}'),
              trailing: Text('+$points'),
              onTap: () {
                setState(() {
                  final teamIndex = _currentGame!.teams
                      .indexWhere((t) => t.id == team.id);
                  if (teamIndex != -1) {
                    final updatedTeam = _currentGame!.teams[teamIndex]
                        .copyWith(score: _currentGame!.teams[teamIndex].score + points);
                    _currentGame!.teams[teamIndex] = updatedTeam;
                    
                    final question = _findQuestion(questionId);
                    if (question != null) {
                      question.isAnswered = true;
                      question.answeredByTeamId = team.id;
                    }
                  }
                });
                Navigator.pop(context);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_currentGame == null) {
      return const Scaffold(
        body: Center(
          child: Text('Игра не выбрана'),
        ),
      );
    }

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
          child: Column(
            children: [
              if (_currentGame!.teams.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: _currentGame!.teams.map((team) {
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            team.name,
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${team.score}',
                            style: AppTextStyles.h3.copyWith(
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              Expanded(
                child: _buildGameField(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGameField() {
    if (_currentGame!.rounds.isEmpty) {
      return const Center(
        child: Text('Нет раундов'),
      );
    }

    final currentRound = _currentGame!.rounds.first;
    
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 2,
            child: _buildCategoryColumn(currentRound),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            flex: 5,
            child: _buildQuestionsGrid(currentRound),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryColumn(RoundModel round) {
    return Column(
      children: round.topics.asMap().entries.map((entry) {
        final index = entry.key;
        final topic = entry.value;
        final isLast = index == round.topics.length - 1;
        
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(
              bottom: isLast ? 0 : AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: AppColors.categoryCard,
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Text(
                  topic.name,
                  style: AppTextStyles.bodyLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildQuestionsGrid(RoundModel round) {
    final points = [500, 1000, 1500, 2000, 2500];
    
    return Column(
      children: points.asMap().entries.map((pointEntry) {
        final rowIndex = pointEntry.key;
        final pointValue = pointEntry.value;
        final isLastRow = rowIndex == points.length - 1;
        
        return Expanded(
          child: Row(
            children: round.topics.asMap().entries.map((topicEntry) {
              final colIndex = topicEntry.key;
              final topic = topicEntry.value;
              final isLastCol = colIndex == round.topics.length - 1;
              
              if (rowIndex >= topic.questions.length) {
                return Expanded(child: Container());
              }
              
              final question = topic.questions[rowIndex];
              final isAnswered = question.isAnswered;
              
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(
                    right: isLastCol ? 0 : AppSpacing.sm,
                    bottom: isLastRow ? 0 : AppSpacing.sm,
                  ),
                  child: GestureDetector(
                    onTap: isAnswered ? null : () => _selectQuestion(question.id),
                    child: Container(
                      decoration: BoxDecoration(
                        color: isAnswered
                            ? AppColors.textLight.withOpacity(0.5)
                            : AppColors.questionCard,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.shadow,
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Center(
                        child: Text(
                          '${question.points}',
                          style: AppTextStyles.h4.copyWith(
                            color: AppColors.questionCardText,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        );
      }).toList(),
    );
  }
}
