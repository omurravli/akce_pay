import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../providers/wallet_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import 'success_screen.dart';

class _Contact {
  final String userId;
  final String username;
  final String email;
  final String walletId;
  final String iban;

  _Contact({
    required this.userId,
    required this.username,
    required this.email,
    required this.walletId,
    required this.iban,
  });

  factory _Contact.fromJson(Map<String, dynamic> j) => _Contact(
        userId: j['id']?.toString() ?? '',
        username: j['username'] ?? '',
        email: j['email'] ?? '',
        walletId: j['wallet_id']?.toString() ?? '',
        iban: j['iban'] ?? '',
      );

  Color get avatarColor {
    final colors = [
      const Color(0xFF3B82F6),
      const Color(0xFF8B5CF6),
      const Color(0xFFEC4899),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
      const Color(0xFFEF4444),
    ];
    return colors[username.codeUnitAt(0) % colors.length];
  }

  String get initials {
    final parts = username.trim().split(' ');
    if (parts.length >= 2) return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    return username.isNotEmpty ? username.substring(0, 1).toUpperCase() : '?';
  }
}

// Demo contacts shown when not logged in with a real account
final _demoContacts = [
  _Contact(userId: 'd1', username: 'Emma J.', email: 'emma@demo.com', walletId: 'mock-wallet-emma', iban: 'TR1234'),
  _Contact(userId: 'd2', username: 'Mehmet Y.', email: 'mehmet@demo.com', walletId: 'mock-wallet-mehmet', iban: 'TR5678'),
  _Contact(userId: 'd3', username: 'Ayşe K.', email: 'ayse@demo.com', walletId: 'mock-wallet-ayse', iban: 'TR9012'),
];

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  String _amount = '0';
  _Contact? _selectedContact;
  final _noteController = TextEditingController();
  final _searchController = TextEditingController();

  List<_Contact> _contacts = [];
  bool _isSearching = false;
  bool _initialLoaded = false;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitial());
  }

  @override
  void dispose() {
    _noteController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadInitial() async {
    final isDemo = context.read<AuthProvider>().isDemo;
    if (isDemo) {
      setState(() {
        _contacts = _demoContacts;
        _selectedContact = _demoContacts.first;
        _initialLoaded = true;
      });
      return;
    }
    await _search('');
    setState(() => _initialLoaded = true);
  }

  void _onSearchChanged() {
    final isDemo = context.read<AuthProvider>().isDemo;
    if (isDemo) {
      final q = _searchController.text.toLowerCase();
      setState(() {
        _contacts = _demoContacts
            .where((c) => c.username.toLowerCase().contains(q))
            .toList();
      });
      return;
    }
    _search(_searchController.text);
  }

  Future<void> _search(String q) async {
    setState(() => _isSearching = true);
    try {
      final res = await ApiService().searchUsers(q);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        final contacts = data
            .map((j) => _Contact.fromJson(j))
            .where((c) => c.walletId.isNotEmpty)
            .toList();
        setState(() {
          _contacts = contacts;
          // keep selection if still in list, else deselect
          if (_selectedContact != null &&
              !contacts.any((c) => c.userId == _selectedContact!.userId)) {
            _selectedContact = contacts.isNotEmpty ? contacts.first : null;
          }
          _selectedContact ??= contacts.isNotEmpty ? contacts.first : null;
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isSearching = false);
    }
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        _amount = _amount.length > 1 ? _amount.substring(0, _amount.length - 1) : '0';
      } else if (key == '.' && _amount.contains('.')) {
        return;
      } else if (_amount == '0' && key != '.') {
        _amount = key;
      } else if (_amount.length < 10) {
        _amount += key;
      }
    });
  }

  Future<void> _handleSendMoney() async {
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.wallets.isEmpty || _selectedContact == null) return;

    final amount = double.tryParse(_amount) ?? 0;
    if (amount <= 0) return;

    final senderWalletId = walletProvider.wallets.first.walletId;
    final description = _noteController.text.isEmpty ? 'Transfer' : _noteController.text;

    final success = await walletProvider.sendMoney(
      senderWalletId: senderWalletId,
      receiverWalletId: _selectedContact!.walletId,
      amount: amount,
      description: description,
    );

    if (mounted) {
      if (success) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => SuccessScreen(
              amount: '₺$_amount',
              recipient: _selectedContact!.username,
              isSend: true,
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.transferFailed)),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final balance = context.watch<WalletProvider>().wallets.isNotEmpty
        ? context.watch<WalletProvider>().wallets.first.balance
        : 0.0;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(l.sendMoney,
            style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.slate300 : AppColors.slate700, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1, color: isDark ? AppColors.slate700 : AppColors.slate100),
        ),
      ),
      body: Column(
        children: [
          _buildContactsSection(l, isDark),
          _buildAmountDisplay(l, isDark, balance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: l.addNote,
                prefixIcon: const Icon(Icons.edit_note_rounded, color: AppColors.slate400),
                filled: true,
                fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(child: _buildNumpad(isDark)),
          _buildSendButton(l, isDark),
        ],
      ),
    );
  }

  Widget _buildContactsSection(AppLocalizations l, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'İsim, e-posta veya IBAN ara...',
              hintStyle: const TextStyle(fontSize: 13),
              prefixIcon: _isSearching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2)))
                  : const Icon(Icons.search_rounded, size: 20),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded, size: 18),
                      onPressed: () => _searchController.clear())
                  : null,
              filled: true,
              fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
              border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              isDense: true,
            ),
          ),
        ),
        if (!_initialLoaded)
          const SizedBox(
            height: 80,
            child: Center(child: CircularProgressIndicator()),
          )
        else if (_contacts.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Center(
              child: Text(
                _searchController.text.isEmpty
                    ? 'Henüz başka kullanıcı yok'
                    : 'Kullanıcı bulunamadı',
                style: const TextStyle(color: AppColors.slate400, fontSize: 13),
              ),
            ),
          )
        else
          SizedBox(
            height: 84,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: _contacts.length,
              itemBuilder: (context, i) {
                final c = _contacts[i];
                final isSelected = _selectedContact?.userId == c.userId;
                return Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => setState(() => _selectedContact = c),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 50,
                          height: 50,
                          decoration: BoxDecoration(
                            color: c.avatarColor,
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: AppColors.primary, width: 2.5)
                                : null,
                          ),
                          child: Center(
                            child: Text(c.initials,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        SizedBox(
                          width: 56,
                          child: Text(
                            c.username.split(' ').first,
                            textAlign: TextAlign.center,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                color: isSelected
                                    ? AppColors.primary
                                    : (isDark ? AppColors.slate300 : AppColors.slate700)),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildAmountDisplay(AppLocalizations l, bool isDark, double balance) {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 4, 24, 0),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800.withValues(alpha: 0.5) : AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        children: [
          if (_selectedContact != null)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                '→ ${_selectedContact!.username}',
                style: const TextStyle(color: AppColors.slate400, fontSize: 12),
              ),
            ),
          Text(l.enterAmount, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
          const SizedBox(height: 6),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('₺', style: TextStyle(fontSize: 28, color: AppColors.primary)),
              const SizedBox(width: 4),
              Text(_amount,
                  style: const TextStyle(
                      fontSize: 52, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 8),
          Text('${l.balance}: ₺${balance.toStringAsFixed(2)}',
              style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.slate600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNumpad(bool isDark) {
    final keys = ['1', '2', '3', '4', '5', '6', '7', '8', '9', '.', '0', '⌫'];
    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 32),
      childAspectRatio: 2.2,
      physics: const NeverScrollableScrollPhysics(),
      children: keys.map((k) => GestureDetector(
        onTap: () => _onKeyPress(k),
        child: Center(
          child: k == '⌫'
              ? Icon(Icons.backspace_outlined,
                  color: isDark ? Colors.white70 : Colors.black54)
              : Text(k,
                  style: TextStyle(
                      fontSize: 24,
                      color: isDark ? Colors.white : Colors.black87)),
        ),
      )).toList(),
    );
  }

  Widget _buildSendButton(AppLocalizations l, bool isDark) {
    final amt = double.tryParse(_amount) ?? 0;
    final isLoading = context.watch<WalletProvider>().isLoading;
    final canSend = amt > 0 && !isLoading && _selectedContact != null;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: canSend ? _handleSendMoney : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: isLoading
              ? const CircularProgressIndicator(color: Colors.white)
              : Text('${l.sendButton} ₺$_amount',
                  style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
