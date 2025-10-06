import 'package:hive/hive.dart';
part 'quiz_attempt.g.dart';

@HiveType(typeId: 3)
class QuizAttempt extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final double percentage;
  @HiveField(2)
  final DateTime createdAt;
  @HiveField(3)
  final String? subjectName;
  @HiveField(4)
  final int? totalQuestions;
  @HiveField(5)
  final int? correctAnswers;
  @HiveField(6)
  final int? wrongAnswers;
  @HiveField(7)
  final int? totalScore;
  @HiveField(8)
  final int? achievedScore;
  @HiveField(9)
  bool isSynced;

  QuizAttempt({
    required this.id,
    required this.percentage,
    required this.createdAt,
    this.subjectName,
    this.totalQuestions,
    this.correctAnswers,
    this.wrongAnswers,
    this.totalScore,
    this.achievedScore,
    this.isSynced = true, // مقدار پیش‌فرض
  });

  factory QuizAttempt.fromJson(Map<String, dynamic> json) {
    return QuizAttempt(
      id: json['_id'] as String? ?? 'error_id_${DateTime.now().millisecondsSinceEpoch}',
      percentage: (json['percentage'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
      subjectName: json['subjectName'] as String? ?? 'آزمون عمومی',
      totalQuestions: json['totalQuestions'] as int?,
      correctAnswers: json['correctAnswers'] as int?,
      wrongAnswers: json['wrongAnswers'] as int?,
      totalScore: json['totalScore'] as int?,
      achievedScore: json['achievedScore'] as int?,
      isSynced: json['isSynced'] as bool? ?? true, // <-- اصلاح اصلی: مقدار پیش‌فرض true
    );
  }

  Map<String, dynamic> toDbMap() {
    return {
      'id': id,
      'percentage': percentage,
      'createdAt': createdAt.toIso8601String(),
      'subjectName': subjectName,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'totalScore': totalScore,
      'achievedScore': achievedScore,
      'isSynced': isSynced,
    };
  }
}