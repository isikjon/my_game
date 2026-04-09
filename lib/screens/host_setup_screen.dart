import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../widgets/add_team_dialog.dart';
import '../widgets/create_game_dialog.dart';
import '../services/game_api_service.dart';
import '../services/session_service.dart';
import 'game_setup_screen.dart';
import 'team_count_screen.dart';

class HostSetupScreen extends StatefulWidget {
  const HostSetupScreen({super.key});

  @override
  State<HostSetupScreen> createState() => _HostSetupScreenState();
}

class _HostGameItem {
  final String name;
  /// Код из POST /api/games; null если сервер недоступен при создании.
  final String? serverCode;

  _HostGameItem({required this.name, this.serverCode});
}

class _HostSetupScreenState extends State<HostSetupScreen> {
  final List<_TeamItem> _teams = [];
  final List<_HostGameItem> _games = [];
  bool _teamsSelectionMode = false;
  bool _gamesSelectionMode = false;
  final Set<int> _selectedTeamIndices = {};
  final Set<int> _selectedGameIndices = {};
  bool _isLoading = false;
  int? _loadingGameIndex;

  Future<void> _loadData() async {
    if (_isLoading) return;
    setState(() => _isLoading = true);
    final api = GameApiService();
    try {
      final games = await api.listGames();
      final teamNames = await api.listTeams();
      
      if (!mounted) return;
      setState(() {
        _games.clear();
        _games.addAll(games.map((g) => _HostGameItem(
              name: g['name'] ?? '',
              serverCode: g['code'],
            )));
        _teams.clear();
        _teams.addAll(teamNames.map((name) => _TeamItem(name: name)));
      });
    } catch (e) {
      debugPrint('[HostSetupScreen] _loadData error: $e');
    } finally {
      api.close();
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void initState() {
    super.initState();
    _loadData();
    // Предзагружаем SVG-иконки в кэш, чтобы не было лага при первом рендере
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      for (final path in const [
        'assets/icons/delete.svg',
        'assets/icons/play_button.svg',
        'assets/icons/star-circle.svg',
      ]) {
        final loader = SvgAssetLoader(path);
        svg.cache.putIfAbsent(
          loader.cacheKey(null),
          () => loader.loadBytes(null),
        );
      }
    });
  }

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

  Future<void> _deleteSelectedGames() async {
    if (_selectedGameIndices.isEmpty) return;
    final api = GameApiService();
    try {
      final indicesToRemove = _selectedGameIndices.toList()
        ..sort((a, b) => b.compareTo(a));
      for (final i in indicesToRemove) {
        final code = _games[i].serverCode;
        if (code != null) await api.deleteGame(code);
        if (!mounted) return;
        setState(() {
          _games.removeAt(i);
        });
      }
      if (!mounted) return;
      setState(() {
        _selectedGameIndices.clear();
        _gamesSelectionMode = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Ошибка удаления игры: $e'),
          backgroundColor: const Color(0xFF863C15),
        ),
      );
    } finally {
      api.close();
    }
  }

  Future<void> _addTeam() async {
    final name = await showAddTeamDialog(context);
    if (name != null && name.isNotEmpty) {
      setState(() {
        _teams.add(_TeamItem(
          name: name,
        ));
      });
    }
  }

  Future<void> _addGame() async {
    final name = await showCreateGameDialog(context);
    if (name == null || name.isEmpty) return;

    if (!mounted) return;
    SessionService.save(GameSession(screen: 'game_setup', gameName: name));
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GameSetupScreen(gameName: name),
      ),
    );

    // Restore session to host_setup when we return here
    SessionService.save(const GameSession(screen: 'host_setup'));
    if (mounted) _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
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
              LayoutBuilder(
                builder: (context, constraints) {
                  final sectionHeight = constraints.maxHeight;
                  return Row(
                    children: [
                      Expanded(
                        child: RepaintBoundary(
                          child: _GamesSection(
                            sectionHeight: sectionHeight,
                            games: _games,
                            selectionMode: _gamesSelectionMode,
                            selectedIndices: _selectedGameIndices,
                            onAddGame: _addGame,
                            onToggleSelectionMode: _toggleGamesSelectionMode,
                            onToggleSelection: _toggleGameSelection,
                            onDeleteSelected: _deleteSelectedGames,
                            loadingGameIndex: _loadingGameIndex,
                            onStartGame: (i) async {
                              if (_isLoading) return;
                              final g = _games[i];
                              final code = g.serverCode;
                              if (code == null) return;

                              setState(() {
                                _isLoading = true;
                                _loadingGameIndex = i;
                              });

                              final api = GameApiService();
                              try {
                                final result = await api.fetchGame(code);
                                if (!mounted) return;
                                SessionService.save(GameSession(screen: 'team_count', gameCode: code));
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => TeamCountScreen(
                                      game: result.game,
                                      gameCode: code,
                                    ),
                                  ),
                                );
                              } catch (e) {
                                if (!mounted) return;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Ошибка загрузки игры: $e'),
                                    backgroundColor: const Color(0xFF863C15),
                                  ),
                                );
                              } finally {
                                api.close();
                                if (mounted) {
                                  setState(() {
                                    _isLoading = false;
                                    _loadingGameIndex = null;
                                  });
                                }
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
              Positioned(
                left: 16,
                top: 16,
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () {
                        SessionService.clear();
                        Navigator.pop(context);
                      },
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
                    const SizedBox(width: 12),
                    GestureDetector(
                      onTap: _loadData,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF863C15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: _isLoading && _loadingGameIndex == null
                            ? const SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.refresh,
                                color: Colors.white, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamItem {
  final String name;

  _TeamItem({
    required this.name,
  });
}

class _TeamsSection extends StatelessWidget {
  final double sectionHeight;
  final List<_TeamItem> teams;
  final bool selectionMode;
  final Set<int> selectedIndices;
  final VoidCallback onAddTeam;
  final VoidCallback onToggleSelectionMode;
  final void Function(int) onToggleSelection;
  final VoidCallback onDeleteSelected;

  const _TeamsSection({
    required this.sectionHeight,
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
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: sectionHeight - 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAddTeam,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                      ),
                      borderRadius: BorderRadius.circular(37.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: Color(0xFFFFFFFF),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Добавить команду',
                            style: TextStyle(
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
                ),
              ),
              if (teams.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggleSelectionMode,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/icons/delete.svg',
                      width: 28,
                      height: 28,
                      colorFilter: ColorFilter.mode(
                        selectionMode
                            ? const Color(0xFF863C15)
                            : const Color(0xFF3A1800),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                if (selectionMode)
                  GestureDetector(
                    onTap: hasSelection ? onDeleteSelected : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                          SvgPicture.asset(
                            'assets/icons/delete.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              hasSelection
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3A1800).withValues(alpha: 0.5),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Удалить',
                            style: TextStyle(
                              color: hasSelection
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3A1800).withValues(alpha: 0.5),
                              fontSize: 16,
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
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
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
  final double sectionHeight;
  final List<_HostGameItem> games;
  final bool selectionMode;
  final Set<int> selectedIndices;
  final VoidCallback onAddGame;
  final VoidCallback onToggleSelectionMode;
  final void Function(int) onToggleSelection;
  final VoidCallback onDeleteSelected;
  final void Function(int) onStartGame;
  final int? loadingGameIndex;

  const _GamesSection({
    required this.sectionHeight,
    required this.games,
    required this.selectionMode,
    required this.selectedIndices,
    required this.onAddGame,
    required this.onToggleSelectionMode,
    required this.onToggleSelection,
    required this.onDeleteSelected,
    required this.onStartGame,
    this.loadingGameIndex,
  });

  @override
  Widget build(BuildContext context) {
    final hasSelection = selectedIndices.isNotEmpty;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(minHeight: sectionHeight - 48),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onAddGame,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 18,
                    ),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [Color(0xFFA35A33), Color(0xFF863C15)],
                      ),
                      borderRadius: BorderRadius.circular(37.5),
                    ),
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.add,
                            color: Color(0xFFFFFFFF),
                            size: 28,
                          ),
                          const SizedBox(width: 14),
                          const Text(
                            'Создать новую игру',
                            style: TextStyle(
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
                ),
              ),
              if (games.isNotEmpty) ...[
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: onToggleSelectionMode,
                  behavior: HitTestBehavior.opaque,
                  child: Padding(
                    padding: const EdgeInsets.all(10),
                    child: SvgPicture.asset(
                      'assets/icons/delete.svg',
                      width: 28,
                      height: 28,
                      colorFilter: ColorFilter.mode(
                        selectionMode
                            ? const Color(0xFF863C15)
                            : const Color(0xFF3A1800),
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                ),
                if (selectionMode)
                  GestureDetector(
                    onTap: hasSelection ? onDeleteSelected : null,
                    behavior: HitTestBehavior.opaque,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
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
                          SvgPicture.asset(
                            'assets/icons/delete.svg',
                            width: 20,
                            height: 20,
                            colorFilter: ColorFilter.mode(
                              hasSelection
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3A1800)
                                      .withValues(alpha: 0.5),
                              BlendMode.srcIn,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'Удалить',
                            style: TextStyle(
                              color: hasSelection
                                  ? const Color(0xFFFFFFFF)
                                  : const Color(0xFF3A1800)
                                      .withValues(alpha: 0.5),
                              fontSize: 16,
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
            SizedBox(
              height: 100,
              child: Center(
                child: Text(
                  'Здесь еще нет игр, но уже можно \nсоздать',
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
              ),
            ),
          ] else ...[
            const SizedBox(height: 32),
            ...List.generate(games.length, (i) {
              final g = games[i];
              return Padding(
                padding: const EdgeInsets.only(bottom: 16),
                child: _GameCard(
                  name: g.name,
                  serverCode: g.serverCode,
                  showSelection: selectionMode,
                  isSelected: selectedIndices.contains(i),
                  onTap: selectionMode ? () => onToggleSelection(i) : null,
                  onStart: () => onStartGame(i),
                  isLoading: loadingGameIndex == i,
                ),
              );
            }),
          ],
        ],
        ),
      ),
    );
  }
}

class _GameCard extends StatelessWidget {
  final String name;
  final String? serverCode;
  final bool showSelection;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback onStart;
  final bool isLoading;

  const _GameCard({
    required this.name,
    this.serverCode,
    required this.showSelection,
    required this.isSelected,
    this.onTap,
    required this.onStart,
    this.isLoading = false,
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      color: Color(0xFF3A1800),
                      fontSize: 22,
                      fontWeight: FontWeight.w500,
                      letterSpacing: -0.5,
                      height: 1.2,
                    ),
                  ),
                  if (serverCode != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Сервер · код $serverCode',
                        style: TextStyle(
                          color: const Color(0xFF3A1800).withValues(alpha: 0.65),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                  else
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        'Без сервера',
                        style: TextStyle(
                          color: const Color(0xFF9C532C).withValues(alpha: 0.9),
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            if (showSelection) ...[
              Container(
                width: 28,
                height: 28,
                margin: const EdgeInsets.only(left: 16),
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
            ] else ...[
              const SizedBox(width: 16),
              GestureDetector(
                onTap: isLoading ? null : onStart,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: isLoading
                          ? [const Color(0xFFA35A33).withValues(alpha: 0.6), const Color(0xFF863C15).withValues(alpha: 0.6)]
                          : [const Color(0xFFA35A33), const Color(0xFF863C15)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isLoading)
                        const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.play_arrow,
                          color: Color(0xFFFFFFFF),
                          size: 22,
                        ),
                      const SizedBox(width: 12),
                      Text(
                        isLoading ? 'Загрузка…' : 'Начать',
                        style: const TextStyle(
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
          ],
        ),
      ),
    );
  }
}
