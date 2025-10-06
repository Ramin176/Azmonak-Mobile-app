import 'package:azmoonak_app/helpers/adaptive_text_size.dart';
import 'package:azmoonak_app/services/api_service.dart';
import 'package:flutter/material.dart';
import '../models/question.dart';
import 'result_screen.dart'; 
import '../models/quiz_attempt.dart'; 

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

  static const Color primaryTeal = Color(0xFF008080);
  static const Color lightTeal = Color(0xFF4DB6AC);
  static const Color darkTeal = Color(0xFF004D40);
  static const Color accentYellow = Color(0xFFFFD700);
  static const Color textDark = Color(0xFF212121);
  static const Color textMedium = Color(0xFF607D8B);
  static const Color backgroundLight = Color(0xFFF8F9FA);

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

 
    final trialResult = QuizAttempt(
      id: 'trial_result',
      percentage: (correct / widget.questions.length) * 100,
      createdAt: DateTime.now(),
      subjectName: 'آزمون آمادگی',
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
          isTrial: true, 
        ),
      ),
    );
  }
double _getResponsiveSize(double baseSize) {
    const double referenceWidth = 375.0;
    final double screenWidth = MediaQuery.of(context).size.width;
    double scaleFactor = screenWidth / referenceWidth;
    if (scaleFactor > 1.5) scaleFactor = 1.5;
    return baseSize * scaleFactor;
  }
  @override
  Widget build(BuildContext context) {
   final currentQuestion = widget.questions[_currentIndex];
    final progress = (_currentIndex + 1) / widget.questions.length;
 final fullImageUrl = currentQuestion.imageUrl != null 
      ? "${ApiService.baseUrl.replaceAll('/api', '')}${currentQuestion.imageUrl}" // برای شبیه‌ساز اندروید
      : null;
    return Scaffold(
      appBar: AppBar(
         backgroundColor: Colors.teal,
        elevation: 0,
        centerTitle: true,
        title:  AdaptiveTextSize(
          text: 'سوال ${_currentIndex + 1} از ${widget.questions.length}',
          style: TextStyle(
            fontSize: _getResponsiveSize(18),
            fontWeight: FontWeight.bold,
            color: Colors.white,
            fontFamily: 'Vazirmatn',
          ),
        ),
       
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
       Card(
              elevation: 4,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_getResponsiveSize( 20))),
              child: Container(
                padding: EdgeInsets.all(_getResponsiveSize( 20.0)),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(_getResponsiveSize(20)),
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
                        fontSize: _getResponsiveSize( 18),
                        fontWeight: FontWeight.bold,
                        color: textDark,
                        fontFamily: 'Vazirmatn',
                      ),
                      textAlign: TextAlign.justify,
                    ),
                    if (fullImageUrl != null && fullImageUrl.isNotEmpty)
                      Padding(
                        padding: EdgeInsets.only(top: _getResponsiveSize( 16.0)),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(_getResponsiveSize( 12)),
                          child: Image.network(
                            fullImageUrl,
                            height: _getResponsiveSize(180),
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
                              height: _getResponsiveSize(180),
                              color: backgroundLight,
                              child: Center(
                                child: Icon(Icons.broken_image, color: textMedium, size: _getResponsiveSize( 50)),
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          
            const SizedBox(height: 24),
            
          
            Expanded(
              child: ListView.builder(
                itemCount: currentQuestion.options.length,
                itemBuilder: (context, index) {
                  return _buildOptionItem(currentQuestion, index);
                },
              ),
            ),
            
           
            if (_isAnswered && currentQuestion.explanation.isNotEmpty)
              _buildExplanationCard(currentQuestion.explanation),

          
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
       
        borderColor = Colors.green;
        backgroundColor = Colors.green.withOpacity(0.1);
        trailingIcon = Icons.check_circle;
      } else if (index == _selectedOptionIndex) {
      
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
