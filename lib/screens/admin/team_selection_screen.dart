import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../models/team_model.dart';
import '../../models/game_model.dart';

class TeamSelectionScreen extends StatefulWidget {
  final List<TeamModel> availableTeams;
  final List<TeamModel>? selectedTeams;
  final Function(List<TeamModel>)? onTeamsSelected;

  const TeamSelectionScreen({
    super.key,
    required this.availableTeams,
    this.selectedTeams,
    this.onTeamsSelected,
  });

  @override
  State<TeamSelectionScreen> createState() => _TeamSelectionScreenState();
}

class _TeamSelectionScreenState extends State<TeamSelectionScreen> {
  late List<TeamModel> _selectedTeams;
  List<GameModel> _games = [
    GameModel(
      id: '1',
      name: 'Игра №1',
      rounds: [],
      teams: [],
    ),
    GameModel(
      id: '2',
      name: 'Игра №2',
      rounds: [],
      teams: [],
    ),
    GameModel(
      id: '3',
      name: 'Игра №3',
      rounds: [],
      teams: [],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _selectedTeams = List<TeamModel>.from(widget.selectedTeams ?? []);
  }

  void _toggleTeamSelection(TeamModel team) {
    setState(() {
      if (_selectedTeams.any((t) => t.id == team.id)) {
        _selectedTeams.removeWhere((t) => t.id == team.id);
      } else {
        _selectedTeams.add(team);
      }
    });
  }

  void _deleteSelectedTeams() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить выбранные команды?'),
        content: Text('Будет удалено команд: ${_selectedTeams.length}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _selectedTeams.clear();
              });
              Navigator.pop(context);
            },
            child: Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Выбор команд'),
        backgroundColor: AppColors.questionScreenCard,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            if (widget.onTeamsSelected != null) {
              widget.onTeamsSelected!(_selectedTeams);
            }
            Navigator.pop(context);
          },
        ),
      ),
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
          child: Row(
            children: [
              Expanded(
                child: _buildTeamsSection(context),
              ),
              Container(
                width: 1,
                color: AppColors.divider,
              ),
              Expanded(
                child: _buildGamesSection(context),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTeamsSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SizedBox(width: 48),
              ElevatedButton(
                onPressed: _selectedTeams.isNotEmpty
                    ? _deleteSelectedTeams
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.questionTextColor,
                  foregroundColor: AppColors.surface,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.md,
                    vertical: AppSpacing.sm,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Удалить',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.surface,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: widget.availableTeams.isEmpty
                ? _buildEmptyTeamsState()
                : ListView.builder(
                    itemCount: widget.availableTeams.length,
                    itemBuilder: (context, index) {
                      final team = widget.availableTeams[index];
                      final isSelected = _selectedTeams.any((t) => t.id == team.id);
                      return _buildTeamItem(team, isSelected);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildGamesSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showCreateGameDialog(context);
                  },
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.surface,
                    size: 20,
                  ),
                  label: Text(
                    'Создать новую игру',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.surface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.questionTextColor,
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              IconButton(
                onPressed: () {
                  _showDeleteGamesDialog(context);
                },
                icon: const Icon(
                  Icons.delete_outline,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Expanded(
            child: _games.isEmpty
                ? _buildEmptyGamesState()
                : ListView.builder(
                    itemCount: _games.length,
                    itemBuilder: (context, index) {
                      return _buildGameItem(_games[index]);
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyTeamsState() {
    return Center(
      child: Text(
        'Нет доступных команд',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.questionTextColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildEmptyGamesState() {
    return Center(
      child: Text(
        'Нет доступных игр',
        style: AppTextStyles.bodyLarge.copyWith(
          color: AppColors.questionTextColor,
        ),
        textAlign: TextAlign.center,
      ),
    );
  }

  Widget _buildTeamItem(TeamModel team, bool isSelected) {
    return GestureDetector(
      onTap: () => _toggleTeamSelection(team),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.sm),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.categoryCard,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Expanded(
              child: Text(
                team.name,
                style: AppTextStyles.bodyLarge.copyWith(
                  color: AppColors.questionTextColor,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.play_arrow,
              color: AppColors.timerBackground,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '25',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.questionTextColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Icon(
              Icons.star_outline,
              color: AppColors.timerBackground,
              size: 20,
            ),
            const SizedBox(width: 4),
            Text(
              '${team.score}',
              style: AppTextStyles.bodyMedium.copyWith(
                color: AppColors.questionTextColor,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            GestureDetector(
              onTap: () => _toggleTeamSelection(team),
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.questionTextColor
                      : AppColors.surface,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: AppColors.questionTextColor,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(
                        Icons.check,
                        color: AppColors.surface,
                        size: 20,
                      )
                    : null,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGameItem(GameModel game) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.categoryCard,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              game.name,
              style: AppTextStyles.bodyLarge.copyWith(
                color: AppColors.questionTextColor,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pushReplacementNamed(
                context,
                '/host',
                arguments: game,
              );
            },
            icon: const Icon(
              Icons.play_arrow,
              color: AppColors.surface,
              size: 16,
            ),
            label: Text(
              'Начать',
              style: AppTextStyles.bodySmall.copyWith(
                color: AppColors.surface,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.questionTextColor,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSpacing.md,
                vertical: AppSpacing.sm,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showCreateGameDialog(BuildContext context) {
    final nameController = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Создать игру'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: 'Название игры',
            hintText: 'Введите название',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              if (nameController.text.isNotEmpty) {
                setState(() {
                  _games.add(GameModel(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    name: nameController.text,
                    rounds: [],
                    teams: _selectedTeams,
                  ));
                });
                Navigator.pop(context);
              }
            },
            child: const Text('Создать'),
          ),
        ],
      ),
    );
  }

  void _showDeleteGamesDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все игры?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _games.clear();
              });
              Navigator.pop(context);
            },
            child: Text(
              'Удалить',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }
}

