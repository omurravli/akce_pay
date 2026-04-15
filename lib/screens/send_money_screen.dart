import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../providers/wallet_provider.dart';
import 'success_screen.dart';

class MockContact {
  final String name;
  final String initials;
  final Color avatarColor;
  final int walletId;

  MockContact({required this.name, required this.initials, required this.avatarColor, required this.walletId});
}

final mockContacts = [
  MockContact(name: 'Emma', initials: 'EJ', avatarColor: const Color(0xFFEC4899), walletId: 2),
  MockContact(name: 'Michael', initials: 'MS', avatarColor: const Color(0xFF3B82F6), walletId: 3),
  MockContact(name: 'Sarah', initials: 'SL', avatarColor: const Color(0xFF8B5CF6), walletId: 4),
  MockContact(name: 'David', initials: 'DJ', avatarColor: const Color(0xFF10B981), walletId: 5),
  MockContact(name: 'Ayşe', initials: 'AK', avatarColor: const Color(0xFFF59E0B), walletId: 6),
  MockContact(name: 'Mehmet', initials: 'MY', avatarColor: const Color(0xFFEF4444), walletId: 7),
];

class SendMoneyScreen extends StatefulWidget {
  const SendMoneyScreen({super.key});

  @override
  State<SendMoneyScreen> createState() => _SendMoneyScreenState();
}

class _SendMoneyScreenState extends State<SendMoneyScreen> {
  String _amount = '0';
  int _selectedContact = 1;
  final _noteController = TextEditingController();

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  void _onKeyPress(String key) {
    setState(() {
      if (key == '⌫') {
        if (_amount.length > 1) {
          _amount = _amount.substring(0, _amount.length - 1);
        } else {
          _amount = '0';
        }
      } else if (key == '.' && _amount.contains('.')) {
        return;
      } else if (_amount == '0' && key != '.') {
        _amount = key;
      } else if (_amount.length < 10) {
        _amount += key;
      }
    });
  }

  String get _displayAmount {
    if (_amount.contains('.')) return _amount;
    return _amount;
  }

  Future<void> _handleSendMoney() async {
    final walletProvider = context.read<WalletProvider>();
    if (walletProvider.wallets.isEmpty) return;

    final amount = double.tryParse(_amount) ?? 0;
    final senderWalletId = walletProvider.wallets.first.walletId;
    final receiverWalletId = mockContacts[_selectedContact].walletId;
    final description = _noteController.text.isEmpty ? 'Transfer' : _noteController.text;

    final success = await walletProvider.sendMoney(
      senderWalletId: senderWalletId,
      receiverWalletId: receiverWalletId,
      amount: amount,
      description: description,
    );

    if (success && mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SuccessScreen(
            amount: '₺$_amount',
            recipient: mockContacts[_selectedContact].name,
            isSend: true,
          ),
        ),
      );
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transfer başarısız. Bakiye yetersiz olabilir.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final walletProvider = context.watch<WalletProvider>();
    final currentBalance = walletProvider.wallets.isNotEmpty 
        ? walletProvider.wallets.first.balance 
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
              color: isDark ? AppColors.slate300 : AppColors.slate700,
              size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
              height: 1,
              color: isDark ? AppColors.slate700 : AppColors.slate100),
        ),
      ),
      body: Column(
        children: [
          _buildContactsRow(context, l, isDark),
          _buildAmountDisplay(context, l, isDark, currentBalance),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: TextField(
              controller: _noteController,
              decoration: InputDecoration(
                hintText: l.addNote,
                prefixIcon: const Icon(Icons.edit_note_rounded,
                    color: AppColors.slate400),
                filled: true,
                fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 14),
              ),
            ),
          ),
          Expanded(child: _buildNumpad(context, isDark)),
          _buildSendButton(context, l, isDark),
        ],
      ),
    );
  }

  Widget _buildContactsRow(BuildContext context, AppLocalizations l, bool isDark) {
    return SizedBox(
      height: 120,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 16, 24, 10),
            child: Text(l.sendTo,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                    letterSpacing: 1.1)),
          ),
          Expanded(
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              children: [
                ...mockContacts.asMap().entries.map((e) {
                  final isSelected = _selectedContact == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedContact = e.key),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: e.value.avatarColor,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(color: AppColors.primary, width: 2.5)
                                  : null,
                            ),
                            child: Center(
                              child: Text(e.value.initials,
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15)),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(e.value.name,
                              style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                  color: isSelected ? AppColors.primary : (isDark ? AppColors.slate300 : AppColors.slate700))),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmountDisplay(BuildContext context, AppLocalizations l, bool isDark, double balance) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800.withOpacity(0.5) : AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        children: [
          Text(l.enterAmount, style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('₺', style: TextStyle(fontSize: 28, color: AppColors.primary)),
              const SizedBox(width: 4),
              Text(_displayAmount, style: const TextStyle(fontSize: 52, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
          const SizedBox(height: 12),
          Text('${l.balance}: ₺${balance.toStringAsFixed(2)}', 
            style: TextStyle(color: isDark ? Colors.white70 : AppColors.slate600, fontSize: 13)),
        ],
      ),
    );
  }

  Widget _buildNumpad(BuildContext context, bool isDark) {
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
            ? Icon(Icons.backspace_outlined, color: isDark ? Colors.white70 : Colors.black54)
            : Text(k, style: TextStyle(fontSize: 24, color: isDark ? Colors.white : Colors.black87)),
        ),
      )).toList(),
    );
  }

  Widget _buildSendButton(BuildContext context, AppLocalizations l, bool isDark) {
    final amt = double.tryParse(_amount) ?? 0;
    final isLoading = context.watch<WalletProvider>().isLoading;
    return Padding(
      padding: const EdgeInsets.all(24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: (amt > 0 && !isLoading) ? _handleSendMoney : null,
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
          child: isLoading 
            ? const CircularProgressIndicator(color: Colors.white)
            : Text('${l.sendButton} ₺$_amount', style: const TextStyle(color: Colors.white)),
        ),
      ),
    );
  }
}
