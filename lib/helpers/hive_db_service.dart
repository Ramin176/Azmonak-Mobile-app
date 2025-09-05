import 'package:hive_flutter/hive_flutter.dart';
import '../models/category.dart';
import '../models/course.dart';
import '../models/question.dart';
import '../models/quiz_attempt.dart';
import '../models/attempt_details.dart'; 
class HiveService {
  // --- نام Box ها (معادل جداول) ---
  static const String categoriesBoxName = 'categories';
  static const String coursesBoxName = 'courses';
  static const String questionsBoxName = 'questions';
  static const String quizAttemptsBoxName = 'quiz_attempts';

 static const String attemptDetailsBoxName = 'attempt_details'; 
 static const String trialQuestionsBoxName = 'trial_questions';


  // --- عملیات همگام‌سازی (Sync) ---
  Future<void> syncData<T>(String boxName, List<T> data) async {
    final box = await Hive.openBox<T>(boxName);
    await box.clear();
    // برای استفاده از addAll، داده‌ها باید List<T> باشند
    await box.addAll(data);
    await box.close();
  }
 Future<List<QuizAttempt>> getUnsyncedAttempts() async {
    final box = await Hive.openBox<QuizAttempt>(quizAttemptsBoxName);
    final unsynced = box.values.where((attempt) => !attempt.isSynced).toList();
    // await box.close(); // بهتر است box باز بماند تا برای آپدیت آماده باشد
    return unsynced;
  }
   Future<void> markAttemptAsSynced(QuizAttempt attempt) async {
    attempt.isSynced = true;
    await attempt.save(); // <-- استفاده از متد save() که از HiveObject می‌آید
  }
  // --- عملیات خواندن داده‌ها از دیتابیس محلی ---
  Future<List<Category>> getCategories() async {
    final box = await Hive.openBox<Category>(categoriesBoxName);
    final categories = box.values.toList();
    await box.close();
    return categories;
  }

  Future<List<Course>> getCoursesByCategory(String categoryId) async {
    final box = await Hive.openBox<Course>(coursesBoxName);
    final courses = box.values.where((course) => course.categoryId == categoryId).toList();
    await box.close();
    return courses;
  }

  Future<List<Question>> getRandomQuestions(List<String> courseIds, int limit) async {
    final box = await Hive.openBox<Question>(questionsBoxName);
    final filteredQuestions = box.values.where((q) => courseIds.contains(q.courseId)).toList();
    filteredQuestions.shuffle();
    final questions = filteredQuestions.take(limit).toList();
    await box.close();
    return questions;
  }
  
  // --- عملیات مربوط به نتایج آزمون ---
  Future<void> saveQuizAttempt(QuizAttempt attempt) async {
      final box = await Hive.openBox<QuizAttempt>(quizAttemptsBoxName);
      await box.add(attempt);
      await box.close();
  }

  Future<List<QuizAttempt>> getQuizHistory() async {
      final box = await Hive.openBox<QuizAttempt>(quizAttemptsBoxName);
      final history = box.values.toList();
      await box.close();
      history.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return history;
  }
    Future<void> saveAttemptDetails(AttemptDetails details) async {
    final box = await Hive.openBox<AttemptDetails>(attemptDetailsBoxName); // <-- استفاده از نام صحیح
    await box.put(details.attemptId, details);
    await box.close();
  }

  Future<AttemptDetails?> getAttemptDetails(String attemptId) async {
    final box = await Hive.openBox<AttemptDetails>(attemptDetailsBoxName); // <-- استفاده از نام صحیح
    final details = box.get(attemptId);
    await box.close();
    return details;
  }
   Future<List<Question>> getTrialQuestions() async {
    final box = await Hive.openBox<Question>(trialQuestionsBoxName);
    final questions = box.values.toList();
    await box.close();
    questions.shuffle(); // هر بار ترتیب متفاوتی داشته باشد
    return questions.take(10).toList();
  }

}