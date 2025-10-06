import 'package:azmoonak_app/helpers/adaptive_text_size.dart'; 
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../models/question.dart';
import 'home_screen.dart'; 
import 'package:connectivity_plus/connectivity_plus.dart';
import 'quiz_screen.dart';
import 'premium_screen.dart';
import '../models/subject.dart'; 
class TestSetupScreen extends StatefulWidget {

    final Subject? preselectedSubject;
      const TestSetupScreen({super.key, this.preselectedSubject});
  @override
  State<TestSetupScreen> createState() => _TestSetupScreenState();
}

class _TestSetupScreenState extends State<TestSetupScreen> {
 final List<Subject> _selectedSubjects = [];
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
 @override
  void initState() {
    super.initState();
    // اگر موضوعی از صفحه قبل ارسال شده بود، آن را به لیست اضافه کن
    if (widget.preselectedSubject != null) {
      _selectedSubjects.add(widget.preselectedSubject!);
    }
  }
  // Helper to get responsive sizes based on screen width
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }
  // برای اصلاح بگذاری امتحان
  // void _showSubjectPicker() {
  //   showModalBottomSheet(
  //     context: context,
  //     isScrollControlled: true,
  //     shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(_getResponsiveSize(context, 20)))),
  //     builder: (_) => SizedBox(height: MediaQuery.of(context).size.height * 0.85, child: const HomeScreen(isPickerMode: true)),
  //   ).then((selectedSubjectsFromPicker) {
  //     if (selectedSubjectsFromPicker != null && selectedSubjectsFromPicker is List<Subject>) {
  //       setState(() {
  //         for (var subject in selectedSubjectsFromPicker) {
  //           if (!_selectedSubjects.any((s) => s.id == subject.id)) {
  //             _selectedSubjects.add(subject);
  //           }
  //         }
  //       });
  //     }
  //   });
  // }
  //   void _pickSubject() async {
  //   // HomeScreen را به عنوان یک صفحه جدید باز می‌کنیم و منتظر نتیجه می‌مانیم
  //   // علامت <List<Subject>> به فلاتر می‌گوید که ما انتظار داریم لیستی از موضوعات برگردد
  //   final result = await Navigator.of(context).push<List<Subject>>(
  //     MaterialPageRoute(
  //       // HomeScreen را در حالت انتخاب (isPickerMode: true) باز می‌کنیم
  //       builder: (ctx) => const HomeScreen(isPickerMode: true),
  //     ),
  //   );

  //   // بعد از اینکه کاربر موضوعی را انتخاب کرد و به این صفحه برگشت،
  //   // چک می‌کنیم که آیا نتیجه‌ای وجود دارد یا خیر
  //   if (result != null && result.isNotEmpty) {
  //     setState(() {
  //       // موضوعات انتخاب شده جدید را به لیست اضافه می‌کنیم
  //       // برای جلوگیری از انتخاب موضوعات تکراری، ابتدا چک می‌کنیم
  //       for (var subject in result) {
  //         if (!_selectedSubjects.any((s) => s.id == subject.id)) {
  //           _selectedSubjects.add(subject);
  //         }
  //       }
  //     });
  //   }
  // }
  
  void _pickSubject() async {
    // HomeScreen را در یک BottomSheet باز می‌کنیم و منتظر نتیجه می‌مانیم
    final result = await showModalBottomSheet<List<Subject>>(
      context: context,
      isScrollControlled: true, // اجازه می‌دهد تا BottomSheet ارتفاع زیادی داشته باشد
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(_getResponsiveSize(context, 20)))
      ),
      builder: (_) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.85, // ۸۵ درصد ارتفاع صفحه
        child: const HomeScreen(isPickerMode: true),
      ),
    );

    // اگر کاربر موضوعی را انتخاب کرده بود، آن را به لیست اضافه کن
    if (result != null && result.isNotEmpty) {
      setState(() {
        for (var subject in result) {
          if (!_selectedSubjects.any((s) => s.id == subject.id)) {
            _selectedSubjects.add(subject);
          }
        }
      });
    }
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
                              text: '۱. موضوعات مورد نظر را انتخاب کنید',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            OutlinedButton.icon(
                              icon: Icon(Icons.add_circle_outline, color: primaryTeal, size: _getResponsiveSize(context, 24)),
                              label: const AdaptiveTextSize(
                                text: 'افزودن / ویرایش موضوعات',
                                style: TextStyle(color: primaryTeal, fontFamily: 'Vazirmatn', fontSize: 16),
                              ),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: primaryTeal,
                                side: const BorderSide(color: primaryTeal, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12))),
                                padding: EdgeInsets.symmetric(
                                  vertical: _getResponsiveSize(context, 12),
                                  horizontal: _getResponsiveSize(context, 16),
                                ),
                              ),
                              onPressed: _pickSubject
                              // _showSubjectPicker,
                            ),
                            SizedBox(height: _getResponsiveSize(context, 16)),
                            const AdaptiveTextSize(
                              text: 'موضوعات انتخاب شده:',
                              style: TextStyle(fontSize: 16, color: textDark, fontFamily: 'Vazirmatn'),
                            ),
                            SizedBox(height: _getResponsiveSize(context, 8)),
                            _selectedSubjects.isEmpty
                                ? const AdaptiveTextSize(
                                    text: 'هنوز موضوعی انتخاب نشده است.',
                                    style: TextStyle(fontStyle: FontStyle.italic, color: textMedium, fontSize: 14, fontFamily: 'Vazirmatn'),
                                  )
                                : Wrap(
                                    spacing: _getResponsiveSize(context, 8.0),
                                    runSpacing: _getResponsiveSize(context, 4.0),
                                    children: _selectedSubjects.map((subject) => Chip(
                                          label: AdaptiveTextSize(
                                            text: subject.name,
                                            style: const TextStyle(color: darkTeal, fontFamily: 'Vazirmatn', fontSize: 14),
                                          ),
                                          backgroundColor: lightTeal.withOpacity(0.2),
                                          deleteIcon: Icon(Icons.cancel, size: _getResponsiveSize(context, 20), color: darkTeal.withOpacity(0.7)),
                                          onDeleted: () => setState(() => _selectedSubjects.removeWhere((s) => s.id == subject.id)),
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
                              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: textDark, fontFamily: 'Vazirmatn'),
                            ),
                            Slider(
                              value: _numberOfQuestions,
                              min: 5,
                              max: 500,
                              divisions: (500 - 5) ~/ 5,
                              label: _numberOfQuestions.toInt().toString(),
                              onChanged: (value) => setState((){
                                 _numberOfQuestions = (value / 5).round() * 5.0;
      // اطمینان از اینکه مقدار از حداقل کمتر نشود
      if (_numberOfQuestions < 5) _numberOfQuestions = 5.0;
                              }),
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
              onPressed: _selectedSubjects.isEmpty || _isLoading ? null : _startQuiz,
              child: _isLoading
                  ? CircularProgressIndicator(color: Colors.white, strokeWidth: _getResponsiveSize(context, 3))
                  : const AdaptiveTextSize(
                      text: 'شروع آزمون',
                      style: TextStyle(fontSize: 18, color: Colors.white, fontWeight: FontWeight.bold, fontFamily: 'Vazirmatn'),
                    ),
            ),
          ],
        ),
      ),
    );
  }

void _startQuiz() async {
  if (_selectedSubjects.isEmpty) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا حداقل یک موضوع را انتخاب کنید.')));
    return;
  }
  
  setState(() { _isLoading = true; });

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final token = authProvider.token;

    if (user == null || token == null) throw Exception('اطلاعات کاربری یافت نشد.');

    // چک کردن دسترسی به موضوعات (این بخش عالی است و باقی می‌ماند)
    for (var subject in _selectedSubjects) {
      if (!user.canAccessSubject(subject.id)) {
        if (mounted) Navigator.of(context).push(MaterialPageRoute(builder: (ctx) => const PremiumScreen()));
        throw Exception('شما به موضوع "${subject.name}" دسترسی ندارید.');
      }
    }

    final subjectIds = _selectedSubjects.map((s) => s.id).toList();
    final limit = _numberOfQuestions.toInt();
    List<Question> questions = [];

    // ---- منطق کلیدی آفلاین/آنلاین ----
    final connectivityResult = await (Connectivity().checkConnectivity());

    if (connectivityResult != ConnectivityResult.none) {
      // حالت آنلاین
      try {
        print("حالت آنلاین: در حال دریافت سوالات از API...");
        questions = await _apiService.fetchRandomQuestions(subjectIds, limit, token);
        // اگر API سوالی برنگرداند، از دیتابیس محلی استفاده می‌کنیم
        if (questions.isEmpty) {
            print("API سوالی برنگگرداند، تلاش برای خواندن از حافظه محلی...");
            questions = await _hiveService.getRandomQuestions(subjectIds, limit, user.id);
        }
      } catch (e) {
        // اگر API با خطا مواجه شد، از دیتابیس محلی استفاده می‌کنیم
        print("خطا در API، تلاش برای خواندن از حافظه محلی... Error: $e");
        questions = await _hiveService.getRandomQuestions(subjectIds, limit, user.id);
      }
    } else {
      // حالت آفلاین
      print("حالت آفلاین: در حال خواندن سوالات از حافظه محلی...");
      questions = await _hiveService.getRandomQuestions(subjectIds, limit, user.id);
    }
    // ------------------------------------

    if (questions.isEmpty) {
      throw Exception('هیچ سوالی (آنلاین یا آفلاین) برای موضوعات انتخاب شده یافت نشد.');
    }

    if (mounted) {
      Navigator.of(context).pushReplacement( // از pushReplacement استفاده می‌کنیم تا کاربر به این صفحه برنگردد
        MaterialPageRoute(
          builder: (ctx) => QuizScreen(questions: questions, courseIds: subjectIds),
        ),
      );
    }
  } catch (e) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('خطا: ${e.toString().replaceAll("Exception: ", "")}')),
      );
    }
  } finally {
    if (mounted) setState(() { _isLoading = false; });
  }
}
}