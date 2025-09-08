import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/course.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import 'home_screen.dart';
import 'quiz_screen.dart';
import 'premium_screen.dart';

class TestSetupScreen extends StatefulWidget {
  const TestSetupScreen({super.key});
  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
  final List<Course> _selectedCourses = [];
  double _numberOfQuestions = 10.0;
  bool _isLoading = false;
  final ApiService _apiService = ApiService();
  final HiveService _hiveService = HiveService();

  void _showCoursePicker() {
    showModalBottomSheet(
      context: context, isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => SizedBox(height: MediaQuery.of(context).size.height * 0.85, child: HomeScreen(isPickerMode: true)),
    ).then((selectedCoursesFromPicker) {
      if (selectedCoursesFromPicker != null && selectedCoursesFromPicker is List<Course>) {
        setState(() {
          for (var course in selectedCoursesFromPicker) {
            if (!_selectedCourses.any((c) => c.id == course.id)) _selectedCourses.add(course);
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF008080);
    return Scaffold(
      appBar: AppBar(title: const Text('ساخت آزمون سفارشی')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column( // Column اصلی
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // --- بخش بالایی که می‌تواند اسکرول بخورد ---
            Expanded( // <-- از Expanded برای گرفتن فضای باقی‌مانده استفاده می‌کنیم
              child: SingleChildScrollView( // <-- برای جلوگیری از Overflow در صفحه‌های کوچک
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('۱. دوره‌های مورد نظر را انتخاب کنید', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            const SizedBox(height: 16),
                            OutlinedButton.icon(
                              icon: const Icon(Icons.add),
                              label: const Text('افزودن / ویرایش دوره‌ها'),
                              onPressed: _showCoursePicker,
                            ),
                            const SizedBox(height: 16),
                            const Text('دوره‌های انتخاب شده:'),
                            const SizedBox(height: 8),
                            _selectedCourses.isEmpty
                              ? const Text('هنوز دوره‌ای انتخاب نشده است.', style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey))
                              : Wrap(
                                  spacing: 8.0,
                                  runSpacing: 4.0,
                                  children: _selectedCourses.map((course) => Chip(
                                    label: Text(course.name),
                                    onDeleted: () => setState(() => _selectedCourses.removeWhere((c) => c.id == course.id)),
                                  )).toList(),
                                ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('۲. تعداد سوالات: ${_numberOfQuestions.toInt()}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                            Slider(
                              value: _numberOfQuestions, min: 5, max: 100, divisions: 19,
                              label: _numberOfQuestions.toInt().toString(),
                              onChanged: (value) => setState(() => _numberOfQuestions = value),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            // --- دکمه پایینی که همیشه ثابت است ---
            const SizedBox(height: 16), // فاصله بین محتوا و دکمه
            ElevatedButton(
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 16), backgroundColor: tealColor),
              onPressed: _selectedCourses.isEmpty || _isLoading ? null : () async {
                setState(() { _isLoading = true; });
                try {
                  final user = Provider.of<AuthProvider>(context, listen: false).user;
                  final limit = _numberOfQuestions.toInt();
                  if (user == null) throw Exception('اطلاعات کاربری یافت نشد.');
                  
                  if (!user.isPremium && limit > 10) {
                    Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen()));
                    return;
                  }

                  final courseIds = _selectedCourses.map((c) => c.id).toList();
                  List<Question> questions;

                  if (user.isPremium) {
                    // کاربر ویژه: فقط از دیتابیس محلی بخوان
                     questions = await _hiveService.getRandomQuestions(courseIds, limit, user.id);
                    if (questions.isEmpty) {
                      throw Exception('هیچ سوالی در حافظه آفلاین یافت نشد. لطفا از صفحه اصلی همگام‌سازی کنید.');
                    }
                  } else {
                    // کاربر رایگان: همیشه از سرور آنلاین بخوان
                    final token = Provider.of<AuthProvider>(context, listen: false).token!;
                    questions = await _apiService.fetchRandomQuestions(courseIds, limit, token);
                  }
                  
                  if (questions.isEmpty) throw Exception('هیچ سوالی برای دوره‌های انتخاب شده یافت نشد.');
                  
                  if (mounted) {
                     Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => QuizScreen(questions: questions, courseIds: courseIds)));
                  }
                } catch (e) {
                  if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا: ${e.toString().replaceAll("Exception: ", "")}')));
                  }
                } finally {
                  if (mounted) { setState(() { _isLoading = false; }); }
                }
              },
              child: _isLoading 
                  ? const CircularProgressIndicator(color: Colors.white) 
                  : const Text('شروع آزمون', style: TextStyle(fontSize: 18)),
            ),
          ],
        ),
      ),
    );
  }
}