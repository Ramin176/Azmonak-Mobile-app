import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class DeactivatedScreen extends StatelessWidget {
  const DeactivatedScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder(
      valueListenable: Hive.box('app_settings').listenable(),
       builder: (context, box, widget){
        // خواندن متن از Hive با یک مقدار پیش‌فرض
        final message = box.get(
          'deactivated_user_message', 
          defaultValue: 'حساب کاربری شما غیرفعال شده است. لطفا با پشتیبانی تماس بگیرید.'
        );
      return Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.block, size: 80, color: Colors.red),
                const SizedBox(height: 24),
                const Text(
                  'حساب کاربری شما غیرفعال شده است',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 16),
                Text(
                    message,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16, color: Colors.grey, height: 1.5),
                  ),
                const SizedBox(height: 32),
                ElevatedButton(
                  onPressed: () {
                    // کاربر را کامل logout کن و به صفحه ورود برگردان
                    Provider.of<AuthProvider>(context, listen: false).logout();
                  },
                  child: const Text('بازگشت به صفحه ورود'),
                )
              ],
            ),
          ),
        ),
      );
  });
  }
}