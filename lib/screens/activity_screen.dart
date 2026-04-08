import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor:
            isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(l.activity,
            style: TextStyle(
                fontWeight: FontWeight.bold,
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
          // Transaction list
          Expanded(
            child: ListView(
              padding: const EdgeInsets.only(bottom: 20),
              children: [
                _buildDateSection(context, l.today, isDark, _todayTransactions),
                _buildDateSection(
                    context, l.yesterday, isDark, _yesterdayTransactions),
                _buildDateSection(
                    context, 'Mar 15', isDark, _olderTransactions),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateSection(BuildContext context, String dateLabel, bool isDark,
      List<Map<String, dynamic>> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(dateLabel,
              style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.slate500,
                  letterSpacing: 1.1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
                color: isDark ? AppColors.slate700 : AppColors.slate100),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark
                                ? (t['color'] as Color).withOpacity(0.2)
                                : t['bg'] as Color,
                            shape: BoxShape.circle,
                          ),
                          child: Icon(t['icon'] as IconData,
                              color: t['color'] as Color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(t['title'] as String,
                                  style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                      color: isDark
                                          ? Colors.white
                                          : AppColors.slate900)),
                              Text(t['sub'] as String,
                                  style: const TextStyle(
                                      color: AppColors.slate400,
                                      fontSize: 11)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(t['amount'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                  color: (t['credit'] as bool)
                                      ? AppColors.green600
                                      : (isDark
                                          ? Colors.white
                                          : AppColors.slate900),
                                )),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: (t['credit'] as bool)
                                    ? AppColors.green500.withOpacity(0.1)
                                    : AppColors.slate100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                (t['credit'] as bool) ? 'Gelir' : 'Gider',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: (t['credit'] as bool)
                                      ? AppColors.green600
                                      : AppColors.slate500,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(
                        height: 1,
                        indent: 70,
                        color: isDark
                            ? AppColors.slate700
                            : AppColors.slate100),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static const _todayTransactions = [
    {
      'icon': Icons.restaurant_rounded,
      'color': AppColors.orange600,
      'bg': AppColors.orange100,
      'title': 'Starbucks',
      'sub': '09:41',
      'amount': '-₺89,00',
      'credit': false,
    },
    {
      'icon': Icons.send_rounded,
      'color': AppColors.primary,
      'bg': Color(0xFFDBEAFE),
      'title': 'Emma\'ya Gönderildi',
      'sub': '08:15',
      'amount': '-₺250,00',
      'credit': false,
    },
  ];

  static const _yesterdayTransactions = [
    {
      'icon': Icons.shopping_bag_rounded,
      'color': AppColors.blue600,
      'bg': AppColors.blue100,
      'title': 'Trendyol',
      'sub': '14:22',
      'amount': '-₺349,99',
      'credit': false,
    },
    {
      'icon': Icons.bolt_rounded,
      'color': Color(0xFF9333EA),
      'bg': Color(0xFFF3E8FF),
      'title': 'EDAŞ Elektrik',
      'sub': '11:00',
      'amount': '-₺456,00',
      'credit': false,
    },
  ];

  static const _olderTransactions = [
    {
      'icon': Icons.account_balance_rounded,
      'color': AppColors.green600,
      'bg': Color(0xFFDCFCE7),
      'title': 'Maaş',
      'sub': '08:00',
      'amount': '+₺22.500,00',
      'credit': true,
    },
    {
      'icon': Icons.wifi_rounded,
      'color': AppColors.primary,
      'bg': Color(0xFFDBEAFE),
      'title': 'Türk Telekom İnternet',
      'sub': '10:30',
      'amount': '-₺299,00',
      'credit': false,
    },
  ];
}
