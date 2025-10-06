import 'package:azmoonak_app/helpers/hive_db_service.dart';
import 'package:azmoonak_app/models/question.dart';
import 'package:azmoonak_app/services/api_service.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/auth_provider.dart';
import 'login_screen.dart';
import 'main_screen.dart';
import 'package:provider/provider.dart';
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
    // از WidgetsBinding استفاده می‌کنیم تا مطمئن شویم BuildContext آماده است
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   _syncTrialQuestions();
    //   _checkAuthAndNavigate();
    // });
  }

  Future<void> _checkAuthAndNavigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final bool isLoggedIn = await authProvider.tryAutoLogin();
     await Future.wait([
      _syncAppSettings(), // <-- همگام‌سازی تنظیمات (شامل درباره ما)
      _syncTrialQuestions(), // همگام‌سازی سوالات آزمایشی
    ]);
     await Future.delayed(const Duration(milliseconds: 500));
      
    if (mounted) {
      if (isLoggedIn) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const MainScreen()),
        );
      } else {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (ctx) => const LoginScreen()),
        );
      }
    }
  }
 Future<void> _syncAppSettings() async {
    try {
      final settings = await ApiService().fetchSettings();
      final settingsBox = await Hive.openBox('app_settings');
      
      // ذخیره متن "درباره ما" در Hive
      await settingsBox.put('about_us_text', settings['aboutUsText']);
      // می‌توانید پلن‌ها و اطلاعات پرداخت را هم اینجا ذخیره کنید
       await settingsBox.put('deactivated_user_message', settings['deactivatedUserMessage']);
      print("App settings synced successfully.");
    } catch (e) {
      print("Could not sync app settings: $e");
    }
  }

//  Future<void> _syncTrialQuestions() async {
//     try {
//        final hiveService = HiveService();
//     final onlineQuestions = await ApiService.fetchTrialQuestions();
//       await hiveService.syncTrialQuestions(onlineQuestions);
//       print("${onlineQuestions.length} trial questions synced successfully.");
//     } catch (e) {
//       print("Could not sync trial questions: $e");
//     }
//   }
Future<void> _syncTrialQuestions() async {
  // ابتدا چک می‌کنیم آیا از قبل سوالی داریم یا نه
  final trialBox = Hive.box<Question>('trial_questions');
  if (trialBox.isNotEmpty) {
    print("[DEBUG] سوالات آزمایشی از قبل در Hive وجود دارد. نیازی به فراخوانی API نیست.");
    return; // اگر سوالی بود، از تابع خارج شو
  }

  print("[DEBUG] باکس سوالات آزمایشی خالی است. در حال تلاش برای دریافت از سرور...");
  
  try {
    // چون متد استاتیک است، نیازی به ساختن نمونه نیست (فعلا)
    final onlineQuestions = await ApiService.fetchTrialQuestions();
    
    if (onlineQuestions.isNotEmpty) {
      final hiveService = HiveService();
      await hiveService.syncTrialQuestions(onlineQuestions);
      print("[DEBUG] موفقیت: ${onlineQuestions.length} سوال آزمایشی با موفقیت دریافت و ذخیره شد.");
    } else {
      print("[DEBUG] هشدار: API فراخوانی شد ولی هیچ سوالی برنگرداند.");
    }
  } catch (e, stacktrace) {
    // ===== این بخش خطا را با جزئیات کامل چاپ می‌کند =====
    print("=================================================");
    print("[DEBUG] خطای بسیار مهم در هنگام فراخوانی API رخ داد!");
    print("نوع خطا: ${e.runtimeType}");
    print("متن خطا: $e");
    print("Stacktrace: \n$stacktrace");
    print("=================================================");
  }
}
  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF008080), // رنگ Teal
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // اینجا می‌توانید لوگوی خود را قرار دهید
            Text(
              'آزمونک',
              style: TextStyle(fontSize: 40, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            SizedBox(height: 20),
            CircularProgressIndicator(color: Colors.white),
          ],
        ),
      ),
    );
  }
}