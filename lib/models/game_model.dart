class GameModel {
  final String id;
  final String name;
  final List<RoundModel> rounds;
  final GameState state;
  final List<TeamModel> teams;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  GameModel({
    required this.id,
    required this.name,
    required this.rounds,
    this.state = GameState.notStarted,
    required this.teams,
    this.createdAt,
    this.updatedAt,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      name: json['name'] as String,
      rounds: (json['rounds'] as List<dynamic>)
          .map((r) => RoundModel.fromJson(r as Map<String, dynamic>))
          .toList(),
      state: GameState.values.firstWhere(
        (e) => e.toString() == 'GameState.${json['state']}',
        orElse: () => GameState.notStarted,
      ),
      teams: (json['teams'] as List<dynamic>)
          .map((t) => TeamModel.fromJson(t as Map<String, dynamic>))
          .toList(),
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : null,
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'rounds': rounds.map((r) => r.toJson()).toList(),
      'state': state.toString().split('.').last,
      'teams': teams.map((t) => t.toJson()).toList(),
      'created_at': createdAt?.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

enum GameState {
  notStarted,
  inProgress,
  paused,
  finished,
}

