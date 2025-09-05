import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/screens/quiz_screen.dart';
import 'package:azmoonak_app/screens/trial_quiz_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'home_screen.dart';
import 'main_screen.dart'; // import MainScreen
import 'register_screen.dart'; // import RegisterScreen
import 'forgot_password_screen.dart';
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
   bool _isPasswordVisible = false;
  void _login() async {
    setState(() { _isLoading = true; });
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    bool success = await authProvider.login(
      _emailController.text.trim(),
      _passwordController.text.trim(),
    );
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (success) {
     
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const MainScreen()),
        (route) => false, 
      );
     
    } else {
      final error = authProvider.errorMessage;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(error ?? 'خطای نامشخص')),
      );
    }
  }
void _startDemoQuiz() async {
  showDialog(context: context, builder: (_) => const Center(child: CircularProgressIndicator()));
  
  final hiveService = HiveService();
  final trialQuestions = await hiveService.getTrialQuestions();
  
  if(mounted) Navigator.of(context).pop();
  
  if (mounted && trialQuestions.isNotEmpty) {
      Navigator.of(context).push(
          MaterialPageRoute(builder: (ctx) => TrialQuizScreen(
              questions: trialQuestions,
          ))
      );
  } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('سوالات آزمایشی یافت نشد. لطفا به اینترنت متصل شوید و برنامه را دوباره باز کنید.')));
  }
}
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            children: [
              const Text('ورود به آزمونک', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              const SizedBox(height: 40),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: 'ایمیل'),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _passwordController,
                obscureText:  !_isPasswordVisible,
                decoration:  InputDecoration(labelText: 'رمز عبور', suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),),
              ),
              const SizedBox(height: 40),
              _isLoading
                  ? const CircularProgressIndicator()
                  : SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(onPressed: _login, child: const Text('ورود')),
                  ),
              TextButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (ctx) => const RegisterScreen()),
                  );
                },
                child: const Text('حساب کاربری ندارید؟ ثبت‌نام کنید'),
              ),
                Align(
                alignment: Alignment.center,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (ctx) => const ForgotPasswordScreen()),
                    );
                  },
                  child: const Text('رمز عبور خود را فراموش کرده‌اید؟'),
                ),
              ),
              SizedBox(height: 20,),
               const Text('میخواهید اول ما را امتحان کنید؟', style: TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                icon: const Icon(Icons.quiz_outlined),
                label: const Text('شروع آزمون آمادگی (۱۰ سوال رایگان)'),
                onPressed: _startDemoQuiz,
              ),
            ],
          ),
        ),
      ),
    );
  }
}