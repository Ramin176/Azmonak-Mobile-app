import 'package:flutter/material.dart';
import '../models/quiz_attempt.dart';
import '../models/question.dart';

class ResultScreen extends StatelessWidget {
  final QuizAttempt attempt;
  final List<Question> questions;
  final Map<String, int> userAnswers;
  final bool isTrial;
  const ResultScreen({
    super.key,
    required this.attempt,
    required this.questions,
    required this.userAnswers,
    this.isTrial = false,
  });

  @override
  Widget build(BuildContext context) {
    const tealColor = Color(0xFF008080);
    final percentage = attempt.percentage;
    final bool passed = percentage >= 40;

    // --- مدیریت مقادیر Null ---
    final correct = attempt.correctAnswers ?? 0;
    final wrong = attempt.wrongAnswers ?? 0;
    final total = attempt.totalQuestions ?? 0;
    final skipped = total - (correct + wrong);
    final achievedScore = attempt.achievedScore ?? 0;
    final totalScore = attempt.totalScore ?? 0;
    // -------------------------

    return Scaffold(
      appBar: AppBar(
        title: const Text('نتیجه آزمون'),
        backgroundColor: Colors.transparent,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
                if (isTrial)
              ElevatedButton(
                onPressed: () => Navigator.of(context).pop(), // فقط به صفحه لاگین برگرد
                child: Text('بازگشت به صفحه قبل'),
              )
            else
            !isTrial? SizedBox(height: 10,):  Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('خانه'),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.refresh),
                    label: const Text('آزمون مجدد'),
                  ),
                ],
              ),
              SizedBox(height: 20,),
              SizedBox(
                width: 150,
                height: 150,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 10,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(passed ? Colors.green : Colors.red),
                    ),
                    Center(
                      child: Text(
                        '${percentage.toStringAsFixed(0)}%',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text(
                passed ? 'قبول شدید!' : 'موفق نشدید',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: passed ? Colors.green : Colors.red),
              ),
              const SizedBox(height: 32),
              
              _buildResultDetailRow(Icons.check_circle, 'پاسخ‌های صحیح', '$correct'),
              _buildResultDetailRow(Icons.cancel, 'پاسخ‌های غلط', '$wrong'),
              _buildResultDetailRow(Icons.help_outline, 'بدون پاسخ', '$skipped'),
              _buildResultDetailRow(Icons.score, 'امتیاز کسب شده', '$achievedScore / $totalScore'),
              
              const SizedBox(height: 40),
              
             isTrial? SizedBox(height: 10,): Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                    icon: const Icon(Icons.home),
                    label: const Text('خانه'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey),
                  ),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.of(context).pop(), // برگشت به صفحه ساخت آزمون
                    icon: const Icon(Icons.refresh),
                    label: const Text('آزمون مجدد'),
                    style: ElevatedButton.styleFrom(backgroundColor: tealColor),
                  ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResultDetailRow(IconData icon, String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, color: Colors.grey[600]),
              const SizedBox(width: 16),
              Text(title, style: const TextStyle(fontSize: 16)),
            ],
          ),
          Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}