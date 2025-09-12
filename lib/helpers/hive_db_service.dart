import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/course.dart';
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
  // --- عملیات خواندن داده‌های کاربر ---
  Future<List<Category>> getCategories(String userId) async {
    final box = await _openUserBox<Category>('categories', userId);
    return box.values.toList();
  }
  
  // Future<List<Course>> getCoursesByCategory(String categoryId, String userId) async {
  //   final box = await _openUserBox<Course>('courses', userId);
  //   return box.values.where((course) => course.categoryId == categoryId).toList();
  // }

  Future<List<Question>> getRandomQuestions(List<String> courseIds, int limit, String userId) async {
    final box = await _openUserBox<Question>('questions', userId);
    final filtered = box.values.where((q) => courseIds.contains(q.courseId)).toList();
    filtered.shuffle();
    return filtered.take(limit).toList();
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
      await Hive.deleteBoxFromDisk(_userBoxName('categories', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('courses', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('questions', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('quiz_attempts', userId));
      await Hive.deleteBoxFromDisk(_userBoxName('attempt_details', userId));
      print("All data boxes for user $userId have been cleared.");
  }
   Future<void> debugHive(String userId) async {
    print("\n--- HIVE DEBUGGER ---");
    
    final categoriesBox = await Hive.openBox<Category>(_userBoxName('categories', userId));
    print("Categories Box ('categories_$userId'): Contains ${categoriesBox.length} items.");
    if (categoriesBox.isNotEmpty) print("First Category: ${categoriesBox.values.first.name}");
    await categoriesBox.close();

    final coursesBox = await Hive.openBox<Course>(_userBoxName('courses', userId));
    print("Courses Box ('courses_$userId'): Contains ${coursesBox.length} items.");
    await coursesBox.close();

    final questionsBox = await Hive.openBox<Question>(_userBoxName('questions', userId));
    print("Questions Box ('questions_$userId'): Contains ${questionsBox.length} items.");
    await questionsBox.close();

    final attemptsBox = await Hive.openBox<QuizAttempt>(_userBoxName('quiz_attempts', userId));
    print("Attempts Box ('quiz_attempts_$userId'): Contains ${attemptsBox.length} items.");
    await attemptsBox.close();

    print("---------------------\n");
  }
  //  Future<List<Course>> getCoursesByCategory(String categoryId, String userId) async {
  // print("--- HIVE DEBUG: Fetching courses for category ID: $categoryId ---");
  
  // final box = await Hive.openBox<Course>(_userBoxName('courses', userId));
  
  // // لاگ برای دیدن تمام دوره‌های موجود در Box
  // print("Total courses in box: ${box.length}");
  // box.values.forEach((course) {
  //   print(" -> Course: ${course.name}, CategoryID: ${course.categoryId}");
  // });

  // // فیلتر کردن
  // final courses = box.values.where((course) => course.categoryId == categoryId).toList();
  
  // print("Found ${courses.length} courses matching the category ID.");
  // print("---------------------------------------------------------");
  // await box.close();
  // return courses;
  // }
 Future<List<Course>> getCoursesByCategory(String categoryId, String userId) async {
  try {
    final boxName = _userBoxName('courses', userId);

    // اگر باز نبود، بازش کن
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<Course>(boxName)
        : await Hive.openBox<Course>(boxName);

    // فیلتر کردن دوره‌های این دسته
    final courses = box.values.where((course) {
      return course.categoryId.toString() == categoryId.toString();
    }).toList();

    print("📦 خواندن ${courses.length} دوره از Hive برای categoryId=$categoryId (userId=$userId)");

    return courses;
  } catch (e) {
    print("❌ خطا در getCoursesByCategory: $e");
    return [];
  }
}

Future<void> saveCoursesByCategory(
  String categoryId,
  String userId,
  List<Course> courses,
) async {
  try {
    final boxName = _userBoxName('courses', userId);

    // اگر باز نبود، بازش کن
    final box = Hive.isBoxOpen(boxName)
        ? Hive.box<Course>(boxName)
        : await Hive.openBox<Course>(boxName);

    // 🧹 پاک کردن دوره‌های قبلی این دسته
    final keysToDelete = box.keys.where((key) {
      final course = box.get(key);
      return course != null && course.categoryId.toString() == categoryId.toString();
    }).toList();

    if (keysToDelete.isNotEmpty) {
      await box.deleteAll(keysToDelete);
    }

    // 📌 ذخیره دوره‌های جدید
    final Map<dynamic, Course> dataMap = {
      for (var item in courses) (item as dynamic).id: item
    };

    await box.putAll(dataMap);

    print("✅ ذخیره ${courses.length} دوره برای categoryId=$categoryId در userId=$userId");
  } catch (e) {
    print("❌ خطا در saveCoursesByCategory: $e");
  }
}

}