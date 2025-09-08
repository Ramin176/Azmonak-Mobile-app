
import 'package:hive_flutter/hive_flutter.dart';

import 'attempt_question.dart';

part 'attempt_details.g.dart';

@HiveType(typeId: 5)
class AttemptDetails extends HiveObject {
  @HiveField(0)
  String attemptId;
  @HiveField(1)
  List<AttemptQuestion> questions;
  @HiveField(2)
  Map<String, int> userAnswers; // <-- ما Map را برمی‌گردانیم. Hive از Map های ساده پشتیبانی می‌کند.

  AttemptDetails({
    required this.attemptId,
    required this.questions,
    required this.userAnswers,
  });
}