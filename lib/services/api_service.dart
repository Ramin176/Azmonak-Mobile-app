import 'dart:convert';
import 'package:azmoonak_app/models/category.dart';
import 'package:azmoonak_app/models/course.dart';
import 'package:azmoonak_app/models/question.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:http/http.dart' as http;

class ApiService {
  // آدرس سرور شما. اگر از شبیه‌ساز اندروید استفاده می‌کنید، این آدرس درست است.
  // برای شبیه‌ساز iOS یا گوشی واقعی، IP کامپیوتر خود را جایگزین 10.0.2.2 کنید.
  static const String _baseUrl = "http://143.20.64.200/api";
  
   Future<List<Question>> fetchAllQuestionsForCourse(String courseId, String token) async {
        final response = await http.get(
            Uri.parse('$_baseUrl/questions/all/$courseId'),
            headers: {'x-auth-token': token},
        );

        if (response.statusCode == 200) {
            List<dynamic> data = json.decode(response.body);
            return data.map((json) => Question.fromJson(json)).toList();
        } else {
            throw Exception('Failed to load all questions for course $courseId');
        }
    }

    Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'), // <-- یک API جدید در بک‌اند
        headers: {'x-auth-token': token},
    );
    if (response.statusCode == 200) {
        return json.decode(response.body);
    } else {
        throw Exception('Failed to fetch user data');
    }
}
  // تابع برای ثبت‌نام کاربر
  Future<Map<String, dynamic>> register(String name, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'name': name,
          'email': email,
          'password': password,
        }),
      );
      // قبل از decode، چک می‌کنیم که پاسخ موفقیت‌آمیز بوده یا نه
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        // اگر خطا بود، پیام خطا را برمی‌گردانیم
        return {'error': json.decode(response.body)['msg'] ?? 'An unknown error occurred'};
      }
    } catch (e) {
      return {'error': 'Could not connect to the server.'};
    }
  }

  // تابع برای ورود کاربر (این همان متدی است که وجود نداشت)
  Future<Map<String, dynamic>> login(String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
        }),
      );
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
        return {'error': json.decode(response.body)['msg'] ?? 'Invalid credentials'};
      }
    } catch (e) {
      return {'error': 'Could not connect to the server.'};
    }
  }
  
Future<List<Category>> fetchCategories(String token) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/courses/categories'),
    headers: {'x-auth-token': token},
  );
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((json) => Category.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load categories');
  }
}

Future<List<Course>> fetchCoursesByCategory(String categoryId, String token) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/courses/category/$categoryId'),
    headers: {'x-auth-token': token},
  );
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((json) => Course.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load courses for category');
  }
}

Future<List<Question>> fetchRandomQuestions(List<String> courseIds, int limit, String token) async {
  final response = await http.post(
    Uri.parse('$_baseUrl/questions/random'),
    headers: {
      'Content-Type': 'application/json', // <-- بسیار مهم
      'x-auth-token': token,
    },
    body: json.encode({
      'courseIds': courseIds, // <-- باید یک لیست از رشته‌ها باشد
      'limit': limit,       // <-- باید یک عدد باشد
    }),
  );

  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((json) => Question.fromJson(json)).toList();
  } else {
    // برای عیب‌یابی، بدنه پاسخ خطا را چاپ می‌کنیم
    print("Error fetching questions: ${response.statusCode}");
    print("Error body: ${response.body}");
    throw Exception('Failed to fetch random questions');
  }
}
Future<List<QuizAttempt>> fetchQuizHistory(String token) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/quiz-attempts/my-history'),
    headers: {'x-auth-token': token},
  );

  if (response.statusCode == 200) {
    // ۱. ابتدا داده‌ها را به صورت یک لیست داینامیک دریافت می‌کنیم
    List<dynamic> data = json.decode(response.body);
    
    // ۲. سپس با استفاده از map، هر آیتم JSON را به یک آبجکت QuizAttempt تبدیل می‌کنیم
    // و در نهایت یک لیست از نوع QuizAttempt برمی‌گردانیم.
    return data.map((json) => QuizAttempt.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load quiz history');
  }
}
Future<QuizAttempt> submitExam(List<String> courseIds, List<Map<String, dynamic>> answers, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/quiz-attempts/submit'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      // --- تغییر اصلی اینجاست ---
      // ما حالا 'courseIds' (به صورت آرایه) را به جای 'courseId' ارسال می‌کنیم
      body: json.encode({
        'courseIds': courseIds,
        'answers': answers,
      }),
      // ------------------------
    );

    if (response.statusCode == 201) {
      // پاسخ موفقیت‌آمیز بود، آن را به آبجکت QuizAttempt تبدیل کن
      return QuizAttempt.fromJson(json.decode(response.body));
    } else {
      // برای عیب‌یابی بهتر، پاسخ خطا را چاپ می‌کنیم
      print("Submit Exam Error: ${response.statusCode}");
      print("Response Body: ${response.body}");
      throw Exception('Failed to submit exam results');
    }
  }


   Future<Map<String, dynamic>> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/forgotpassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'email': email}),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to the server.'};
    }
  }

  Future<Map<String, dynamic>> resetPassword(String email, String token, String password) async {
    try {
      final response = await http.put(
        Uri.parse('$_baseUrl/auth/resetpassword'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'token': token,
          'password': password,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': 'Could not connect to the server.'};
    }
  }
static Future<List<Question>> fetchTrialQuestions() async {
  final response = await http.get(Uri.parse('$_baseUrl/questions/trial'));
  if (response.statusCode == 200) {
    List<dynamic> data = json.decode(response.body);
    return data.map((json) => Question.fromJson(json)).toList();
  } else {
    throw Exception('Failed to fetch trial questions');
  }
}
Future<Map<String, dynamic>> fetchSettings() async {
    final response = await http.get(Uri.parse('$_baseUrl/settings'));
    if (response.statusCode == 200) {
        return json.decode(response.body);
    } else {
        throw Exception('Failed to load settings');
    }
}
Future<Map<String, dynamic>> updateUserDetails(String name, String token) async {
  final response = await http.put(
    Uri.parse('$_baseUrl/users/updatedetails'),
    headers: {
      'Content-Type': 'application/json',
      'x-auth-token': token,
    },
    body: json.encode({'name': name}),
  );
  return json.decode(response.body);
}

Future<Map<String, dynamic>> updateUserPassword(String oldPassword, String newPassword, String token) async {
  final response = await http.put(
    Uri.parse('$_baseUrl/users/updatepassword'),
    headers: {
      'Content-Type': 'application/json',
      'x-auth-token': token,
    },
    body: json.encode({
      'oldPassword': oldPassword,
      'newPassword': newPassword,
    }),
  );
  return json.decode(response.body);
}
}

