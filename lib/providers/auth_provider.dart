import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  User? _user;
  String? _token;
  bool _isLoading = false;

  User? get user => _user;
  String? get token => _token;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null && _user != null;
  bool get isDemo => _token == DemoData.demoToken;

  bool _adminUnlocked = false;
  bool get isAdmin => _adminUnlocked;

  bool tryUnlockAdmin(String pin) {
    if (pin == 'akce2025') {
      _adminUnlocked = true;
      notifyListeners();
      return true;
    }
    return false;
  }

  void lockAdmin() {
    _adminUnlocked = false;
    notifyListeners();
  }

  AuthProvider() {
    _loadToken();
  }

  Future<void> _loadToken() async {
    _token = await _apiService.getToken();
    if (_token == DemoData.demoToken) {
      _user = DemoData.demoUser;
    } else {
      final userJson = await _apiService.getUserJson();
      if (userJson != null) {
        _user = User.fromJson(jsonDecode(userJson));
      } else if (_token != null) {
        _token = null;
        await _apiService.deleteToken();
      }
    }
    if (_token != null && _user == null) {
      _token = null;
      await _apiService.deleteToken();
    }
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    final emailLower = email.trim().toLowerCase();
    try {
      return await _loginWithCredentials(emailLower, password);
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loginWithDemoAccount() async {
    _isLoading = true;
    notifyListeners();

    try {
      DemoData.reset();
      _token = DemoData.demoToken;
      _user = DemoData.demoUser;
      await _apiService.saveToken(_token!);
      await _apiService.saveUserJson(jsonEncode(_user!.toJson()));
      return true;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> _loginWithCredentials(String email, String password) async {
    final response = await _apiService.login(email, password);
    if (response.statusCode != 200) return false;

    final data = jsonDecode(response.body);
    _token = data['token'];
    _user = User.fromJson(data['user']);
    await _apiService.saveToken(_token!);
    await _apiService.saveUserJson(jsonEncode(_user!.toJson()));
    return true;
  }

  Future<bool> register({
    required String username,
    required String email,
    required String password,
    required int age,
    required String telephoneno,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.register(
        username: username,
        email: email,
        password: password,
        age: age,
        telephoneno: telephoneno,
      );
      if (response.statusCode == 201) {
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> logout() async {
    _token = null;
    _user = null;
    _adminUnlocked = false;
    DemoData.reset();
    await _apiService.deleteToken();
    notifyListeners();
  }
}
