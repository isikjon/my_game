import 'package:flutter/material.dart';
import '../data/questions_data.dart';
import 'question_screen.dart';

class GameBoardScreen extends StatelessWidget {
  const GameBoardScreen({super.key});

  static const List<String> _categories = [
    'Природа',
    'Еда',
    'Памятники',
    'История',
    'Книги',
  ];

  static const List<int> _scores = [500, 1000, 1500, 2000, 2500];

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
          child: LayoutBuilder(
            builder: (context, constraints) {
              return Padding(
                padding: EdgeInsets.symmetric(
                  horizontal: constraints.maxWidth * 0.06,
                  vertical: constraints.maxHeight * 0.12,
                ),
                child: Center(
                  child: FittedBox(
                    fit: BoxFit.contain,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: List.generate(_categories.length, (index) {
                        return Padding(
                          padding: EdgeInsets.only(
                            bottom:
                                index < _categories.length - 1 ? 25.0 : 0,
                          ),
                          child: _buildRow(context, _categories[index]),
                        );
                      }),
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

  Widget _buildRow(BuildContext context, String category) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _CategoryButton(label: category),
        const SizedBox(width: 50),
        ...List.generate(_scores.length, (index) {
          return Padding(
            padding: EdgeInsets.only(
              right: index < _scores.length - 1 ? 30.0 : 0,
            ),
            child: _ScoreButton(
              score: _scores[index],
              onTap: () {
                final question =
                    questionsData[category]?[_scores[index]] ?? '';
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QuestionScreen(question: question),
                  ),
                );
              },
            ),
          );
        }),
      ],
    );
  }
}

class _CategoryButton extends StatelessWidget {
  final String label;

  const _CategoryButton({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 542.5,
      height: 117.5,
      decoration: BoxDecoration(
        color: const Color(0xFFFFF1E4),
        borderRadius: BorderRadius.circular(37.5),
      ),
      alignment: Alignment.center,
      child: Text(
        label,
        style: const TextStyle(
          color: Color(0xFF3A1800),
          fontSize: 50,
          fontWeight: FontWeight.w600,
          letterSpacing: -0.9,
          height: 1.0,
        ),
      ),
    );
  }
}

class _ScoreButton extends StatelessWidget {
  final int score;
  final VoidCallback onTap;

  const _ScoreButton({required this.score, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 271,
        height: 117.5,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFA35A33), Color(0xFF863C15)],
          ),
          borderRadius: BorderRadius.circular(37.5),
        ),
        alignment: Alignment.center,
        child: Text(
          score.toString(),
          style: const TextStyle(
            color: Color(0xFFFFFFFF),
            fontSize: 60,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.9,
            height: 1.0,
          ),
        ),
      ),
    );
  }
}
