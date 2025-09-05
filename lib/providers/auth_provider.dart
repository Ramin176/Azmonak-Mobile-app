import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import '../models/user.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  String? _token;
  AppUser? _user;

  bool get isAuthenticated => _token != null && _user != null;
  String? get token => _token;
  AppUser? get user => _user;
  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Future<bool> _handleAuthResponse(Map<String, dynamic> response) async {
    _errorMessage = null;
    if (response.containsKey('token') && response.containsKey('user')) {
      _token = response['token'];
      _user = AppUser.fromJson(response['user']);
      
      await _storage.write(key: 'token', value: _token);
      final userBox = await Hive.openBox<AppUser>('userBox');
      await userBox.put('currentUser', _user!);
      
      notifyListeners();
      return true;
    } else {
      _errorMessage = response['msg'] ?? response['error'] ?? 'An unknown error occurred';
      notifyListeners();
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      final response = await _apiService.login(email, password);
      return await _handleAuthResponse(response);
    } catch (e) {
      _errorMessage = 'Could not connect to the server.';
      notifyListeners();
      return false;
    }
  }
  
  Future<bool> register(String name, String email, String password) async {
    try {
      final response = await _apiService.register(name, email, password);
      return await _handleAuthResponse(response);
    } catch (e) {
      _errorMessage = 'Could not connect to the server.';
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    await _storage.delete(key: 'token');
    final userBox = await Hive.openBox<AppUser>('userBox');
    await userBox.clear();
    notifyListeners();
  }
Future<void> updateProfileImage(String path) async {
    if (_user == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('profile_image_path_${_user!.id}', path);
    _user = _user!.copyWith(profileImagePath: path);
    notifyListeners(); // به همه ویجت‌ها اطلاع بده که عکس عوض شده
  }
  Future<bool> tryAutoLogin() async {
    try {
      final token = await _storage.read(key: 'token');
      final userBox = await Hive.openBox<AppUser>('userBox');
      final user = userBox.get('currentUser');
      if (token != null && user != null && user.id.isNotEmpty) {
         final prefs = await SharedPreferences.getInstance();
      final imagePath = prefs.getString('profile_image_path_${user.id}'); 
      _user = user.copyWith(profileImagePath: imagePath);
        _token = token;
        _user = user;
        notifyListeners();
        // رفرش در پس‌زمینه برای گرفتن آخرین وضعیت اشتراک
        refreshUser(); 
        return true;
      }
      await logout();
      return false;
    } catch (e) {
      await logout();
      return false;
    }
  }
  
  Future<void> refreshUser() async {
    if (_token == null) return;
    try {
      final userData = await _apiService.fetchCurrentUser(_token!);
      _user = AppUser.fromJson(userData);
       final prefs = await SharedPreferences.getInstance();
    final imagePath = prefs.getString('profile_image_path_${_user!.id}');
      final userBox = await Hive.openBox<AppUser>('userBox');
      await userBox.put('currentUser', _user!);
      notifyListeners();
    } catch (e) {
      print("Failed to refresh user: $e");
    }
  }
}