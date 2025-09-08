import 'package:hive/hive.dart';

part 'attempt_question.g.dart';

@HiveType(typeId: 6)
class AttemptQuestion {
  @HiveField(0)
  String id;
  @HiveField(1)
  String text;
  @HiveField(2)
  List<String> options;
  @HiveField(3)
  int correctAnswerIndex;

  AttemptQuestion({
    required this.id,
    required this.text,
    required this.options,
    required this.correctAnswerIndex,
  });
}