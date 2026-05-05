import 'dart:convert';
import 'package:flutter/material.dart';
import '../models/asset.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';
import 'auth_provider.dart';
import 'market_provider.dart';
import 'wallet_provider.dart';

/// Kullanıcının portföyü (altın, gümüş, döviz holdings'leri) ve
/// al/sat işlemleri için provider.
class PortfolioProvider with ChangeNotifier {
  final ApiService _api = ApiService();
  AuthProvider? _auth;
  WalletProvider? _walletProvider;
  MarketProvider? _marketProvider;

  List<PortfolioHolding> _holdings = [];
  bool _isLoading = false;
  String? _sessionKey;

  List<PortfolioHolding> get holdings => _holdings;
  bool get isLoading => _isLoading;
  bool get _demo => _auth?.isDemo == true;

  double get totalMarketValue =>
      _holdings.fold<double>(0, (s, h) => s + h.marketValue);
  double get totalCostBasis =>
      _holdings.fold<double>(0, (s, h) => s + h.costBasis);
  double get totalProfitLoss => totalMarketValue - totalCostBasis;
  double get totalProfitLossPercent => totalCostBasis == 0
      ? 0
      : (totalProfitLoss / totalCostBasis) * 100;

  void updateDeps(
      AuthProvider auth, WalletProvider wallet, MarketProvider market) {
    final nextSessionKey =
        auth.isAuthenticated ? '${auth.token}:${auth.isDemo}' : null;
    final shouldRefreshSession = nextSessionKey != _sessionKey;

    _auth = auth;
    _walletProvider = wallet;
    _marketProvider = market;
    if (auth.isAuthenticated) {
      _sessionKey = nextSessionKey;
      if (shouldRefreshSession) {
        fetchHoldings();
      }
    } else {
      _sessionKey = null;
      if (_holdings.isNotEmpty) {
        _holdings = [];
        notifyListeners();
      }
    }
  }

  Future<void> fetchHoldings() async {
    if (_auth == null || !_auth!.isAuthenticated) return;
    _isLoading = true;
    notifyListeners();

    if (_demo) {
      _holdings = List<PortfolioHolding>.from(DemoData.demoHoldings);
      _isLoading = false;
      notifyListeners();
      return;
    }

    try {
      final res = await _api.getHoldings();
      if (res.statusCode == 200) {
        final List<dynamic> data = jsonDecode(res.body);
        _holdings = data.map((j) => PortfolioHolding.fromJson(j)).toList();
      }
    } catch (e) {
      debugPrint('Holdings fetch error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// TL bakiyesinden alış. amountTl kadar TL düşer, karşılığında miktar artar.
  Future<bool> buyAsset({
    required String symbol,
    required double amountTl,
  }) async {
    if (amountTl <= 0) return false;
    _isLoading = true;
    notifyListeners();

    if (_demo) {
      final tlWallet = _walletProvider?.wallets
          .where((w) => w.walletType == 'TL')
          .toList();
      final rate = _marketProvider?.rateOf(symbol);
      if (tlWallet == null ||
          tlWallet.isEmpty ||
          rate == null ||
          tlWallet.first.balance < amountTl) {
        _isLoading = false;
        notifyListeners();
        return false;
      }

      final quantity = amountTl / rate.sellPrice;
      final idx = _holdings.indexWhere((h) => h.symbol == symbol);
      if (idx == -1) {
        _holdings.add(
          PortfolioHolding(
            symbol: symbol,
            name: rate.name,
            quantity: quantity,
            averageCost: rate.sellPrice,
            currentPrice: rate.midPrice,
          ),
        );
      } else {
        final holding = _holdings[idx];
        final newQuantity = holding.quantity + quantity;
        final newAverageCost =
            ((holding.quantity * holding.averageCost) +
                    (quantity * rate.sellPrice)) /
                newQuantity;
        _holdings[idx] = PortfolioHolding(
          symbol: holding.symbol,
          name: holding.name,
          quantity: newQuantity,
          averageCost: newAverageCost,
          currentPrice: rate.midPrice,
        );
      }
      DemoData.setDemoHoldings(_holdings);
      DemoData.addDemoActivity(
        DemoActivityEntry(
          type: 'buy_asset',
          amount: amountTl,
          isCredit: false,
          createdAt: DateTime.now(),
          assetSymbol: symbol,
        ),
      );
      _walletProvider?.adjustTlBalance(-amountTl);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final res = await _api.buyAsset(symbol: symbol, amountTl: amountTl);
      if (res.statusCode == 200) {
        await fetchHoldings();
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

  /// Belirli miktarda holding'i sat, karşılığı TL bakiyesine yatar.
  Future<bool> sellAsset({
    required String symbol,
    required double quantity,
  }) async {
    if (quantity <= 0) return false;
    _isLoading = true;
    notifyListeners();

    if (_demo) {
      final idx = _holdings.indexWhere((h) => h.symbol == symbol);
      final rate = _marketProvider?.rateOf(symbol);
      if (idx == -1 || rate == null || _holdings[idx].quantity < quantity) {
        _isLoading = false;
        notifyListeners();
        return false;
      }
      final holding = _holdings[idx];
      final newQuantity = holding.quantity - quantity;
      if (newQuantity <= 0) {
        _holdings.removeAt(idx);
      } else {
        _holdings[idx] = PortfolioHolding(
          symbol: holding.symbol,
          name: holding.name,
          quantity: newQuantity,
          averageCost: holding.averageCost,
          currentPrice: rate.midPrice,
        );
      }
      DemoData.setDemoHoldings(_holdings);
      DemoData.addDemoActivity(
        DemoActivityEntry(
          type: 'sell_asset',
          amount: quantity * rate.buyPrice,
          isCredit: true,
          createdAt: DateTime.now(),
          assetSymbol: symbol,
        ),
      );
      _walletProvider?.adjustTlBalance(quantity * rate.buyPrice);
      _isLoading = false;
      notifyListeners();
      return true;
    }

    try {
      final res = await _api.sellAsset(symbol: symbol, quantity: quantity);
      if (res.statusCode == 200) {
        await fetchHoldings();
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
