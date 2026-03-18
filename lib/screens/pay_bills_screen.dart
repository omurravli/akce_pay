import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'success_screen.dart';

class _BillType {
  final IconData icon;
  final String Function(AppLocalizations) label;
  final Color color;
  final Color bgColor;
  final String mockAmount;
  final String mockDue;

  const _BillType({
    required this.icon,
    required this.label,
    required this.color,
    required this.bgColor,
    required this.mockAmount,
    required this.mockDue,
  });
}

class PayBillsScreen extends StatefulWidget {
  const PayBillsScreen({super.key});

  @override
  State<PayBillsScreen> createState() => _PayBillsScreenState();
}

class _PayBillsScreenState extends State<PayBillsScreen> {
  int _selectedBillType = 0;
  final _billNoController = TextEditingController();
  final _amountController = TextEditingController();

  static const List<_BillType> _billTypes = [
    _BillType(
      icon: Icons.bolt_rounded,
      label: _electricityLabel,
      color: AppColors.orange600,
      bgColor: AppColors.orange100,
      mockAmount: '456,00',
      mockDue: '25.03.2026',
    ),
    _BillType(
      icon: Icons.water_drop_rounded,
      label: _waterLabel,
      color: AppColors.blue600,
      bgColor: AppColors.blue100,
      mockAmount: '87,50',
      mockDue: '28.03.2026',
    ),
    _BillType(
      icon: Icons.wifi_rounded,
      label: _internetLabel,
      color: AppColors.primary,
      bgColor: Color(0xFFDBEAFE),
      mockAmount: '299,00',
      mockDue: '01.04.2026',
    ),
    _BillType(
      icon: Icons.local_fire_department_rounded,
      label: _gasLabel,
      color: Color(0xFF9333EA),
      bgColor: Color(0xFFF3E8FF),
      mockAmount: '612,75',
      mockDue: '22.03.2026',
    ),
    _BillType(
      icon: Icons.phone_android_rounded,
      label: _phoneLabel,
      color: Color(0xFF0F766E),
      bgColor: Color(0xFFCCFBF1),
      mockAmount: '189,90',
      mockDue: '15.04.2026',
    ),
    _BillType(
      icon: Icons.subscriptions_rounded,
      label: _subsLabel,
      color: Color(0xFFDB2777),
      bgColor: Color(0xFFFCE7F3),
      mockAmount: '59,99',
      mockDue: '05.04.2026',
    ),
  ];

  static String _electricityLabel(AppLocalizations l) => l.electricity;
  static String _waterLabel(AppLocalizations l) => l.water;
  static String _internetLabel(AppLocalizations l) => l.internet;
  static String _gasLabel(AppLocalizations l) => l.naturalGas;
  static String _phoneLabel(AppLocalizations l) => l.phone;
  static String _subsLabel(AppLocalizations l) => l.subscriptions;

  @override
  void initState() {
    super.initState();
    _amountController.text = _billTypes[0].mockAmount;
    _billNoController.text = '1234567890';
  }

  @override
  void dispose() {
    _billNoController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  void _onSelectBill(int index) {
    setState(() {
      _selectedBillType = index;
      _amountController.text = _billTypes[index].mockAmount;
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final selected = _billTypes[_selectedBillType];

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : Colors.white,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(l.payBills,
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            // Pending bills banner
            _buildPendingBanner(context, l, isDark),
            const SizedBox(height: 20),

            // Category label
            Text(l.billCategories,
                style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.slate500,
                    letterSpacing: 1.1)),
            const SizedBox(height: 12),

            // Bill type grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.1,
              children: _billTypes.asMap().entries.map((e) {
                final isSelected = _selectedBillType == e.key;
                return GestureDetector(
                  onTap: () => _onSelectBill(e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? e.value.color
                          : (isDark ? AppColors.cardDark : Colors.white),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected
                            ? e.value.color
                            : (isDark
                                ? AppColors.slate700
                                : AppColors.slate100),
                        width: isSelected ? 2 : 1,
                      ),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                  color: e.value.color.withOpacity(0.3),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4))
                            ]
                          : [
                              BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 6)
                            ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          e.value.icon,
                          color: isSelected
                              ? Colors.white
                              : e.value.color,
                          size: 28,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          e.value.label(l),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isSelected
                                ? FontWeight.bold
                                : FontWeight.w500,
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? AppColors.slate300
                                    : AppColors.slate700),
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),

            const SizedBox(height: 24),

            // Selected bill detail card
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    selected.color.withOpacity(isDark ? 0.2 : 0.08),
                    selected.color.withOpacity(isDark ? 0.08 : 0.02),
                  ],
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: selected.color.withOpacity(0.25)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                        color: selected.bgColor,
                        shape: BoxShape.circle),
                    child: Icon(selected.icon,
                        color: selected.color, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(selected.label(l),
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.slate900)),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.calendar_today_rounded,
                                size: 11, color: AppColors.slate400),
                            const SizedBox(width: 4),
                            Text(
                              '${l.dueDate}: ${selected.mockDue}',
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppColors.slate500),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${selected.mockAmount}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: selected.color,
                        ),
                      ),
                      Text(l.billAmount,
                          style: const TextStyle(
                              fontSize: 10, color: AppColors.slate400)),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Bill number field
            Text(l.billNo,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate300 : AppColors.slate700)),
            const SizedBox(height: 8),
            TextField(
              controller: _billNoController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: l.enterBillNo,
                prefixIcon: const Icon(Icons.tag_rounded,
                    color: AppColors.slate400, size: 20),
                filled: true,
                fillColor:
                    isDark ? AppColors.slate800 : AppColors.slate50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.slate200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: isDark
                            ? AppColors.slate700
                            : AppColors.slate200)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Amount field
            Text(l.amount,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isDark ? AppColors.slate300 : AppColors.slate700)),
            const SizedBox(height: 8),
            TextField(
              controller: _amountController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                prefixIcon: const Padding(
                  padding: EdgeInsets.only(left: 14, right: 8),
                  child: Text('₺',
                      style: TextStyle(
                          fontSize: 18,
                          color: AppColors.slate500,
                          fontWeight: FontWeight.w500)),
                ),
                prefixIconConstraints: const BoxConstraints(minWidth: 0),
                filled: true,
                fillColor:
                    isDark ? AppColors.slate800 : AppColors.slate50,
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide:
                        const BorderSide(color: AppColors.slate200)),
                enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(
                        color: isDark
                            ? AppColors.slate700
                            : AppColors.slate200)),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide:
                      const BorderSide(color: AppColors.primary, width: 2),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Pay button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(
                      builder: (_) => SuccessScreen(
                        amount: '₺${_amountController.text}',
                        recipient: selected.label(l),
                        isSend: false,
                      ),
                    ),
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: selected.color,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  elevation: 4,
                  shadowColor: selected.color.withOpacity(0.4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(selected.icon, color: Colors.white, size: 20),
                    const SizedBox(width: 8),
                    Text(l.payNow,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingBanner(
      BuildContext context, AppLocalizations l, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFFED7AA)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.orange100,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.warning_amber_rounded,
                color: AppColors.orange600, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.pendingBills,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 13,
                        color: AppColors.orange600)),
                Text(
                    Localizations.localeOf(context).languageCode == 'tr'
                        ? '3 fatura ödeme bekliyor'
                        : '3 bills are awaiting payment',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.slate600)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}