import 'package:flutter/material.dart';
import '../models/question.dart';
import 'result_screen.dart'; // ما از همان صفحه نتایج استفاده می‌کنیم
import '../models/quiz_attempt.dart'; // برای ارسال به ResultScreen

class TrialQuizScreen extends StatefulWidget {
  final List<Question> questions;
  const TrialQuizScreen({super.key, required this.questions});

  @override
  State<TrialQuizScreen> createState() => _TrialQuizScreenState();
}

class _TrialQuizScreenState extends State<TrialQuizScreen> {
  int _currentIndex = 0;
  int? _selectedOptionIndex;
  bool _isAnswered = false;
  final Map<String, int> _userAnswers = {};

  void _answerQuestion(int index) {
    if (_isAnswered) return;
    setState(() {
      _selectedOptionIndex = index;
      _isAnswered = true;
    });
    _userAnswers[widget.questions[_currentIndex].id] = index;
  }

  void _nextQuestion() {
    if (_currentIndex < widget.questions.length - 1) {
      setState(() {
        _currentIndex++;
        _isAnswered = false;
        _selectedOptionIndex = null;
      });
    } else {
      // --- تغییر اصلی اینجاست: محاسبه محلی و رفتن به صفحه نتایج ---
      _showTrialResults();
    }
  }
  
  void _showTrialResults() {
    int correct = 0;
    widget.questions.forEach((q) {
      if (_userAnswers.containsKey(q.id) && _userAnswers[q.id] == q.correctAnswerIndex) {
        correct++;
      }
    });

    // یک آبجکت QuizAttempt موقت فقط برای نمایش در ResultScreen می‌سازیم
    final trialResult = QuizAttempt(
      id: 'trial_result',
      percentage: (correct / widget.questions.length) * 100,
      createdAt: DateTime.now(),
      courseName: 'آزمون آمادگی',
      correctAnswers: correct,
      totalQuestions: widget.questions.length,
      wrongAnswers: widget.questions.length - correct,
      achievedScore: correct,
      totalScore: widget.questions.length,
      isSynced: false,
      
    );
    
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (ctx) => ResultScreen(
          attempt: trialResult,
          questions: widget.questions,
          userAnswers: _userAnswers,
          isTrial: true, // یک فلگ برای اینکه ResultScreen بداند این آزمون آزمایشی است
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
   final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;

    return Scaffold(
      appBar: AppBar(
        title: Text('سوال ${_currentIndex + 1} از ${widget.questions.length}'),
        actions: [
          // دکمه نشانه‌گذاری
         
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
