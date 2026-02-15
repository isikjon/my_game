class TeamModel {
  final String id;
  final String name;
  final int score;
  final String? color;

  TeamModel({
    required this.id,
    required this.name,
    this.score = 0,
    this.color,
  });

  factory TeamModel.fromJson(Map<String, dynamic> json) {
    return TeamModel(
      id: json['id'] as String,
      name: json['name'] as String,
      score: json['score'] as int? ?? 0,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'score': score,
      'color': color,
    };
  }

  TeamModel copyWith({
    String? id,
    String? name,
    int? score,
    String? color,
  }) {
    return TeamModel(
      id: id ?? this.id,
      name: name ?? this.name,
      score: score ?? this.score,
      color: color ?? this.color,
    );
  }
}

