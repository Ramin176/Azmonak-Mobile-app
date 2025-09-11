
import 'package:azmoonak_app/helpers/adaptive_text_size.dart';
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/attempt_details.dart';
import 'package:azmoonak_app/models/attempt_question.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/providers/auth_provider.dart';
import 'package:azmoonak_app/screens/result_screen.dart';
import 'package:azmoonak_app/services/api_service.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'dart:async'; // برای تایمر
import '../models/question.dart';
// ... import های دیگر

class QuizScreen extends StatefulWidget {
  final List<Question> questions;
  final List<String> courseIds;
  const QuizScreen({super.key, required this.questions, required this.courseIds});

  @override
  State<QuizScreen> createState() => _QuizScreenState();
}

class _QuizScreenState extends State<QuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  bool? _isCorrect;
  final Map<String, int> _userAnswers = {};
  final HiveService _hiveService = HiveService();
  final Set<String> _bookmarkedQuestions = {};
static const Color primaryTeal = Color(0xFF008080); // Teal اصلی
  static const Color lightTeal = Color(0xFF4DB6AC); // Teal روشن‌تر
  static const Color darkTeal = Color(0xFF004D40); // Teal تیره‌تر
  static const Color accentYellow = Color(0xFFFFD700); // زرد تاکید (برای ستاره)
  static const Color textDark = Color(0xFF212121); // متن تیره
  static const Color textMedium = Color(0xFF607D8B); // متن متوسط
  static const Color backgroundLight = Color(0xFFF8F9FA); // پس‌زمینه روشن
  double _getResponsiveSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    // Adjust this multiplier as needed for different screen sizes
    return baseSize * (screenWidth / 375.0); // Assuming 375 is a common base width (e.g., iPhone 8)
  }
  void _answerQuestion(int index) {
    if (_isAnswered) return; // اگر قبلا پاسخ داده شده، کاری نکن

    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
      _isCorrect = (widget.questions[_currentIndex].correctAnswerIndex == index);
    });
    
    // پاسخ کاربر را ذخیره کن
    _userAnswers[widget.questions[_currentIndex].id] = index;
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedOptionIndex = null;
        _isCorrect = null;
      });
    } else {
      _submitAndShowResults();
    }
  }

  void _toggleBookmark() {
    final questionId = widget.questions[_currentIndex].id;
    setState(() {
      if (_bookmarkedQuestions.contains(questionId)) {
        _bookmarkedQuestions.remove(questionId);
      } else {
        _bookmarkedQuestions.add(questionId);
      }
    });
  }
// void _submitAndShowResults() async {
//   showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
//    final user = Provider.of<AuthProvider>(context, listen: false).user;
//   try {
//     final connectivityResult = await (Connectivity().checkConnectivity());
//     final apiService = ApiService();
//     final token = Provider.of<AuthProvider>(context, listen: false).token;

//     if (token == null || widget.courseIds.isEmpty) {
//       throw Exception('اطلاعات آزمون ناقص است. لطفا دوباره تلاش کنید.');
//     }
    
//     final answersForApi = _userAnswers.entries.map((e) => {'questionId': e.key, 'answerIndex': e.value}).toList();
//     QuizAttempt result;
//  final questionsForReview = widget.questions.map((q) {
//       return AttemptQuestion(
//         id: q.id,
//         text: q.text,
//         options: q.options,
//         correctAnswerIndex: q.correctAnswerIndex,
//       );
//     }).toList();
//      final details = AttemptDetails(
//       attemptId: result.id,
//       questions: questionsForReview, // <-- حالا از لیست تبدیل شده استفاده می‌کنیم
//       userAnswers: _userAnswers,
//     );
//     await _hiveService.saveAttemptDetails(details, user!.id);
//     if (connectivityResult != ConnectivityResult.none) {
//       // --- حالت آنلاین ---
//       print("آنلاین: در حال ارسال نتایج به سرور...");
//       // حالا لیست کامل ID ها را ارسال می‌کنیم
//       result = await apiService.submitExam(widget.courseIds, answersForApi, token);
//       result.isSynced = true;
//     } else {
//       // --- حالت آفلاین ---
//       print("آفلاین: در حال محاسبه و ذخیره نتایج به صورت محلی...");
//       int correct = 0;
//       widget.questions.forEach((q) {
//         if (_userAnswers.containsKey(q.id) && _userAnswers[q.id] == q.correctAnswerIndex) { correct++; }
//       });
//       result = QuizAttempt(
//         id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
//         percentage: (correct / widget.questions.length) * 100,
//         createdAt: DateTime.now(),
//         correctAnswers: correct,
//         totalQuestions: widget.questions.length,
//         isSynced: false,
//       );
//     }
    
//     final hiveService = HiveService();
//     await _hiveService.saveQuizAttempt(result, user!.id);
//      final details = AttemptDetails(
//       attemptId: result.id,
//       questions: widget.questions,
//       userAnswers: _userAnswers,
//     );
//       await _hiveService.saveQuizAttempt(result, user!.id);
//     if (mounted) Navigator.of(context, rootNavigator: true).pop();
//     if (mounted) {
//         Navigator.of(context).pushReplacement(
//             MaterialPageRoute(
//                 builder: (ctx) => ResultScreen(
//                     attempt: result,
//                     questions: widget.questions,
//                     userAnswers: _userAnswers,
//                 ),
//             ),
//         );
//     }
//   } catch (e) {
//     if (mounted) Navigator.of(context, rootNavigator: true).pop();
//     if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(content: Text('خطا در ثبت نتایج: ${e.toString()}'))
//         );
//     }
//   }
// }

void _submitAndShowResults() async {
  showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));

  try {
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final user = authProvider.user;
    final token = authProvider.token;
    final connectivityResult = await (Connectivity().checkConnectivity());
    final answersForApi = _userAnswers.entries.map((e) => {'questionId': e.key, 'answerIndex': e.value}).toList();
    
    // متغیر result را اینجا با مقدار اولیه تعریف می‌کنیم
    QuizAttempt result;

    if (connectivityResult != ConnectivityResult.none && token != null && user != null) {
      // --- حالت آنلاین ---
      final apiService = ApiService();
      result = await apiService.submitExam(widget.courseIds, answersForApi, token);
      result.isSynced = true;
    } else {
      // --- حالت آفلاین ---
      int correct = 0;
      widget.questions.forEach((q) {
        if (_userAnswers.containsKey(q.id) && _userAnswers[q.id] == q.correctAnswerIndex) { correct++; }
      });
      result = QuizAttempt(
        id: 'offline_${DateTime.now().millisecondsSinceEpoch}',
        percentage: (correct / widget.questions.length) * 100,
        createdAt: DateTime.now(),
        correctAnswers: correct,
        totalQuestions: widget.questions.length,
        isSynced: false,
        courseName: widget.courseIds.length == 1 ? "Single Course" : "آزمون عمومی", // یک نام پیش‌فرض
      );
    }
    
    // --- ذخیره در Hive (بخش کلیدی) ---
    final hiveService = HiveService();
    
    // ۱. ذخیره نتیجه کلی
    if(user != null) await hiveService.saveQuizAttempt(result, user.id);

    // ۲. تبدیل Question ها به AttemptQuestion برای ذخیره جزئیات
    final questionsForReview = widget.questions.map((q) {
  return AttemptQuestion(
    id: q.id,
    text: q.text,
    // --- تغییر اصلی: فقط متن گزینه‌ها را استخراج می‌کنیم ---
    options: q.options.map((opt) => opt['text'] ?? '').toList(),
    correctAnswerIndex: q.correctAnswerIndex,
  );
}).toList();

    // ۳. ساخت آبجکت جزئیات
   final details = AttemptDetails(
  attemptId: result.id,
  questions: questionsForReview,
  userAnswers: _userAnswers, // <-- اینجا بدون تغییر است
);

    // ۴. ذخیره جزئیات
    if(user != null) await hiveService.saveAttemptDetails(details, user.id);
    
    // ------------------------------------

    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (mounted) {
        Navigator.of(context).pushReplacement(
            MaterialPageRoute(
                builder: (ctx) => ResultScreen(
                    attempt: result,
                    questions: widget.questions,
                    userAnswers: _userAnswers,
                ),
            ),
        );
    }
  } catch (e) {
    if (mounted) Navigator.of(context, rootNavigator: true).pop();
    if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('خطا در ثبت نتایج: ${e.toString()}')));
    }
  }
}
  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;
    final isBookmarked = _bookmarkedQuestions.contains(currentQuestion.id);
 final fullImageUrl = currentQuestion.imageUrl != null 
      ? "http://143.20.64.200${currentQuestion.imageUrl}" // برای شبیه‌ساز اندروید
      : null;
    return Scaffold(
      backgroundColor: backgroundLight,
      appBar: AppBar(
        backgroundColor: primaryTeal,
        elevation: 0,
        centerTitle: true,
        title: AdaptiveTextSize(
          text: 'سوال ${_currentIndex + 1} از ${widget.questions.length}',
          style: TextStyle(
            fontSize: _getResponsiveSize(context, 18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Vazirmatn',
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? accentYellow : Colors.white,
              size: _getResponsiveSize(context, 26),
            ),
            onPressed: _toggleBookmark,
          ),
          SizedBox(width: _getResponsiveSize(context, 8)),
        ],
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(_getResponsiveSize(context, 6.0)),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, _) => LinearProgressIndicator(
              value: value,
              backgroundColor: lightTeal.withOpacity(0.5),
              valueColor: const AlwaysStoppedAnimation<Color>(accentYellow),
            ),
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.all(_getResponsiveSize(context, 16.0)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // کارت سوال
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
              child: Container(
                padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
                  gradient: LinearGradient(
                    colors: [lightTeal.withOpacity(0.1), Colors.white],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdaptiveTextSize(
                      text: currentQuestion.text,
                      style: TextStyle(
                        fontSize: _getResponsiveSize(context, 18),
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        fontFamily: 'Vazirmatn',
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    if (fullImageUrl != null && fullImageUrl.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: _getResponsiveSize(context, 16.0)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 12)),
                          child: Image.network(
                            fullImageUrl,
                            height: _getResponsiveSize(context, 180),
                            fit: BoxFit.contain,
                            loadingBuilder: (context, child, loadingProgress) {
                              if (loadingProgress == null) return child;
                              return Center(
                                child: CircularProgressIndicator(
                                  color: primaryTeal,
                                  value: loadingProgress.expectedTotalBytes != null
                                      ? loadingProgress.cumulativeBytesLoaded / loadingProgress.expectedTotalBytes!
                                      : null,
                                ),
                              );
                            },
                            errorBuilder: (context, error, stackTrace) => Container(
                              height: _getResponsiveSize(context, 180),
                              color: backgroundLight,
                              child: Center(
                                child: Icon(Icons.broken_image, color: textMedium, size: _getResponsiveSize(context, 50)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            SizedBox(height: _getResponsiveSize(context, 24)),

            // لیست گزینه‌ها
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {
                  return _buildOptionItem(currentQuestion, index);
                },
              ),
            ),

            // نمایش توضیحات (فقط بعد از پاسخ دادن)
            if (_isAnswered && currentQuestion.explanation.isNotEmpty)
              _buildExplanationCard(currentQuestion.explanation),

            // دکمه بعدی (فقط بعد از پاسخ دادن ظاهر می‌شود)
            if (_isAnswered)
              Padding(
                padding: EdgeInsets.only(top: _getResponsiveSize(context, 16.0)),
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryTeal,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 30))),
                    padding: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 14)),
                    elevation: 6,
                  ),
                  child: AdaptiveTextSize(
                    text: _currentIndex == widget.questions.length - 1 ? 'پایان و نمایش نتایج' : 'سوال بعدی',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontFamily: 'Vazirmatn',
                      fontSize: _getResponsiveSize(context, 16),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }


  Widget _buildOptionItem(Question question, int index) {
    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    IconData? trailingIcon;
    Color iconColor = textMedium.withOpacity(0.7);

    if (_isAnswered) {
      if (index == question.correctAnswerIndex) {
        // گزینه صحیح
        borderColor = primaryTeal; // از پالت Teal
        backgroundColor = primaryTeal.withOpacity(0.1);
        trailingIcon = Icons.check_circle_rounded;
        iconColor = primaryTeal;
      } else if (index == _selectedOptionIndex) {
        // گزینه غلطی که کاربر انتخاب کرده
        borderColor = Colors.red.shade600;
        backgroundColor = Colors.red.shade50.withOpacity(0.7);
        trailingIcon = Icons.cancel_rounded;
        iconColor = Colors.red.shade600;
      }
    } else if (index == _selectedOptionIndex) {
      // گزینه انتخاب شده قبل از پاسخ نهایی
      borderColor = lightTeal;
      backgroundColor = lightTeal.withOpacity(0.05);
    }

    return Card(
      elevation: _isAnswered && (index == question.correctAnswerIndex || index == _selectedOptionIndex) ? 4 : 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15))),
      margin: EdgeInsets.symmetric(vertical: _getResponsiveSize(context, 8)),
      child: InkWell(
        borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15)),
        onTap: () => _answerQuestion(index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          padding: EdgeInsets.symmetric(
              horizontal: _getResponsiveSize(context, 16), vertical: _getResponsiveSize(context, 14)),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(_getResponsiveSize(context, 15)),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: AdaptiveTextSize(
                  text: question.options[index]['text'] ?? '',
                  style: TextStyle(
                    fontSize: _getResponsiveSize(context, 16),
                    color: textDark,
                    fontFamily: 'Vazirmatn',
                  ),
                ),
              ),
              if (trailingIcon != null)
                Icon(trailingIcon, color: iconColor, size: _getResponsiveSize(context, 24)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExplanationCard(String explanation) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20))),
      margin: EdgeInsets.only(top: _getResponsiveSize(context, 16.0)),
      child: Container(
        padding: EdgeInsets.all(_getResponsiveSize(context, 20.0)),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(_getResponsiveSize(context, 20)),
          gradient: LinearGradient(
            colors: [primaryTeal.withOpacity(0.05), Colors.white],
            begin: Alignment.bottomRight,
            end: Alignment.topLeft,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.info_rounded, color: primaryTeal, size: _getResponsiveSize(context, 28)),
                SizedBox(width: _getResponsiveSize(context, 10)),
                AdaptiveTextSize(
                  text: 'توضیحات',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: _getResponsiveSize(context, 17),
                      color: primaryTeal,
                      fontFamily: 'Vazirmatn'),
                ),
              ],
            ),
            SizedBox(height: _getResponsiveSize(context, 12)),
            AdaptiveTextSize(
              text: explanation,
              style: TextStyle(
                fontSize: _getResponsiveSize(context, 15),
                color: textMedium,
                fontFamily: 'Vazirmatn',
                height: 1.6,
              ),
              textAlign: TextAlign.justify,
            ),
          ],
        ),
      ),
    );
  }
}