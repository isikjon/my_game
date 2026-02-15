class QuestionModel {
  final String id;
  final String text;
  final String answer;
  final int points;
  bool isAnswered;
  String? answeredByTeamId;

  QuestionModel({
    required this.id,
    required this.text,
    required this.answer,
    required this.points,
    this.isAnswered = false,
    this.answeredByTeamId,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    return QuestionModel(
      id: json['id'] as String,
      text: json['text'] as String,
      answer: json['answer'] as String,
      points: json['points'] as int,
      isAnswered: json['is_answered'] as bool? ?? false,
      answeredByTeamId: json['answered_by_team_id'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'text': text,
      'answer': answer,
      'points': points,
      'is_answered': isAnswered,
      'answered_by_team_id': answeredByTeamId,
    };
  }
}

