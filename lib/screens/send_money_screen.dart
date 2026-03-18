import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'success_screen.dart';

final mockContacts = [
  MockContact(name: 'Emma', initials: 'EJ', avatarColor: const Color(0xFFEC4899)),
  MockContact(name: 'Michael', initials: 'MS', avatarColor: const Color(0xFF3B82F6)),
  MockContact(name: 'Sarah', initials: 'SL', avatarColor: const Color(0xFF8B5CF6)),
  MockContact(name: 'David', initials: 'DJ', avatarColor: const Color(0xFF10B981)),
  MockContact(name: 'Ayşe', initials: 'AK', avatarColor: const Color(0xFFF59E0B)),
  MockContact(name: 'Mehmet', initials: 'MY', avatarColor: const Color(0xFFEF4444)),
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

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : Colors.white,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : Colors.white,
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
          // Contacts row
          _buildContactsRow(context, l, isDark),

          // Amount display
          _buildAmountDisplay(context, l, isDark),

          // Note input
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

          // Numpad
          Expanded(child: _buildNumpad(context, isDark)),

          // Send button
          _buildSendButton(context, l, isDark),
        ],
      ),
    );
  }

  Widget _buildContactsRow(
      BuildContext context, AppLocalizations l, bool isDark) {
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
                // Contacts
                ...mockContacts.asMap().entries.map((e) {
                  final isSelected = _selectedContact == e.key;
                  return Padding(
                    padding: const EdgeInsets.only(right: 16),
                    child: GestureDetector(
                      onTap: () =>
                          setState(() => _selectedContact = e.key),
                      child: Column(
                        children: [
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: e.value.avatarColor,
                              shape: BoxShape.circle,
                              border: isSelected
                                  ? Border.all(
                                      color: AppColors.primary, width: 2.5)
                                  : null,
                              boxShadow: isSelected
                                  ? [
                                      BoxShadow(
                                          color: AppColors.primary
                                              .withOpacity(0.4),
                                          blurRadius: 8,
                                          offset: const Offset(0, 2))
                                    ]
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
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w500,
                                  color: isSelected
                                      ? AppColors.primary
                                      : (isDark
                                          ? AppColors.slate300
                                          : AppColors.slate700))),
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

  Widget _buildAmountDisplay(
      BuildContext context, AppLocalizations l, bool isDark) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 20),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800.withOpacity(0.5) : AppColors.slate50,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        children: [
          Text(l.enterAmount,
              style: const TextStyle(
                  color: AppColors.slate400,
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              const Text('₺',
                  style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w300,
                      color: AppColors.primary)),
              const SizedBox(width: 4),
              Text(_displayAmount,
                  style: const TextStyle(
                      fontSize: 52,
                      fontWeight: FontWeight.w600,
                      color: AppColors.primary,
                      letterSpacing: -2)),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: isDark ? AppColors.slate700 : Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    blurRadius: 4)
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.account_balance_wallet_outlined,
                    color: AppColors.slate400, size: 14),
                const SizedBox(width: 6),
                Text(
                  '${l.balance}: ',
                  style: const TextStyle(
                      color: AppColors.slate500,
                      fontSize: 12,
                      fontWeight: FontWeight.w500),
                ),
                Text(
                  '₺14.582,50',
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color:
                          isDark ? Colors.white : AppColors.slate800),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumpad(BuildContext context, bool isDark) {
    final keys = [
      '1', '2', '3',
      '4', '5', '6',
      '7', '8', '9',
      '.', '0', '⌫',
    ];

    return GridView.count(
      crossAxisCount: 3,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 4),
      childAspectRatio: 2.4,
      mainAxisSpacing: 4,
      crossAxisSpacing: 4,
      physics: const NeverScrollableScrollPhysics(),
      children: keys.map((k) {
        final isBackspace = k == '⌫';
        return GestureDetector(
          onTap: () => _onKeyPress(k),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: isBackspace
                  ? Icon(Icons.backspace_outlined,
                      color: isDark
                          ? AppColors.slate400
                          : AppColors.slate500,
                      size: 22)
                  : Text(k,
                      style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.w600,
                          color: isDark
                              ? Colors.white
                              : AppColors.slate800)),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSendButton(
      BuildContext context, AppLocalizations l, bool isDark) {
    final amt = double.tryParse(_amount) ?? 0;
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
      child: SizedBox(
        width: double.infinity,
        height: 54,
        child: ElevatedButton(
          onPressed: amt > 0
              ? () {
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
                }
              : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            disabledBackgroundColor: AppColors.primary.withOpacity(0.4),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14)),
            elevation: 4,
            shadowColor: AppColors.primary.withOpacity(0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                '${l.sendButton} ₺$_amount',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.arrow_forward_rounded,
                  color: Colors.white, size: 18),
            ],
          ),
        ),
      ),
    );
  }
}
