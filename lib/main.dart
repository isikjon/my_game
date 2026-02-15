import 'package:flutter/material.dart';
import 'styles/app_theme.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/mode_selection/mode_selection_screen.dart';
import 'screens/admin/admin_home_screen.dart';
import 'screens/admin/team_selection_screen.dart';
import 'screens/game/host_game_screen.dart';
import 'screens/game/display_game_screen.dart';
import 'screens/game/scoreboard_screen.dart';
import 'models/game_model.dart';
import 'config/app_mode.dart';

void main() {
  runApp(const QuizGameApp());
}

class QuizGameApp extends StatelessWidget {
  const QuizGameApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Своя Игра',
      theme: AppTheme.lightTheme,
      debugShowCheckedModeBanner: false,
      initialRoute: '/',
      routes: {
        '/': (context) => const SplashScreen(),
        '/mode-selection': (context) => const ModeSelectionScreen(),
        '/admin': (context) {
          AppModeConfig.setMode(AppMode.admin);
          return const AdminHomeScreen();
        },
        '/host': (context) {
          AppModeConfig.setMode(AppMode.host);
          final game = ModalRoute.of(context)!.settings.arguments as GameModel?;
          return HostGameScreen(game: game);
        },
        '/display': (context) {
          AppModeConfig.setMode(AppMode.display);
          return const DisplayGameScreen();
        },
        '/scoreboard': (context) {
          final teams = ModalRoute.of(context)!.settings.arguments as List?;
          return ScoreboardScreen(
            teams: teams ?? [],
          );
        },
        '/admin/team-selection': (context) {
          final args = ModalRoute.of(context)!.settings.arguments as Map<String, dynamic>?;
          return TeamSelectionScreen(
            availableTeams: args?['teams'] ?? [],
            selectedTeams: args?['selectedTeams'],
            onTeamsSelected: args?['onTeamsSelected'],
          );
        },
      },
    );
  }
}

