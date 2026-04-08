import 'package:flutter/material.dart';
import '../models/game_model.dart';
import '../models/game_state.dart';
import '../services/game_api_service.dart';
import '../widgets/add_team_dialog.dart';
import 'host_lobby_screen.dart';

class TeamCountScreen extends StatefulWidget {
  final GameModel game;
  final String? gameCode;

  const TeamCountScreen({super.key, required this.game, this.gameCode});

  @override
  State<TeamCountScreen> createState() => _TeamCountScreenState();
}

class _TeamCountScreenState extends State<TeamCountScreen> {
  final List<String> _teams = [];
  List<String> _existingTeamNames = [];

  @override
  void initState() {
    super.initState();
    _loadExistingTeams();
  }

  Future<void> _loadExistingTeams() async {
    final api = GameApiService();
    try {
      final names = await api.listTeams();
      if (!mounted) return;
      setState(() => _existingTeamNames = names);
    } catch (e) {
      debugPrint('[TeamCountScreen] Failed to load existing teams: $e');
    } finally {
      api.close();
    }
  }

  void _addTeam() async {
    final name = await showAddTeamDialog(context);
    if (name != null && name.isNotEmpty) {
      setState(() {
        if (!_teams.contains(name)) {
          _teams.add(name);
        }
      });
    }
  }

  void _removeTeam(int index) {
    setState(() => _teams.removeAt(index));
  }

  void _toggleExistingTeam(String name) {
    setState(() {
      if (_teams.contains(name)) {
        _teams.remove(name);
      } else {
        _teams.add(name);
      }
    });
  }

  Future<void> _onContinue() async {
    if (_teams.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Нужно минимум 2 команды'),
          backgroundColor: Color(0xFF863C15),
        ),
      );
      return;
    }

    final code = widget.gameCode;
    if (code != null) {
      final api = GameApiService();
      try {
        // Fetch current teams to avoid duplicates
        final existingTeams = await api.listTeamsForGame(code);
        final existingNames = existingTeams.map((t) => t.name).toSet();

        final teamsToAdd = _teams.where((n) => !existingNames.contains(n)).toList();
        if (teamsToAdd.isNotEmpty) {
          await api.addTeamsBulk(code, teamsToAdd);
        }
      } catch (_) {
        // Не блокируем игру, если сервер недоступен
      } finally {
        api.close();
      }
    }

    if (!mounted) return;

    // Convert GameModel rounds → LiveRoundState for real-time layer
    final liveRounds = widget.game.rounds
        .map((r) => LiveRoundState(
              name: r.name,
              timeSeconds: r.timeSeconds,
              topics: r.topics
                  .map((t) =>
                      LiveTopicState(name: t.name, questionIds: const []))
                  .toList(),
            ))
        .toList();

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => HostLobbyScreen(
          gameCode: widget.gameCode ?? '',
          teamNames: List.of(_teams),
          rounds: liveRounds,
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
          child: Stack(
            children: [
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
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
                            ...List.generate(
                                _teams.length,
                                (i) => Padding(
                                      padding: const EdgeInsets.only(right: 20),
                                      child: Stack(
                                        children: [
                                          _TeamCard(name: _teams[i]),
                                          Positioned(
                                            top: 0,
                                            right: 0,
                                            child: GestureDetector(
                                              onTap: () => _removeTeam(i),
                                              child: Container(
                                                padding:
                                                    const EdgeInsets.all(4),
                                                decoration: const BoxDecoration(
                                                  color: Color(0xFF863C15),
                                                  shape: BoxShape.circle,
                                                ),
                                                child: const Icon(Icons.close,
                                                    color: Colors.white,
                                                    size: 16),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    )),
                            // Add button
                            _AddTeamButton(onTap: _addTeam),
                          ],
                        ),
                      ),
                      if (_existingTeamNames.isNotEmpty) ...[
                        const SizedBox(height: 24),
                        const Text(
                          'Выбрать из ранее созданных:',
                          style: TextStyle(
                            color: Color(0xFF9C532C),
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 44,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: _existingTeamNames.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final name = _existingTeamNames[i];
                              final isSelected = _teams.contains(name);
                              return GestureDetector(
                                onTap: () => _toggleExistingTeam(name),
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 16),
                                  decoration: BoxDecoration(
                                    color: isSelected
                                        ? const Color(0xFF863C15)
                                        : const Color(0xFFFFF1E4),
                                    borderRadius: BorderRadius.circular(50),
                                    border: isSelected
                                        ? null
                                        : Border.all(
                                            color: const Color(0xFF863C15),
                                            width: 1.5),
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    name,
                                    style: TextStyle(
                                      color: isSelected
                                          ? Colors.white
                                          : const Color(0xFF3A1800),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                      const SizedBox(height: 40),
                      // Continue button
                      GestureDetector(
                        onTap: _onContinue,
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 32,
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
                          child: const Center(
                            child: Text(
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
              Positioned(
                left: 16,
                top: 16,
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF863C15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back,
                        color: Colors.white, size: 24),
                  ),
                ),
              ),
            ],
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
