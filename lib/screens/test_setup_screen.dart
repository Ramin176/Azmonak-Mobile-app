import 'package:azmoonak_app/helpers/adaptive_text_size.dart'; // Import the new helper
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../models/course.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import 'home_screen.dart'; // Ensure HomeScreen import is correct for picker
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

  // --- پالت رنگی جدید (Teal) - همانند HomeScreen ---
  static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  static const Color lightTeal = Color(0xFF4DB6AC); // Teal روشن‌تر
  static const Color darkTeal = Color(0xFF004D40); // Teal تیره‌تر
  static const Color accentYellow = Color(0xFFFFD700); // زرد تاکید (برای ستاره)
  static const Color textDark = Color(0xFF212121); // متن تیره
  static const Color textMedium = Color(0xFF607D8B); // متن متوسط
  static const Color backgroundLight = Color(0xFFF8F9FA); // پس‌زمینه روشن

  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }

  void _showCoursePicker() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(_getResponsiveSize(context, 20)))),
      builder: (_) => SizedBox(
          height: MediaQuery.of(context).size.height * 0.85, child: const HomeScreen(isPickerMode: true)),
    ).then((selectedCoursesFromPicker) {
      if (selectedCoursesFromPicker != null && selectedCoursesFromPicker is List<Course>) {
        setState(() {
          for (var course in selectedCoursesFromPicker) {
            if (!_selectedCourses.any((c) => c.id == course.id)) {
              _selectedCourses.add(course);
            }
          }
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        title: AdaptiveTextSize(
          text: 'ساخت آزمون سفارشی',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontFamily: 'Vazirmatn',
            fontSize: _getResponsiveSize(context, 20),
          ),
        ),
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white), // Color of the back button
      ),
      body: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
                      child: Padding(
                        padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdaptiveTextSize(
                              text: '۱. دوره‌های مورد نظر را انتخاب کنید',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            OutlinedButton.icon(
                              icon: Icon(Icons.add_circle_outline, color: primaryTeal, size: _getResponsiveSize(context, 24)),
                              label: AdaptiveTextSize(
                                text: 'افزودن / ویرایش دوره‌ها',
                                style: TextStyle(color: primaryTeal, fontFamily: 'Vazirmatn', fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTeal,
                                side: BorderSide(color: primaryTeal, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12))),
                                padding: EdgeInsets.symmetric(
                                  vertical: _getResponsiveSize(context, 12),
                                  horizontal: _getResponsiveSize(context, 16),
                                ),
                              ),
                              onPressed: _showCoursePicker,
                            ),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            AdaptiveTextSize(
                              text: 'دوره‌های انتخاب شده:',
                              style: TextStyle(fontSize: 16, color: textDark, fontFamily: 'Vazirmatn'),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 8)),
                            _selectedCourses.isEmpty
                                ? AdaptiveTextSize(
                                    text: 'هنوز دوره‌ای انتخاب نشده است.',
                                    style: TextStyle(fontStyle: FontStyle.italic, color: textMedium, fontSize: 14, fontFamily: 'Vazirmatn'),
                                  )
                                : Wrap(
                                    spacing: _getResponsiveSize(context, 8.0),
                                    runSpacing: _getResponsiveSize(context, 4.0),
                                    children: _selectedCourses.map((course) => Chip(
                                          label: AdaptiveTextSize(
                                            text: course.name,
                                            style: TextStyle(color: darkTeal, fontFamily: 'Vazirmatn', fontSize: 14),
                                          ),
                                          backgroundColor: lightTeal.withOpacity(0.2),
                                          deleteIcon: Icon(Icons.cancel, size: _getResponsiveSize(context, 20), color: darkTeal.withOpacity(0.7)),
                                          onDeleted: () => setState(() => _selectedCourses.removeWhere((c) => c.id == course.id)),
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 8)),
                                            side: BorderSide(color: lightTeal.withOpacity(0.4)),
                                          ),
                                        )).toList(),
                                  ),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: _getResponsiveSize(context, 24)),
                    Card(
                      elevation: 4,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
                      child: Padding(
                        padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            AdaptiveTextSize(
                              text: '۲. تعداد سوالات: ${_numberOfQuestions.toInt()}',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                            ),
                            Slider(
                              value: _numberOfQuestions,
                              min: 5,
                              max: 100,
                              divisions: 19,
                              label: _numberOfQuestions.toInt().toString(),
                              onChanged: (value) => setState(() => _numberOfQuestions = value),
                              activeColor: primaryTeal,
                              inactiveColor: lightTeal.withOpacity(0.3),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 16)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 16)),
                backgroundColor: primaryTeal,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15))),
                elevation: 5,
              ),
              onPressed: _selectedCourses.isEmpty || _isLoading
                  ? null
                  : () async {
                      setState(() {
                        _isLoading = true;
                      });
                      try {
                        final authProvider = Provider.of<AuthProvider>(context, listen: false);
                        final user = authProvider.user;
                        final limit = _numberOfQuestions.toInt();

                        if (user == null) throw Exception('اطلاعات کاربری یافت نشد.');

                        if (!user.isPremium && limit > 10) {
                          if (mounted) {
                            Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen()));
                          }
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
                          final token = authProvider.token!;
                          questions = await _apiService.fetchRandomQuestions(courseIds, limit, token);
                        }

                        if (questions.isEmpty) throw Exception('هیچ سوالی برای دوره‌های انتخاب شده یافت نشد.');

                        if (mounted) {
                          Navigator.of(context).push(MaterialPageRoute(
                              builder: (ctx) => QuizScreen(questions: questions, courseIds: courseIds)));
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: AdaptiveTextSize(text: 'خطا: ${e.toString().replaceAll("Exception: ", "")}', style: TextStyle(color: Colors.white, fontFamily: 'Vazirmatn', fontSize: 14))));
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: _getResponsiveSize(context, 3))
                  : AdaptiveTextSize(
                      text: 'شروع آزمون',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}