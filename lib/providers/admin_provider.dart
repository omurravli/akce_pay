import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

/// Admin panel verilerini sağlar (yalnızca role==admin kullanıcılar için).
class AdminProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  AuthProvider? _auth;

  AdminStats? _stats;
  List<AdminUserSummary> _users = [];
  bool _isLoading = false;

  AdminStats? get stats => _stats;
  List<AdminUserSummary> get users => _users;
  bool get isLoading => _isLoading;
  bool get _demo => _auth?.isDemo == true;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated && auth.isAdmin) {
      fetch();
    } else {
      _stats = null;
      _users = [];
      notifyListeners();
    }
  }

  Future<void> fetch() async {
    if (_auth == null || !_auth!.isAuthenticated || !_auth!.isAdmin) return;
    _isLoading = true;
    notifyListeners();

    if (_demo) {
      _stats = null;
      _users = const [];
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final s = await _api.getAdminStats();
      if (s.statusCode == 200) {
        _stats = AdminStats.fromJson(jsonDecode(s.body));
      }
      final u = await _api.getAdminUsers();
      if (u.statusCode == 200) {
        final List<dynamic> data = jsonDecode(u.body);
        _users = data.map((j) => AdminUserSummary.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Admin fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> toggleUserActive(String userId, bool isActive) async {
    try {
      final res =
          await _api.updateAdminUser(userId: userId, isActive: isActive);
      if (res.statusCode == 200) {
        await fetch();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
}
