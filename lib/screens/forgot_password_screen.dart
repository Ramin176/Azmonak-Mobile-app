import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'reset_password_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});
  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

  void _sendResetCode() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا ایمیل خود را وارد کنید.')));
      return;
    }
    setState(() { _isLoading = true; });

    final response = await _apiService.forgotPassword(_emailController.text.trim());
    
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (response.containsKey('success') && response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('کد بازیابی با موفقیت به ایمیل شما ارسال شد.')),
      );
      // به صفحه بعد برو و ایمیل را هم برای استفاده بعدی ارسال کن
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (ctx) => ResetPasswordScreen(email: _emailController.text.trim())),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['msg'] ?? response['error'] ?? 'خطایی رخ داد.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('بازیابی رمز عبور')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('ایمیل حساب کاربری خود را وارد کنید تا کد بازیابی برایتان ارسال شود.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: 'ایمیل'),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _sendResetCode,
                    child: const Text('ارسال کد بازیابی'),
                  ),
          ],
        ),
      ),
    );
  }
}