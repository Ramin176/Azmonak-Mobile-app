import 'package:azmoonak_app/models/subject.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/question.dart';
import '../models/quiz_attempt.dart';
import '../models/attempt_details.dart';
import '../models/settings.dart';

class HiveService {
  // --- دسترسی مستقیم به Box های عمومی که در main.dart باز شده‌اند ---
  Box<AppSettings> get settingsBox => Hive.box<AppSettings>('settings');
  Box<Question> get trialQuestionsBox => Hive.box<Question>('trial_questions');
  static const String trialQuestionsBoxName = 'trial_questions';
  // --- تابع اصلی برای ساختن نام Box منحصر به فرد برای هر کاربر ---
  String _userBoxName(String baseName, String userId) => '${baseName}_$userId';
  
  // --- تابع برای باز کردن امن Box کاربر ---
  Future<Box<T>> _openUserBox<T>(String baseName, String userId) async {
    final boxName = _userBoxName(baseName, userId);
    if (Hive.isBoxOpen(boxName)) {
      return Hive.box<T>(boxName);
    }
    return await Hive.openBox<T>(boxName);
  }

  // --- عملیات همگام‌سازی ---
  // Future<void> syncData<T extends HiveObject>(String baseBoxName, List<T> data, String userId) async {
  //   final box = await _openUserBox<T>(baseBoxName, userId);
  //   await box.clear();
  //   await box.addAll(data);
  // }
Future<void> syncData<T extends HiveObject>(String baseBoxName, List<T> data, String userId) async {
  final box = await _openUserBox<T>(baseBoxName, userId);
  await box.clear();
  // به جای addAll، از putAll با یک Map استفاده می‌کنیم تا از ID به عنوان کلید استفاده شود
  final Map<dynamic, T> dataMap = { for (var item in data) (item as dynamic).id : item };
  await box.putAll(dataMap);
}

Future<List<Subject>> getSubjects(String userId) async {
    final box = await _openUserBox<Subject>('subjects', userId);
    return box.values.toList();
  }
  


   Future<List<Question>> getRandomQuestions(List<String> subjectIds, int limit, String userId) async {
    final box = await _openUserBox<Question>('questions', userId);
    final filtered = box.values.where((q) => subjectIds.contains(q.subjectId)).toList();
    filtered.shuffle();
    return filtered.take(limit).toList();
  }
  Future<List<Question>> getAllQuestions(String userId) async {
  try {
    final box = await _openUserBox<Question>('questions', userId);
    return box.values.toList();
  } catch (e) {
    print("Error getting all local questions: $e");
    return [];
  }
}
  // --- عملیات مربوط به نتایج آزمون کاربر ---
  Future<void> saveQuizAttempt(QuizAttempt attempt, String userId) async {
      final box = await _openUserBox<QuizAttempt>('quiz_attempts', userId);
      await box.add(attempt);
  }

  Future<List<QuizAttempt>> getQuizHistory(String userId) async {
      final box = await _openUserBox<QuizAttempt>('quiz_attempts', userId);
      final history = box.values.toList();
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return history;
  }

  Future<void> saveAttemptDetails(AttemptDetails details, String userId) async {
    final box = await _openUserBox<AttemptDetails>('attempt_details', userId);
    await box.put(details.attemptId, details);
  }

  Future<AttemptDetails?> getAttemptDetails(String attemptId, String userId) async {
    final box = await _openUserBox<AttemptDetails>('attempt_details', userId);
    return box.get(attemptId);
  }

  // --- توابع مربوط به آزمون آزمایشی (عمومی) ---
  Future<List<Question>> getTrialQuestions() async {
    final questions = trialQuestionsBox.values.toList();
    questions.shuffle();
    return questions.take(10).toList();
  }

  Future<void> syncTrialQuestions(List<Question> questions) async {
    await trialQuestionsBox.clear();
    await trialQuestionsBox.addAll(questions);
  }

  // --- توابع مربوط به تنظیمات (عمومی) ---
  Future<void> saveSettings(AppSettings settings) async {
    await settingsBox.put(0, settings);
  }

  Future<AppSettings?> getSettings() async {
    return settingsBox.get(0);
  }

  // --- تابع برای پاک کردن داده‌های کاربر هنگام خروج ---
   Future<void> clearUserBoxes(String userId) async {
      // حذف Box های قدیمی
      await Hive.deleteBoxFromDisk(_userBoxName('categories', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('courses', userId));
      
      // حذف Box های جدید
      await Hive.deleteBoxFromDisk(_userBoxName('subjects', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('questions', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('quiz_attempts', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('attempt_details', userId));
      print("All data boxes for user $userId have been cleared.");
  }
  
Future<void> debugUserBoxes(String userId) async {
  print("\n\n=============== HIVE DEBUGGER ================");
  print("--- Checking boxes for User ID: $userId ---");

  try {
    // بررسی Box مربوط به Subjects
    final subjectBoxName = _userBoxName('subjects', userId);
    if (await Hive.boxExists(subjectBoxName)) {
      final box = await Hive.openBox<Subject>(subjectBoxName);
      print("✅ Box 'subjects' EXISTS. Contains ${box.length} items.");
      if (box.isNotEmpty) {
        // چاپ کردن ۵ آیتم اول برای نمونه
        box.values.take(5).forEach((subject) {
          print("  -> Subject: id=${subject.id}, name=${subject.name}, parent=${subject.parent}");
        });
      }
      await box.close();
    } else {
      print("❌ Box 'subjects' DOES NOT EXIST.");
    }

    // شما می‌توانید Box های دیگر را هم به همین شکل برای تست اضافه کنید
    // final questionBoxName = _userBoxName('questions', userId);
    // ...

  } catch (e) {
    print("!!! ERROR during Hive debug: $e");
  }

  print("==========================================\n\n");
}
}



