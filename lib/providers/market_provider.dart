import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';
import 'auth_provider.dart';

/// Borsa (gold/silver/USD/EUR) anlık kurlarını yönetir.
class MarketProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  AuthProvider? _auth;

  List<MarketRate> _rates = [];
  bool _isLoading = false;
  Timer? _autoRefresh;

  List<MarketRate> get rates => _rates;
  bool get isLoading => _isLoading;
  bool get _demo => _auth?.isDemo == true;

  MarketRate? rateOf(String symbol) {
    for (final r in _rates) {
      if (r.symbol == symbol) return r;
    }
    return null;
  }

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated) {
      fetchRates();
      _autoRefresh?.cancel();
      _autoRefresh = Timer.periodic(
          const Duration(seconds: 30), (_) => fetchRates(silent: true));
    } else {
      _autoRefresh?.cancel();
      _rates = [];
      notifyListeners();
    }
  }

  Future<void> fetchRates({bool silent = false}) async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    if (!silent) {
      _isLoading = true;
      notifyListeners();
    }

    if (_demo) {
      _rates = DemoData.demoMarketRates;
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.getMarketRates();
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _rates = data.map((j) => MarketRate.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Market fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _autoRefresh?.cancel();
    super.dispose();
  }
}
