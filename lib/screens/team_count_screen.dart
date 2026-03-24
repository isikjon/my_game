import 'package:flutter/material.dart';
import '../models/game_model.dart';
import 'play_game_board_screen.dart';

class TeamCountScreen extends StatefulWidget {
  final GameModel game;

  const TeamCountScreen({super.key, required this.game});

  @override
  State<TeamCountScreen> createState() => _TeamCountScreenState();
}

class _TeamCountScreenState extends State<TeamCountScreen> {
  final List<String> _teams = [
    'Команда 1',
    'Команда 2',
    'Команда 3',
    'Команда 4',
  ];

  void _addTeam() {
    setState(() {
      _teams.add('Команда ${_teams.length + 1}');
    });
  }

  void _onContinue() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => PlayGameBoardScreen(
          game: widget.game,
          teams: List.of(_teams),
        ),
      ),
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
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(left: 4, bottom: 28),
                  child: Text(
                    'Количество команд',
                    style: TextStyle(
                      color: Color(0xFF3A1800),
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      letterSpacing: -0.6,
                      height: 1.0,
                    ),
                  ),
                ),
                // Teams row
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ...List.generate(_teams.length, (i) => Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: _TeamCard(name: _teams[i]),
                      )),
                      // Add button
                      _AddTeamButton(onTap: _addTeam),
                    ],
                  ),
                ),
                const SizedBox(height: 40),
                // Continue button
                Center(
                  child: GestureDetector(
                    onTap: _onContinue,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 80,
                        vertical: 20,
                      ),
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                        ),
                        borderRadius: BorderRadius.circular(50),
                      ),
                      child: const Text(
                        'Продолжить',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 26,
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
          ),
        ),
      ),
    );
  }
}

// ─── Team card ───────────────────────────────────────────────────────────────

class _TeamCard extends StatelessWidget {
  final String name;

  const _TeamCard({required this.name});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 140,
          height: 140,
          decoration: BoxDecoration(
            color: const Color(0xFFFFF1E4),
            borderRadius: BorderRadius.circular(28),
          ),
          child: Center(
            child: Image.asset(
              'assets/images/users.png',
              width: 72,
              height: 72,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          name,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Color(0xFF3A1800),
            fontSize: 18,
            fontWeight: FontWeight.w600,
            letterSpacing: -0.4,
            height: 1.0,
          ),
        ),
      ],
    );
  }
}

// ─── Add button ──────────────────────────────────────────────────────────────

class _AddTeamButton extends StatelessWidget {
  final VoidCallback onTap;

  const _AddTeamButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 140,
        decoration: BoxDecoration(
          color: const Color(0xFF863C15),
          borderRadius: BorderRadius.circular(28),
        ),
        child: const Icon(
          Icons.add,
          color: Colors.white,
          size: 40,
        ),
      ),
    );
  }
}
