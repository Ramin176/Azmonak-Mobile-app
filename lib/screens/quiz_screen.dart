
import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/attempt_details.dart';
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
void _submitAndShowResults() async {
  showDialog(context: context, barrierDismissible: false, builder: (ctx) => const Center(child: CircularProgressIndicator()));
  
  try {
    final connectivityResult = await (Connectivity().checkConnectivity());
    final apiService = ApiService();
    final token = Provider.of<AuthProvider>(context, listen: false).token;

    if (token == null || widget.courseIds.isEmpty) {
      throw Exception('اطلاعات آزمون ناقص است. لطفا دوباره تلاش کنید.');
    }
    
    final answersForApi = _userAnswers.entries.map((e) => {'questionId': e.key, 'answerIndex': e.value}).toList();
    QuizAttempt result;

    if (connectivityResult != ConnectivityResult.none) {
      // --- حالت آنلاین ---
      print("آنلاین: در حال ارسال نتایج به سرور...");
      // حالا لیست کامل ID ها را ارسال می‌کنیم
      result = await apiService.submitExam(widget.courseIds, answersForApi, token);
      result.isSynced = true;
    } else {
      // --- حالت آفلاین ---
      print("آفلاین: در حال محاسبه و ذخیره نتایج به صورت محلی...");
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
      );
    }
    
    final hiveService = HiveService();
    await hiveService.saveQuizAttempt(result);
     final details = AttemptDetails(
      attemptId: result.id,
      questions: widget.questions,
      userAnswers: _userAnswers,
    );
    await _hiveService.saveAttemptDetails(details);
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
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('خطا در ثبت نتایج: ${e.toString()}'))
        );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;
    final isBookmarked = _bookmarkedQuestions.contains(currentQuestion.id);

    return Scaffold(
      appBar: AppBar(
        title: Text('سوال ${_currentIndex + 1} از ${widget.questions.length}'),
        actions: [
          // دکمه نشانه‌گذاری
          IconButton(
            icon: Icon(
              isBookmarked ? Icons.bookmark : Icons.bookmark_border,
              color: isBookmarked ? Colors.amber : null,
            ),
            onPressed: _toggleBookmark,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6.0),
          child: TweenAnimationBuilder<double>(
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeInOut,
            tween: Tween<double>(begin: 0, end: progress),
            builder: (context, value, _) => LinearProgressIndicator(value: value),
          ),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // متن سوال
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                currentQuestion.text,
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.5),
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: 24),
            
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
                padding: const EdgeInsets.only(top: 16.0),
                child: ElevatedButton(
                  onPressed: _nextQuestion,
                  child: Text(_currentIndex == widget.questions.length - 1 ? 'پایان و نمایش نتایج' : 'سوال بعدی'),
                ),
              )
          ],
        ),
      ),
    );
  }


  Widget _buildOptionItem(Question question, int index) {
    Color borderColor = Colors.grey.shade300;
    Color backgroundColor = Colors.white;
    IconData? trailingIcon;

    if (_isAnswered) {
      if (index == question.correctAnswerIndex) {
        // گزینه صحیح
        borderColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
        trailingIcon = Icons.check_circle;
      } else if (index == _selectedOptionIndex) {
        // گزینه غلطی که کاربر انتخاب کرده
        borderColor = Colors.red;
        backgroundColor = Colors.red.withOpacity(0.1);
        trailingIcon = Icons.cancel;
      }
    }

    return GestureDetector(
      onTap: () => _answerQuestion(index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(vertical: 6),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(child: Text(question.options[index]['text'] ?? '', style: const TextStyle(fontSize: 16))),
            if (trailingIcon != null)
              Icon(trailingIcon, color: borderColor),
          ],
        ),
      ),
    );
  }

  // ویجت جدید برای نمایش توضیحات
  Widget _buildExplanationCard(String explanation) {
    return Card(
      color: Colors.blue[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.info, color: Colors.blue),
                SizedBox(width: 8),
                Text('توضیحات', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Text(explanation),
          ],
        ),
      ),
    );
  }
}