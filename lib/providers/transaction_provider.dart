import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/app_transaction.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';
import 'auth_provider.dart';

class TransactionProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  AuthProvider? _auth;
  List<AppTransaction> _transactions = [];
  bool _isLoading = false;

  List<AppTransaction> get transactions => _transactions;
  bool get isLoading => _isLoading;
  bool get _demo => _auth?.isDemo == true;

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated) {
      fetchTransactions();
    } else {
      _transactions = [];
      notifyListeners();
    }
  }

  Future<void> fetchTransactions() async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    _isLoading = true;
    notifyListeners();

    if (_demo) {
      _transactions = DemoData.demoActivities
          .where((e) => e.type == 'send_money' || e.type == 'load_balance')
          .map((e) => AppTransaction(
                transactionId: e.createdAt.millisecondsSinceEpoch.toString(),
                senderId: e.isCredit ? null : 'local-demo-user',
                receiverId: e.isCredit ? 'local-demo-user' : null,
                amount: e.amount,
                description: e.note,
                type: e.type == 'send_money' ? 'TRANSFER' : 'DEPOSIT',
                status: 'SUCCESS',
                date: e.createdAt,
              ))
          .toList();
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.getTransactions();
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as List;
        _transactions = data.map((j) => AppTransaction.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Error fetching transactions: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
