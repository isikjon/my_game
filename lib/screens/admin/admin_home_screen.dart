import 'package:flutter/material.dart';
import '../../styles/app_colors.dart';
import '../../styles/app_text_styles.dart';
import '../../styles/app_spacing.dart';
import '../../models/team_model.dart';
import '../../models/game_model.dart';
import '../../widgets/add_team_dialog.dart';

class AdminHomeScreen extends StatefulWidget {
  const AdminHomeScreen({super.key});

  @override
  State<AdminHomeScreen> createState() => _AdminHomeScreenState();
}

class _AdminHomeScreenState extends State<AdminHomeScreen> {
  List<TeamModel> _teams = [
    TeamModel(id: '1', name: 'Команда Nº123456', score: 10567),
    TeamModel(id: '2', name: 'Команда №2', score: 107),
    TeamModel(id: '3', name: 'Команда №3', score: 107),
  ];

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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Администрирование'),
        backgroundColor: AppColors.questionScreenCard,
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
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    _showAddTeamDialog(context);
                  },
                  icon: const Icon(
                    Icons.add,
                    color: AppColors.surface,
                    size: 20,
                  ),
                  label: Text(
                    'Добавить команду',
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
                  _showDeleteTeamsDialog(context);
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
            child: _teams.isEmpty
                ? _buildEmptyTeamsState(context)
                : ListView.builder(
                    itemCount: _teams.length,
                    itemBuilder: (context, index) {
                      return _buildTeamItem(_teams[index]);
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
                ? _buildEmptyGamesState(context)
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

  Widget _buildEmptyTeamsState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Здесь еще нет команд, но',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.questionTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'уже можно создать',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.questionTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyGamesState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            'Здесь еще нет игр, но уже',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.questionTextColor,
            ),
            textAlign: TextAlign.center,
          ),
          Text(
            'можно создать',
            style: AppTextStyles.bodyLarge.copyWith(
              color: AppColors.questionTextColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTeamItem(TeamModel team) {
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
          Container(
            width: 16,
            height: 16,
            decoration: BoxDecoration(
              color: AppColors.timerBackground,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: AppColors.questionTextColor,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            '${team.score}',
            style: AppTextStyles.bodyMedium.copyWith(
              color: AppColors.questionTextColor,
            ),
          ),
        ],
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

  void _showAddTeamDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AddTeamDialog(
        onSave: (name) {
          setState(() {
            _teams.add(TeamModel(
              id: DateTime.now().millisecondsSinceEpoch.toString(),
              name: name,
              score: 0,
            ));
          });
        },
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
                    teams: _teams,
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

  void _showDeleteTeamsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Удалить все команды?'),
        content: const Text('Это действие нельзя отменить.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Отмена'),
          ),
          TextButton(
            onPressed: () {
              setState(() {
                _teams.clear();
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
