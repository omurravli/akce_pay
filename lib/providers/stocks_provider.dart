import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import 'auth_provider.dart';

class StockSearchResult {
  final String symbol;
  final String name;
  StockSearchResult({required this.symbol, required this.name});
  factory StockSearchResult.fromJson(Map<String, dynamic> j) =>
      StockSearchResult(symbol: j['symbol'] ?? '', name: j['name'] ?? '');
}

class StocksProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  AuthProvider? _auth;

  List<MarketRate> _popular = [];
  List<MarketRate> _tracked = [];
  Set<String> _trackedSymbols = {};
  List<StockSearchResult> _searchResults = [];
  bool _isLoading = false;
  bool _isSearching = false;
  Timer? _pollTimer;

  List<MarketRate> get popular => _popular;
  List<MarketRate> get tracked => _tracked;
  Set<String> get trackedSymbols => _trackedSymbols;
  List<StockSearchResult> get searchResults => _searchResults;
  bool get isLoading => _isLoading;
  bool get isSearching => _isSearching;

  bool isTracked(String symbol) => _trackedSymbols.contains(symbol);

  void updateAuth(AuthProvider auth) {
    _auth = auth;
    if (auth.isAuthenticated && !auth.isDemo) {
      fetchAll();
      _pollTimer?.cancel();
      _pollTimer = Timer.periodic(
        const Duration(minutes: 5),
        (_) => fetchAll(silent: true),
      );
    } else {
      _pollTimer?.cancel();
      _popular = [];
      _tracked = [];
      _trackedSymbols = {};
      notifyListeners();
    }
  }

  Future<void> fetchAll({bool silent = false}) async {
    if (_auth?.isAuthenticated != true || _auth?.isDemo == true) return;
    if (!silent) { _isLoading = true; notifyListeners(); }
    await Future.wait([_fetchPopular(), _fetchTracked()]);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> _fetchPopular() async {
    try {
      final res = await _api.getPopularStocks();
      if (res.statusCode == 200) {
        _popular = (jsonDecode(res.body) as List).map((j) => MarketRate.fromJson(j)).toList();
      }
    } catch (_) {}
  }

  Future<void> _fetchTracked() async {
    try {
      final res = await _api.getTrackedStocks();
      if (res.statusCode == 200) {
        _tracked = (jsonDecode(res.body) as List).map((j) => MarketRate.fromJson(j)).toList();
        _trackedSymbols = _tracked.map((r) => r.symbol).toSet();
      }
    } catch (_) {}
  }

  Future<bool> trackStock(String symbol, String name) async {
    try {
      final res = await _api.trackStock(symbol: symbol, name: name);
      if (res.statusCode == 200) {
        await _fetchTracked();
        // ensure symbol is marked even if the fetch returned no price data yet
        _trackedSymbols.add(symbol);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<bool> untrackStock(String symbol) async {
    try {
      final res = await _api.untrackStock(symbol);
      if (res.statusCode == 200) {
        _trackedSymbols.remove(symbol);
        _tracked.removeWhere((r) => r.symbol == symbol);
        notifyListeners();
        return true;
      }
    } catch (_) {}
    return false;
  }

  Future<void> searchStocks(String query) async {
    if (query.length < 2) {
      _searchResults = [];
      notifyListeners();
      return;
    }
    _isSearching = true;
    notifyListeners();
    try {
      final res = await _api.searchBistStocks(query);
      if (res.statusCode == 200) {
        _searchResults = (jsonDecode(res.body) as List)
            .map((j) => StockSearchResult.fromJson(j))
            .toList();
      }
    } catch (_) {}
    _isSearching = false;
    notifyListeners();
  }

  void clearSearch() {
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }
}
