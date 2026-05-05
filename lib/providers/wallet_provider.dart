import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/wallet.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';
import 'auth_provider.dart';

class WalletProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  AuthProvider? _authProvider;
  List<Wallet> _wallets = [];
  bool _isLoading = false;

  List<Wallet> get wallets => _wallets;
  bool get isLoading => _isLoading;
  bool get _demo => _authProvider?.isDemo == true;

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

    if (_demo) {
      _wallets = List<Wallet>.from(DemoData.demoWallets);
      _isLoading = false;
      notifyListeners();
      return;
    }

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

    if (_demo) {
      final idx = _wallets.indexWhere((w) => w.walletId == walletId);
      if (idx != -1) {
        final wallet = _wallets[idx];
        _wallets[idx] = Wallet(
          walletId: wallet.walletId,
          ownerId: wallet.ownerId,
          iban: wallet.iban,
          walletType: wallet.walletType,
          balance: wallet.balance + amount,
        );
        DemoData.setDemoWallets(_wallets);
        DemoData.addDemoActivity(
          DemoActivityEntry(
            type: 'load_balance',
            amount: amount,
            isCredit: true,
            createdAt: DateTime.now(),
            note: description,
          ),
        );
      }
      _isLoading = false;
      notifyListeners();
      return true;
    }

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

    if (_demo) {
      final idx = _wallets.indexWhere((w) => w.walletId == senderWalletId);
      if (idx == -1) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final wallet = _wallets[idx];
      if (wallet.balance < amount) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      _wallets[idx] = Wallet(
        walletId: wallet.walletId,
        ownerId: wallet.ownerId,
        iban: wallet.iban,
        walletType: wallet.walletType,
        balance: wallet.balance - amount,
      );
      DemoData.setDemoWallets(_wallets);
      DemoData.addDemoActivity(
        DemoActivityEntry(
          type: 'send_money',
          amount: amount,
          isCredit: false,
          createdAt: DateTime.now(),
          note: description,
        ),
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

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

  void adjustTlBalance(double delta) {
    final idx = _wallets.indexWhere((w) => w.walletType == 'TL');
    if (idx == -1) return;
    final wallet = _wallets[idx];
    _wallets[idx] = Wallet(
      walletId: wallet.walletId,
      ownerId: wallet.ownerId,
      iban: wallet.iban,
      walletType: wallet.walletType,
      balance: wallet.balance + delta,
    );
    DemoData.setDemoWallets(_wallets);
    notifyListeners();
  }
}
