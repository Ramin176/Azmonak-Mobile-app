import 'package:hive/hive.dart';
import 'question.dart';

part 'attempt_details.g.dart';

@HiveType(typeId: 5) // یک ID جدید و منحصر به فرد
class AttemptDetails extends HiveObject {
  @HiveField(0)
  final String attemptId;

  @HiveField(1)
  final List<Question> questions;

  @HiveField(2)
  final Map<String, int> userAnswers;

  AttemptDetails({
    required this.attemptId,
    required this.questions,
    required this.userAnswers,
  });
}