import 'package:azmoonak_app/models/attempt_details.dart';
import 'package:azmoonak_app/models/subject.dart';
import 'package:azmoonak_app/models/purchased_subject.dart';
import 'package:azmoonak_app/models/question.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/models/settings.dart';
import 'package:azmoonak_app/models/user.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'providers/auth_provider.dart';
import 'screens/splash_screen.dart';
import 'models/attempt_question.dart';
import 'screens/deactivated_screen.dart';
void main() async{
   WidgetsFlutterBinding.ensureInitialized(); 
  await Hive.initFlutter();
   Hive.registerAdapter(SubjectAdapter()); 
  Hive.registerAdapter(PurchasedSubjectAdapter()); 
  Hive.registerAdapter(QuestionAdapter());
  Hive.registerAdapter(QuizAttemptAdapter());
  Hive.registerAdapter(AppUserAdapter());
  Hive.registerAdapter(AttemptDetailsAdapter());
  Hive.registerAdapter(AttemptQuestionAdapter());
  Hive.registerAdapter(AppSettingsAdapter());
  Hive.registerAdapter(SubscriptionPlanAdapter()); 
   await Hive.openBox<AppUser>('userBox');
  await Hive.openBox<Question>('trial_questions');
  await Hive.openBox<AppSettings>('settings');
   await initializeDateFormatting('fa', null); 
  runApp( AzmoonakApp());
}

class AzmoonakApp extends StatelessWidget {
   
  @override
  Widget build(BuildContext context) {
   
    const Color tealColor = Color(0xFF008080);
    
    const Color backgroundColor = Color(0xFFF5F7FA);
    return ChangeNotifierProvider(
      create: (ctx) => AuthProvider(),
      child: Consumer<AuthProvider>(
         builder: (ctx, auth, _) => MaterialApp(
          title: 'آزمونک',
            locale: const Locale('fa'),
          supportedLocales: const [
            Locale('fa'), 
          ],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
        
        
          theme: ThemeData(
            primaryColor: tealColor,
            scaffoldBackgroundColor: backgroundColor,
            fontFamily: 'Vazir',
        
            appBarTheme: const AppBarTheme(
              backgroundColor: backgroundColor,
              foregroundColor: Colors.black87, 
              elevation: 0,
              centerTitle: true,
            ),
        
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
        
            cardTheme: CardTheme(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              margin: const EdgeInsets.symmetric(vertical: 8),
            ),
        
           
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
         
          home:auth.isDeactivated 
              ? const DeactivatedScreen() 
              :  const SplashScreen(),
          debugShowCheckedModeBanner: false,
        ),
      ),
    );
  }
}