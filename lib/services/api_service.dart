import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class ApiService {
  // Use your computer's local IP (e.g., 192.168.1.x) for real device testing
  // 10.0.2.2 is the special alias for your host loopback interface in Android Emulator
  static const String baseUrl = 'http://10.0.2.2:3000'; 
  
  final _storage = const FlutterSecureStorage();

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwt_token');
  }

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwt_token', value: token);
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwt_token');
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

  // Auth Endpoints
  Future<http.Response> register({
    required String username,
    required String email,
    required String password,
    required int age,
    required String telephoneno,
  }) async {
    final url = Uri.parse('$baseUrl/auth/register');
    final response = await http.post(
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
    return response;
  }

  Future<http.Response> login(String email, String password) async {
    final url = Uri.parse('$baseUrl/auth/login');
    final response = await http.post(
      url,
      headers: _getHeaders(null),
      body: jsonEncode({
        'email': email,
        'password': password,
      }),
    );
    return response;
  }

  // Wallet Endpoints
  Future<http.Response> getWallets() async {
    final token = await getToken();
    final url = Uri.parse('$baseUrl/api/wallets');
    return await http.get(url, headers: _getHeaders(token));
  }

  Future<http.Response> loadBalance({
    required int walletId,
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

  // Transaction Endpoints
  Future<http.Response> sendMoney({
    required int senderWalletId,
    required int receiverWalletId,
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
}
