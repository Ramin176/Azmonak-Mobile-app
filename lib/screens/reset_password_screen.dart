import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String email;
  
  const ResetPasswordScreen({super.key, required this.email});
  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _tokenController = TextEditingController();
  final _passwordController = TextEditingController();
  final _apiService = ApiService();
  bool _isLoading = false;

   bool _isPasswordVisible = false;
  void _resetPassword() async {
    if (_tokenController.text.trim().isEmpty || _passwordController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('لطفا تمام فیلدها را پر کنید.')));
      return;
    }
    setState(() { _isLoading = true; });

    final response = await _apiService.resetPassword(
      widget.email,
      _tokenController.text.trim(),
      _passwordController.text.trim(),
    );
    
    if (!mounted) return;
    setState(() { _isLoading = false; });

    if (response.containsKey('success') && response['success'] == true) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('رمز عبور با موفقیت تغییر کرد. لطفا با رمز جدید وارد شوید.')),
      );
      // به صفحه ورود برو و تمام صفحات قبلی را از حافظه پاک کن
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (ctx) => const LoginScreen()),
        (route) => false,
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(response['msg'] ?? response['error'] ?? 'کد وارد شده اشتباه یا منقضی شده است.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('تنظیم رمز عبور جدید')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('کد ۶ رقمی که به ایمیل ${widget.email} ارسال شده و رمز عبور جدید خود را وارد کنید.', textAlign: TextAlign.center),
            const SizedBox(height: 20),
            TextField(
              controller: _tokenController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'کد بازیابی'),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _passwordController,
              obscureText:  !_isPasswordVisible,
              decoration:  InputDecoration(labelText: 'رمز عبور جدید', suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible ? Icons.visibility_off : Icons.visibility,
                    ),
                    onPressed: () {
                      // ۴. با کلیک، وضعیت را تغییر بده
                      setState(() {
                        _isPasswordVisible = !_isPasswordVisible;
                      });
                    },
                  ),),
            ),
            const SizedBox(height: 30),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _resetPassword,
                    child: const Text('تغییر رمز عبور'),
                  ),
          ],
        ),
      ),
    );
  }
}