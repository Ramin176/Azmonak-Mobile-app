import 'package:azmoonak_app/models/attempt_details.dart';
import 'package:azmoonak_app/models/category.dart';
import 'package:azmoonak_app/models/course.dart';
import 'package:azmoonak_app/models/question.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
void main() async{
   WidgetsFlutterBinding.ensureInitialized(); 
  await Hive.initFlutter();
  Hive.registerAdapter(CategoryAdapter());
  Hive.registerAdapter(CourseAdapter());
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(QuizAttemptAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(AttemptDetailsAdapter());
   await initializeDateFormatting('fa', null); 
  runApp(const AzmoonakApp());
}

class AzmoonakApp extends StatelessWidget {
  const AzmoonakApp({super.key});
  
  @override
  Widget build(BuildContext context) {
    // تعریف رنگ اصلی Teal
    const Color tealColor = Color(0xFF008080);
    // تعریف یک رنگ پس‌زمینه روشن و ملایم
    const Color backgroundColor = Color(0xFFF5F7FA);
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: MaterialApp(
        title: 'آزمونک',
        // --- تعریف تم سراسری ---
        theme: ThemeData(
          primaryColor: tealColor,
          scaffoldBackgroundColor: backgroundColor,
          fontFamily: 'Vazir', // مطمئن شوید فونت را اضافه کرده‌اید

          // استایل AppBar
          appBarTheme: const AppBarTheme(
            backgroundColor: backgroundColor,
            foregroundColor: Colors.black87, // رنگ آیکون‌ها و متن
            elevation: 0,
            centerTitle: true,
          ),

          // استایل دکمه‌های اصلی
          elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
              backgroundColor: tealColor,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 24),
              textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, fontFamily: 'Vazir'),
            ),
          ),

          // استایل کارت‌ها
          cardTheme: CardTheme(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            margin: const EdgeInsets.symmetric(vertical: 8),
          ),

          // استایل فیلدهای ورودی
          inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: tealColor, width: 2),
            ),
          ),
        ),
        // ------------------------
        home: const SplashScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
  }
}