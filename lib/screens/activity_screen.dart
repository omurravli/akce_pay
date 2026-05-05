import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../services/demo_data.dart';
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
    final isDemo = context.watch<AuthProvider>().isDemo;
    final demoEntries = DemoData.demoActivities;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text(
          l.activity,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.slate900,
          ),
        ),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? AppColors.slate300 : AppColors.slate700,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(
            height: 1,
            color: isDark ? AppColors.slate700 : AppColors.slate100,
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: isDemo
                ? (demoEntries.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.history_toggle_off_rounded,
                                size: 44,
                                color: AppColors.slate400,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                l.noDemoTransactionHistory,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView(
                        padding: const EdgeInsets.only(bottom: 20),
                        children:
                            _buildDemoSections(context, l, isDark, demoEntries),
                      ))
                : ListView(
                    padding: const EdgeInsets.only(bottom: 20),
                    children: [
                      _buildDateSection(
                        context,
                        l.today,
                        isDark,
                        _todayTransactions(l),
                      ),
                      _buildDateSection(
                        context,
                        l.yesterday,
                        isDark,
                        _yesterdayTransactions(l),
                      ),
                      _buildDateSection(
                        context,
                        'Mar 15',
                        isDark,
                        _olderTransactions(l),
                      ),
                    ],
                  ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildDemoSections(
    BuildContext context,
    AppLocalizations l,
    bool isDark,
    List<DemoActivityEntry> entries,
  ) {
    final now = DateTime.now();
    final yesterdayDate = now.subtract(const Duration(days: 1));
    final today = <DemoActivityEntry>[];
    final yesterday = <DemoActivityEntry>[];
    final older = <DemoActivityEntry>[];

    for (final entry in entries) {
      final createdAt = entry.createdAt;
      final isToday = createdAt.year == now.year &&
          createdAt.month == now.month &&
          createdAt.day == now.day;
      final isYesterday = createdAt.year == yesterdayDate.year &&
          createdAt.month == yesterdayDate.month &&
          createdAt.day == yesterdayDate.day;

      if (isToday) {
        today.add(entry);
      } else if (isYesterday) {
        yesterday.add(entry);
      } else {
        older.add(entry);
      }
    }

    final sections = <Widget>[];
    if (today.isNotEmpty) {
      sections.add(
        _buildDateSection(
          context,
          l.today,
          isDark,
          today.map((entry) => _demoItem(l, entry)).toList(),
        ),
      );
    }
    if (yesterday.isNotEmpty) {
      sections.add(
        _buildDateSection(
          context,
          l.yesterday,
          isDark,
          yesterday.map((entry) => _demoItem(l, entry)).toList(),
        ),
      );
    }
    if (older.isNotEmpty) {
      sections.add(
        _buildDateSection(
          context,
          '${older.first.createdAt.day}.${older.first.createdAt.month}.${older.first.createdAt.year}',
          isDark,
          older.map((entry) => _demoItem(l, entry)).toList(),
        ),
      );
    }
    return sections;
  }

  Map<String, dynamic> _demoItem(AppLocalizations l, DemoActivityEntry entry) {
    final subtitle =
        '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
    final amount =
        '${entry.isCredit ? '+' : '-'}₺${entry.amount.toStringAsFixed(2)}';

    switch (entry.type) {
      case 'load_balance':
        return {
          'icon': Icons.add_card_rounded,
          'color': AppColors.green600,
          'bg': const Color(0xFFDCFCE7),
          'title': l.loadMoney,
          'sub': subtitle,
          'amount': amount,
          'credit': entry.isCredit,
        };
      case 'buy_asset':
        return {
          'icon': Icons.north_rounded,
          'color': AppColors.orange600,
          'bg': AppColors.orange100,
          'title': '${l.buy} ${l.assetName(entry.assetSymbol ?? '')}',
          'sub': subtitle,
          'amount': amount,
          'credit': entry.isCredit,
        };
      case 'sell_asset':
        return {
          'icon': Icons.south_rounded,
          'color': AppColors.green600,
          'bg': const Color(0xFFDCFCE7),
          'title': '${l.sell} ${l.assetName(entry.assetSymbol ?? '')}',
          'sub': subtitle,
          'amount': amount,
          'credit': entry.isCredit,
        };
      case 'send_money':
        return {
          'icon': Icons.send_rounded,
          'color': AppColors.primary,
          'bg': const Color(0xFFDBEAFE),
          'title': entry.note ?? l.sendMoney,
          'sub': subtitle,
          'amount': amount,
          'credit': entry.isCredit,
        };
      default:
        return {
          'icon': Icons.receipt_long_rounded,
          'color': AppColors.slate500,
          'bg': AppColors.slate100,
          'title': entry.note ?? l.activity,
          'sub': subtitle,
          'amount': amount,
          'credit': entry.isCredit,
        };
    }
  }

  Widget _buildDateSection(
    BuildContext context,
    String dateLabel,
    bool isDark,
    List<Map<String, dynamic>> items,
  ) {
    final l = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(
            dateLabel,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColors.slate500,
              letterSpacing: 1.1,
            ),
          ),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? AppColors.slate700 : AppColors.slate100,
            ),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final t = e.value;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
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
                          child: Icon(
                            t['icon'] as IconData,
                            color: t['color'] as Color,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                t['title'] as String,
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.slate900,
                                ),
                              ),
                              Text(
                                t['sub'] as String,
                                style: const TextStyle(
                                  color: AppColors.slate400,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              t['amount'] as String,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: (t['credit'] as bool)
                                    ? AppColors.green600
                                    : (isDark
                                        ? Colors.white
                                        : AppColors.slate900),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: (t['credit'] as bool)
                                    ? AppColors.green500.withOpacity(0.1)
                                    : AppColors.slate100,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                (t['credit'] as bool) ? l.income : l.expenses,
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
                          : AppColors.slate100,
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  static List<Map<String, dynamic>> _todayTransactions(AppLocalizations l) => [
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
          'bg': const Color(0xFFDBEAFE),
          'title': l.isTr ? 'Emma\'ya Gönderildi' : 'Sent to Emma',
          'sub': '08:15',
          'amount': '-₺250,00',
          'credit': false,
        },
      ];

  static List<Map<String, dynamic>> _yesterdayTransactions(
    AppLocalizations l,
  ) =>
      [
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
          'color': const Color(0xFF9333EA),
          'bg': const Color(0xFFF3E8FF),
          'title': l.isTr ? 'EDAŞ Elektrik' : 'EDAS Electricity',
          'sub': '11:00',
          'amount': '-₺456,00',
          'credit': false,
        },
      ];

  static List<Map<String, dynamic>> _olderTransactions(AppLocalizations l) => [
        {
          'icon': Icons.account_balance_rounded,
          'color': AppColors.green600,
          'bg': const Color(0xFFDCFCE7),
          'title': l.isTr ? 'Maaş' : 'Salary',
          'sub': '08:00',
          'amount': '+₺22.500,00',
          'credit': true,
        },
        {
          'icon': Icons.wifi_rounded,
          'color': AppColors.primary,
          'bg': const Color(0xFFDBEAFE),
          'title': l.isTr ? 'Türk Telekom İnternet' : 'Turk Telekom Internet',
          'sub': '10:30',
          'amount': '-₺299,00',
          'credit': false,
        },
      ];
}
