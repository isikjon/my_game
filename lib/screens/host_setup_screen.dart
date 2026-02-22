import 'dart:math';
import 'package:flutter/material.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/create_game_dialog.dart';
import 'game_board_screen.dart';

class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  final List<_TeamItem> _teams = [];
  final List<String> _games = [];
  bool _teamsSelectionMode = false;
  bool _gamesSelectionMode = false;
  final Set<int> _selectedTeamIndices = {};
  final Set<int> _selectedGameIndices = {};
  final _rng = Random();

  void _toggleTeamsSelectionMode() {
    setState(() {
      _teamsSelectionMode = !_teamsSelectionMode;
      if (!_teamsSelectionMode) _selectedTeamIndices.clear();
    });
  }

  void _toggleGamesSelectionMode() {
    setState(() {
      _gamesSelectionMode = !_gamesSelectionMode;
      if (!_gamesSelectionMode) _selectedGameIndices.clear();
    });
  }

  void _toggleTeamSelection(int index) {
    setState(() {
      if (_selectedTeamIndices.contains(index)) {
        _selectedTeamIndices.remove(index);
      } else {
        _selectedTeamIndices.add(index);
      }
    });
  }

  void _deleteSelectedTeams() {
    if (_selectedTeamIndices.isEmpty) return;
    setState(() {
      final indicesToRemove = _selectedTeamIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indicesToRemove) {
        _teams.removeAt(i);
      }
      _selectedTeamIndices.clear();
      _teamsSelectionMode = false;
    });
  }

  void _toggleGameSelection(int index) {
    setState(() {
      if (_selectedGameIndices.contains(index)) {
        _selectedGameIndices.remove(index);
      } else {
        _selectedGameIndices.add(index);
      }
    });
  }

  void _deleteSelectedGames() {
    if (_selectedGameIndices.isEmpty) return;
    setState(() {
      final indicesToRemove = _selectedGameIndices.toList()..sort((a, b) => b.compareTo(a));
      for (final i in indicesToRemove) {
        _games.removeAt(i);
      }
      _selectedGameIndices.clear();
      _gamesSelectionMode = false;
    });
  }

  Future<void> _addTeam() async {
    final name = await showAddTeamDialog(context);
    if (name != null && name.isNotEmpty) {
      setState(() {
        _teams.add(_TeamItem(
          name: name,
          rounds: 25,
          score: 100 + _rng.nextInt(9900),
        ));
      });
    }
  }

  Future<void> _addGame() async {
    final name = await showCreateGameDialog(context);
    if (name != null && name.isNotEmpty) {
      setState(() {
        _games.add(name);
      });
    }
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
          child: LayoutBuilder(
            builder: (context, constraints) {
              final dividerHeight = constraints.maxHeight.clamp(0.0, 400.0);
              return Row(
                children: [
                  Expanded(
                    child: _TeamsSection(
                      teams: _teams,
                      selectionMode: _teamsSelectionMode,
                      selectedIndices: _selectedTeamIndices,
                      onAddTeam: _addTeam,
                      onToggleSelectionMode: _toggleTeamsSelectionMode,
                      onToggleSelection: _toggleTeamSelection,
                      onDeleteSelected: _deleteSelectedTeams,
                    ),
                  ),
                  Center(
                    child: SizedBox(
                      width: 5,
                      height: dividerHeight,
                      child: Container(
                        color: Color(0xFF9C532C).withValues(alpha: 0.5),
                      ),
                    ),
                  ),
                  Expanded(
                    child: _GamesSection(
                      games: _games,
                      selectionMode: _gamesSelectionMode,
                      selectedIndices: _selectedGameIndices,
                      onAddGame: _addGame,
                      onToggleSelectionMode: _toggleGamesSelectionMode,
                      onToggleSelection: _toggleGameSelection,
                      onDeleteSelected: _deleteSelectedGames,
                      onStartGame: (i) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const GameBoardScreen(),
                          ),
                        );
                      },
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _TeamItem {
  final String name;
  final int rounds;
  final int score;

  _TeamItem({
    required this.name,
    required this.rounds,
    required this.score,
  });
}

class _TeamsSection extends StatelessWidget {
  final List<_TeamItem> teams;
  final bool selectionMode;
  final Set<int> selectedIndices;
  final VoidCallback onAddTeam;
  final VoidCallback onToggleSelectionMode;
  final void Function(int) onToggleSelection;
  final VoidCallback onDeleteSelected;

  const _TeamsSection({
    required this.teams,
    required this.selectionMode,
    required this.selectedIndices,
    required this.onAddTeam,
    required this.onToggleSelectionMode,
    required this.onToggleSelection,
    required this.onDeleteSelected,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndices.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              GestureDetector(
                onTap: onAddTeam,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                    ),
                    borderRadius: BorderRadius.circular(37.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Color(0xFFFFFFFF),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Добавить команду',
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (teams.isNotEmpty) ...[
                GestureDetector(
                  onTap: onToggleSelectionMode,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.delete_outline,
                      color: selectionMode
                          ? const Color(0xFF863C15)
                          : const Color(0xFF3A1800),
                      size: 32,
                    ),
                  ),
                ),
                if (selectionMode)
                  GestureDetector(
                    onTap: hasSelection ? onDeleteSelected : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: hasSelection
                            ? const Color(0xFF863C15)
                            : const Color(0xFF863C15).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete,
                            color: hasSelection
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF3A1800).withValues(alpha: 0.5),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Удалить',
                            style: TextStyle(
                              color: hasSelection
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3A1800).withValues(alpha: 0.5),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (teams.isEmpty) ...[
            const SizedBox(height: 48),
            Text(
              'Здесь еще нет команд, но уже можно создать',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
                height: 1.3,
                inherit: false,
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            ...List.generate(teams.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _TeamCard(
                  team: teams[i],
                  showSelection: selectionMode,
                  isSelected: selectedIndices.contains(i),
                  onTap: selectionMode ? () => onToggleSelection(i) : null,
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final _TeamItem team;
  final bool showSelection;
  final bool isSelected;
  final VoidCallback? onTap;

  const _TeamCard({
    required this.team,
    required this.showSelection,
    required this.isSelected,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBF7),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                team.name,
                style: const TextStyle(
                  color: Color(0xFF3A1800),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.play_arrow,
                  color: Color(0xFFF0B85E),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  team.rounds.toString(),
                  style: const TextStyle(
                    color: Color(0xFFF0B85E),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 24),
                const Icon(
                  Icons.star,
                  color: Color(0xFFF0B85E),
                  size: 24,
                ),
                const SizedBox(width: 8),
                Text(
                  team.score.toString(),
                  style: const TextStyle(
                    color: Color(0xFFF0B85E),
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (showSelection) ...[
                  const SizedBox(width: 24),
                  Container(
                    width: 28,
                    height: 28,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? const Color(0xFF863C15)
                          : Colors.transparent,
                      border: Border.all(
                        color: isSelected
                            ? const Color(0xFF863C15)
                            : const Color(0xFF9C532C).withValues(alpha: 0.6),
                        width: 2,
                      ),
                    ),
                    child: isSelected
                        ? const Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 18,
                          )
                        : null,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GamesSection extends StatelessWidget {
  final List<String> games;
  final bool selectionMode;
  final Set<int> selectedIndices;
  final VoidCallback onAddGame;
  final VoidCallback onToggleSelectionMode;
  final void Function(int) onToggleSelection;
  final VoidCallback onDeleteSelected;
  final void Function(int) onStartGame;

  const _GamesSection({
    required this.games,
    required this.selectionMode,
    required this.selectedIndices,
    required this.onAddGame,
    required this.onToggleSelectionMode,
    required this.onToggleSelection,
    required this.onDeleteSelected,
    required this.onStartGame,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndices.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 12,
            runSpacing: 12,
            children: [
              GestureDetector(
                onTap: onAddGame,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 40,
                    vertical: 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                    ),
                    borderRadius: BorderRadius.circular(37.5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.add,
                        color: Color(0xFFFFFFFF),
                        size: 28,
                      ),
                      const SizedBox(width: 16),
                      Text(
                        'Создать новую игру',
                        style: const TextStyle(
                          color: Color(0xFFFFFFFF),
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          letterSpacing: -0.5,
                          height: 1.0,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              if (games.isNotEmpty) ...[
                GestureDetector(
                  onTap: onToggleSelectionMode,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Icon(
                      Icons.delete_outline,
                      color: selectionMode
                          ? const Color(0xFF863C15)
                          : const Color(0xFF3A1800),
                      size: 32,
                    ),
                  ),
                ),
                if (selectionMode)
                  GestureDetector(
                    onTap: hasSelection ? onDeleteSelected : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 16,
                      ),
                      decoration: BoxDecoration(
                        color: hasSelection
                            ? const Color(0xFF863C15)
                            : const Color(0xFF863C15).withValues(alpha: 0.4),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.delete,
                            color: hasSelection
                                ? const Color(0xFFFFFFFF)
                                : const Color(0xFF3A1800).withValues(alpha: 0.5),
                            size: 22,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Удалить',
                            style: TextStyle(
                              color: hasSelection
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3A1800).withValues(alpha: 0.5),
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ],
          ),
          if (games.isEmpty) ...[
            const SizedBox(height: 48),
            Text(
              'Здесь еще нет игр, но уже можно создать',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Color(0xFF3A1800),
                fontSize: 28,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.5,
                height: 1.3,
                inherit: false,
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            ...List.generate(games.length, (i) {
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _GameCard(
                  name: games[i],
                  showSelection: selectionMode,
                  isSelected: selectedIndices.contains(i),
                  onTap: selectionMode ? () => onToggleSelection(i) : null,
                  onStart: () => onStartGame(i),
                ),
              );
            }),
          ],
        ],
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String name;
  final bool showSelection;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback onStart;

  const _GameCard({
    required this.name,
    required this.showSelection,
    required this.isSelected,
    this.onTap,
    required this.onStart,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBF7),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: onTap,
              behavior: HitTestBehavior.opaque,
              child: Text(
                name,
                style: const TextStyle(
                  color: Color(0xFF3A1800),
                  fontSize: 22,
                  fontWeight: FontWeight.w500,
                  letterSpacing: -0.5,
                  height: 1.2,
                ),
              ),
            ),
          ),
          if (showSelection) ...[
            Container(
              width: 28,
              height: 28,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isSelected
                    ? const Color(0xFF863C15)
                    : Colors.transparent,
                border: Border.all(
                  color: isSelected
                      ? const Color(0xFF863C15)
                      : const Color(0xFF9C532C).withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
              child: isSelected
                  ? const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 18,
                    )
                  : null,
            ),
          ],
          GestureDetector(
            onTap: onStart,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                ),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.play_arrow,
                    color: Color(0xFFFFFFFF),
                    size: 22,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    'Начать',
                    style: TextStyle(
                      color: Color(0xFFFFFFFF),
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      letterSpacing: -0.5,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
