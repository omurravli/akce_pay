import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Backend ekibi için sözleşme (contract) görevini görür.
///
/// === Beklenen endpoint listesi ===
/// POST   /auth/register            -> { token, user }
/// POST   /auth/login                -> { token, user: {id, username, email, role} }
/// GET    /api/wallets               -> [Wallet]
/// PATCH  /api/wallets/load          -> Wallet
/// POST   /api/transactions/send     -> Transaction
///
/// (Yeni) Borsa & Trading
/// GET    /api/market/rates          -> [MarketRate]
/// POST   /api/trade/buy             -> { holding, wallet }   body: {symbol, amountTl}
/// POST   /api/trade/sell            -> { holding, wallet }   body: {symbol, quantity}
///
/// (Yeni) Portföy
/// GET    /api/portfolio/holdings    -> [PortfolioHolding]
///
/// (Yeni) Cashback
/// GET    /api/cashback/balance      -> { balance: number }
/// GET    /api/cashback/entries      -> [CashbackEntry]
/// POST   /api/cashback/withdraw     -> { newBalance } body: {walletId}
///
/// (Yeni) Admin (yalnız role==admin)
/// GET    /api/admin/stats           -> AdminStats
/// GET    /api/admin/users           -> [AdminUserSummary]
/// PATCH  /api/admin/users/:id       -> AdminUserSummary  body: {isActive?, role?}
class ApiService {
  // Backend takımının sunucusunun gerçek IP'si.
  // Üretimde environment değişkenine taşınmalı.
  static const String baseUrl = 'https://akcepay-production.up.railway.app';

  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<String?> getUserJson() async {
    return await _storage.read(key: 'current_user');
  }

  Future<void> saveUserJson(String userJson) async {
    await _storage.write(key: 'current_user', value: userJson);
  }

  Future<String?> getDemoProfileJson() async {
    return await _storage.read(key: 'demo_profile');
  }

  Future<void> saveDemoProfileJson(String value) async {
    await _storage.write(key: 'demo_profile', value: value);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
    await _storage.delete(key: 'current_user');
  }

  Map<String, String> _getHeaders(String? token) {
    final headers = {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (token != null) {
      headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  // ==========================================================================
  // Auth
  // ==========================================================================
  Future<http.Response> register({
    required String username,
    required String email,
    required String password,
    required int age,
    required String telephoneno,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    return await http.post(
      url,
      headers: _getHeaders(null),
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        'age': age,
        'telephoneno': telephoneno,
      }),
    );
  }

  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    return await http.post(
      url,
      headers: _getHeaders(null),
      body: jsonEncode({'email': email, 'password': password}),
    );
  }

  // ==========================================================================
  // Wallets
  // ==========================================================================
  Future<http.Response> getWallets() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/wallets');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> loadBalance({
    required String walletId,
    required double amount,
    String? description,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/wallets/load');
    return await http.patch(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        'wallet_id': walletId,
        'amount': amount,
        'description': description,
      }),
    );
  }

  // ==========================================================================
  // Transactions
  // ==========================================================================
  Future<http.Response> sendMoney({
    required String senderWalletId,
    required String receiverWalletId,
    required double amount,
    required String description,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/transactions/send');
    return await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        'sender_wallet_id': senderWalletId,
        'receiver_wallet_id': receiverWalletId,
        'amount': amount,
        'description': description,
      }),
    );
  }

  Future<http.Response> getTransactions() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/transactions');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> getActivities() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/activities');
    return await http.get(url, headers: _getHeaders(token));
  }

  // ==========================================================================
  // Market (Borsa) – Yeni
  // ==========================================================================
  /// Anlık altın/gümüş/döviz kurları.
  Future<http.Response> getMarketRates() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/market/rates');
    return await http.get(url, headers: _getHeaders(token));
  }

  // ==========================================================================
  // Trading – Yeni
  // ==========================================================================
  /// TL bakiyesinden bir varlık (altın/gümüş/döviz) satın alır.
  /// Body: { "symbol": "GOLD_GR", "amount_tl": 1000.0 }
  Future<http.Response> buyAsset({
    required String symbol,
    required double amountTl,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/trade/buy');
    return await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        'symbol': symbol,
        'amount_tl': amountTl,
      }),
    );
  }

  /// Mevcut bir holding'in bir kısmını satar.
  /// Body: { "symbol": "GOLD_GR", "quantity": 1.5 }
  Future<http.Response> sellAsset({
    required String symbol,
    required double quantity,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/trade/sell');
    return await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        'symbol': symbol,
        'quantity': quantity,
      }),
    );
  }

  // ==========================================================================
  // Portfolio – Yeni
  // ==========================================================================
  Future<http.Response> getHoldings() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/portfolio/holdings');
    return await http.get(url, headers: _getHeaders(token));
  }

  // ==========================================================================
  // Cashback – Yeni
  // ==========================================================================
  Future<http.Response> getCashbackBalance() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/cashback/balance');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> getCashbackEntries() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/cashback/entries');
    return await http.get(url, headers: _getHeaders(token));
  }

  /// Birikmiş cashback bakiyesini bir cüzdana aktarır.
  Future<http.Response> withdrawCashback({required String walletId}) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/cashback/withdraw');
    return await http.post(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({'wallet_id': walletId}),
    );
  }

  // ==========================================================================
  // Admin – Yeni (yalnız role==admin)
  // ==========================================================================
  Future<http.Response> getAdminStats() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/admin/stats');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> searchUsers(String query) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/users/search?q=${Uri.encodeComponent(query)}');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> getAdminUserTransactions(String userId) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/admin/users/$userId/transactions');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> getAdminUsers() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/admin/users');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> updateAdminUser({
    required String userId,
    bool? isActive,
    String? role,
  }) async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/admin/users/$userId');
    return await http.patch(
      url,
      headers: _getHeaders(token),
      body: jsonEncode({
        if (isActive != null) 'is_active': isActive,
        if (role != null) 'role': role,
      }),
    );
  }
}
