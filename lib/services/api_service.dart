import 'dart:convert';
import 'package:azmoonak_app/helpers/api_exceptions.dart';
import 'package:azmoonak_app/models/question.dart';
import 'package:azmoonak_app/models/quiz_attempt.dart';
import 'package:azmoonak_app/models/subject.dart';
import 'package:http/http.dart' as http;
class ApiService {
 
  // برای شبیه‌ساز iOS یا گوشی واقعی، IP کامپیوتر خود را جایگزین 10.0.2.2 کنید.
  static const String _baseUrl = "http://143.20.64.200/api";

   static String get baseUrl => _baseUrl;
  Future<List<Question>> fetchAllQuestionsForSubject(String subjectId, String token) async {
  final response = await http.get(
      Uri.parse('$_baseUrl/questions/all/$subjectId'),
      headers: {'x-auth-token': token},
  );
  final responseBody = json.decode(response.body);
    if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => Question.fromJson(json)).toList();
    } else {
        final responseBody = json.decode(response.body);
        throw ApiException(responseBody['msg'] ?? 'Failed to load questions', code: responseBody['code']);
    }
}
    Future<Map<String, dynamic>> fetchCurrentUser(String token) async {
    final response = await http.get(
        Uri.parse('$_baseUrl/auth/me'),
        headers: {'x-auth-token': token},
    );
      final responseBody = json.decode(response.body);
    if (response.statusCode == 200) {
        return json.decode(response.body);
    } else {
         throw ApiException(responseBody['msg'] ?? 'Failed to fetch user data', code: responseBody['code']);
    }
}
  
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
     
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return json.decode(response.body);
      } else {
       
        return {'error': json.decode(response.body)['msg'] ?? 'An unknown error occurred'};
      }
    } catch (e) {
      return {'error': 'Could not connect to the server.'};
    }
  }


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
  
  // Future<List<Subject>> fetchSubjectTree() async {
  //   final response = await http.get(Uri.parse('$_baseUrl/subjects/tree'));
  //   if (response.statusCode == 200) {
  //     List<dynamic> data = json.decode(response.body);
  //     return data.map((json) => Subject.fromJson(json)).toList();
  //   } else {
  //     throw Exception('Failed to load subject tree');
  //   }
  // }
Future<List<Subject>> fetchSubjectTree() async {
  print('ApiService: Sending request to fetch subject tree...');
  try {
    final response = await http.get(Uri.parse('$_baseUrl/subjects/tree'));
    
    print('ApiService: fetchSubjectTree response status code: ${response.statusCode}');
        print('ApiService: RAW SUBJECT TREE JSON RECEIVED:\n${response.body}');

    if (response.statusCode == 200) {
      print('ApiService: Subject tree fetched successfully.');
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Subject.fromJson(json)).toList();
    } else {
      print('ApiService: Failed to load subject tree. Body: ${response.body}');
      throw Exception('Failed to load subject tree');
    }
  } catch (e) {
    print('ApiService: Network error while fetching subject tree: $e');
    rethrow;
  }
}

Future<List<Question>> fetchRandomQuestions(List<String> subjectIds, int limit, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/questions/random'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: json.encode({
        'subjectIds': subjectIds, 
        'limit': limit,
      }),
    );
    if (response.statusCode == 200) {
      List<dynamic> data = json.decode(response.body);
      return data.map((json) => Question.fromJson(json)).toList();
    } else {
      print("Error fetching questions: ${response.statusCode} - ${response.body}");
      throw Exception('Failed to fetch random questions');
    }
  }
Future<List<QuizAttempt>> fetchQuizHistory(String token) async {
  final response = await http.get(
    Uri.parse('$_baseUrl/quiz-attempts/my-history'),
    headers: {'x-auth-token': token},
  );

  if (response.statusCode == 200) {
    
    List<dynamic> data = json.decode(response.body);
    
    
    return data.map((json) => QuizAttempt.fromJson(json)).toList();
  } else {
    throw Exception('Failed to load quiz history');
  }
}
 Future<QuizAttempt> submitExam(List<String> subjectIds, List<Map<String, dynamic>> answers, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/quiz-attempts/submit'),
      headers: {
        'Content-Type': 'application/json',
        'x-auth-token': token,
      },
      body: json.encode({
        'subjectIds': subjectIds,
        'answers': answers,
      }),
    );
    if (response.statusCode == 201) {
      return QuizAttempt.fromJson(json.decode(response.body));
    } else {
      throw Exception('Failed to submit exam results');
    }
  }
// Future<Map<String, dynamic>> purchaseSubject(String subjectId, String duration, String token) async {
//     final response = await http.post(
//       Uri.parse('$_baseUrl/purchase/subject'),
//       headers: {
//         'Content-Type': 'application/json',
//         'x-auth-token': token,
//       },
//       body: json.encode({
//         'subjectId': subjectId,
//         'duration': duration,
//       }),
//     );
//      if (response.statusCode >= 200 && response.statusCode < 300) {
//         return json.decode(response.body);
//       } else {
//         throw Exception(json.decode(response.body)['msg'] ?? 'Failed to purchase subject');
//       }
//   }

Future<Map<String, dynamic>> createSubjectOrder({
  required String subjectId,
  required String planKey,
  required String planDuration,
  required String planPrice,
  required String token,
}) async {
  
  final response = await http.post(
    Uri.parse('$_baseUrl/orders/subject'), // <-- آدرس API جدید
    headers: {
      'Content-Type': 'application/json',
      'x-auth-token': token,
    },
    body: json.encode({
      'subjectId': subjectId,
      'planKey': planKey,
      'planDuration': planDuration,
      'planPrice': planPrice,
    }),
  );

  final responseBody = json.decode(response.body);

  if (response.statusCode >= 200 && response.statusCode < 300) {
    return responseBody;
  } else {
    throw Exception(responseBody['msg'] ?? 'Failed to create order');
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
// Future<Map<String, dynamic>> fetchSettings() async {
//     final response = await http.get(Uri.parse('$_baseUrl/settings'));
//     if (response.statusCode == 200) {
//         return json.decode(response.body);
//     } else {
//         throw Exception('Failed to load settings');
//     }
// }
Future<Map<String, dynamic>> fetchSettings() async {
  print('ApiService: Sending request to fetch settings...');
  try {
    final response = await http.get(Uri.parse('$_baseUrl/settings'));

    print('ApiService: fetchSettings response status code: ${response.statusCode}');
    
    if (response.statusCode == 200) {
      print('ApiService: Settings fetched successfully.');
      return json.decode(response.body);
    } else {
      // اگر کد وضعیت خطا بود، متن کامل خطا را چاپ کن
      print('ApiService: Failed to load settings. Body: ${response.body}');
      throw Exception('Failed to load settings');
    }
  } catch (e) {
    // اگر خطای شبکه رخ داد (مثلاً اتصال قطع شد)، آن را چاپ کن
    print('ApiService: Network error while fetching settings: $e');
    rethrow; // خطا را دوباره پرتاب کن تا لایه بالایی آن را مدیریت کند
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

