import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';
import 'auth_provider.dart';
import 'wallet_provider.dart';

/// Cashback bakiyesi ve geçmiş kayıtlarını yönetir.
/// Backend `/api/cashback/*` endpoint'lerine bağlanır.
class CashbackProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  AuthProvider? _auth;
  WalletProvider? _walletProvider;

  double _balance = 0;
  List<CashbackEntry> _entries = [];
  bool _isLoading = false;

  double get balance => _balance;
  List<CashbackEntry> get entries => _entries;
  bool get isLoading => _isLoading;
  bool get _demo => _auth?.isDemo == true;

  /// Kategori bazlı ortalama oranlar (ör. UI'da "%3 alışveriş, %1 fatura" göstermek için).
  Map<String, double> get rateByCategory => const {
        'shopping': 0.03,
        'bills': 0.01,
        'transfer': 0.005,
        'trade': 0.005,
      };

  void updateDeps(AuthProvider auth, WalletProvider wallet) {
    _auth = auth;
    _walletProvider = wallet;
    if (auth.isAuthenticated) {
      fetch();
    } else {
      _balance = 0;
      _entries = [];
      notifyListeners();
    }
  }

  Future<void> fetch() async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    _isLoading = true;
    notifyListeners();

    if (_demo) {
      _entries = List<CashbackEntry>.from(DemoData.demoCashbackEntries);
      _balance = DemoData.demoCashbackBalance;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final balRes = await _api.getCashbackBalance();
      if (balRes.statusCode == 200) {
        final data = jsonDecode(balRes.body);
        _balance = (data['balance'] as num?)?.toDouble() ?? 0;
      }
      final entRes = await _api.getCashbackEntries();
      if (entRes.statusCode == 200) {
        final List<dynamic> data = jsonDecode(entRes.body);
        _entries = data.map((j) => CashbackEntry.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Cashback fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Birikmiş cashback'i ana TL cüzdanına aktarır.
  Future<bool> withdrawToTlWallet() async {
    if (_balance <= 0) return false;
    _isLoading = true;
    notifyListeners();

    final tl = _walletProvider?.wallets
        .where((w) => w.walletType == 'TL')
        .toList();
    if (tl == null || tl.isEmpty) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
    final walletId = tl.first.walletId;

    try {
      final res = await _api.withdrawCashback(walletId: walletId);
      if (res.statusCode == 200) {
        await fetch();
        await _walletProvider?.fetchWallets();
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
