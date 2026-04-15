import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;
  List<Wallet> _wallets = [];
  bool _isLoading = false;

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;

  void updateAuth(AuthProvider auth) {
    _authProvider = auth;
    if (auth.isAuthenticated) {
      fetchWallets();
    } else {
      _wallets = [];
      notifyListeners();
    }
  }

  Future<void> fetchWallets() async {
    if (_authProvider == null || !_authProvider!.isAuthenticated) return;

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.getWallets();
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        _wallets = data.map((json) => Wallet.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching wallets: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> loadBalance({
    required int walletId,
    required double amount,
    String? description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.loadBalance(
        walletId: walletId,
        amount: amount,
        description: description,
      );
      if (response.statusCode == 200) {
        await fetchWallets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> sendMoney({
    required int senderWalletId,
    required int receiverWalletId,
    required double amount,
    required String description,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final response = await _apiService.sendMoney(
        senderWalletId: senderWalletId,
        receiverWalletId: receiverWalletId,
        amount: amount,
        description: description,
      );
      if (response.statusCode == 200) {
        await fetchWallets();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
