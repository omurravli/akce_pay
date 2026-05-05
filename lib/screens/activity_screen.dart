import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../models/user_activity.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';
import '../services/demo_data.dart';
import '../theme.dart';

class ActivityScreen extends StatefulWidget {
  const ActivityScreen({super.key});

  @override
  State<ActivityScreen> createState() => _ActivityScreenState();
}

class _ActivityScreenState extends State<ActivityScreen> {
  List<UserActivity> _activities = [];
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final isDemo = context.read<AuthProvider>().isDemo;
    if (!isDemo) _fetchActivities();
  }

  Future<void> _fetchActivities() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getActivities();
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _activities = data.map((j) => UserActivity.fromJson(j)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

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
                : _buildAuditBody(context, l, isDark),
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

  Widget _buildAuditBody(BuildContext context, AppLocalizations l, bool isDark) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_activities.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.history_toggle_off_rounded, size: 44, color: AppColors.slate400),
            const SizedBox(height: 10),
            Text(
              l.noDemoTransactionHistory,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.slate800,
              ),
            ),
          ],
        ),
      );
    }

    // Group by date label
    final now = DateTime.now();
    final yesterday = now.subtract(const Duration(days: 1));
    final Map<String, List<UserActivity>> grouped = {};
    for (final a in _activities) {
      final String label;
      if (a.date.year == now.year && a.date.month == now.month && a.date.day == now.day) {
        label = l.today;
      } else if (a.date.year == yesterday.year && a.date.month == yesterday.month && a.date.day == yesterday.day) {
        label = l.yesterday;
      } else {
        label = '${a.date.day}.${a.date.month}.${a.date.year}';
      }
      grouped.putIfAbsent(label, () => []).add(a);
    }

    return ListView(
      padding: const EdgeInsets.only(bottom: 20),
      children: grouped.entries.map((e) => _buildAuditSection(context, e.key, isDark, e.value)).toList(),
    );
  }

  Widget _buildAuditSection(BuildContext context, String dateLabel, bool isDark, List<UserActivity> items) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 8),
          child: Text(dateLabel, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate500, letterSpacing: 1.1)),
        ),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
          ),
          child: Column(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final a = e.value;
              final icon = _auditIcon(a.type);
              final color = _auditColor(a.type);
              final isSuccess = a.type != 'UNSUCCESSFUL_LOGIN' && a.type != 'DELETE';
              final time = '${a.date.hour.toString().padLeft(2, '0')}:${a.date.minute.toString().padLeft(2, '0')}';

              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: isDark ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(icon, color: color, size: 20),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _auditTitle(a.type),
                                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.slate900),
                              ),
                              Text(
                                a.description?.isNotEmpty == true ? '${a.description}  •  $time' : time,
                                style: const TextStyle(color: AppColors.slate400, fontSize: 11),
                              ),
                              if (a.ip?.isNotEmpty == true)
                                Text(a.ip!, style: const TextStyle(color: AppColors.slate400, fontSize: 10)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isSuccess ? AppColors.green600.withValues(alpha: 0.1) : AppColors.orange600.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            isSuccess ? 'Başarılı' : 'Başarısız',
                            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: isSuccess ? AppColors.green600 : AppColors.orange600),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (i < items.length - 1)
                    Divider(height: 1, indent: 70, color: isDark ? AppColors.slate700 : AppColors.slate100),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _auditIcon(String type) {
    switch (type) {
      case 'LOGIN': return Icons.login_rounded;
      case 'UNSUCCESSFUL_LOGIN': return Icons.warning_amber_rounded;
      case 'REGISTER': return Icons.person_add_rounded;
      case 'UPDATE': return Icons.edit_rounded;
      case 'DELETE': return Icons.delete_rounded;
      case 'TRANSFER': return Icons.send_rounded;
      case 'DEPOSIT': return Icons.add_card_rounded;
      case 'WALLET_CREATE': return Icons.account_balance_wallet_rounded;
      default: return Icons.info_outline_rounded;
    }
  }

  Color _auditColor(String type) {
    switch (type) {
      case 'LOGIN':
      case 'REGISTER':
      case 'DEPOSIT':
      case 'WALLET_CREATE': return AppColors.green600;
      case 'UNSUCCESSFUL_LOGIN':
      case 'DELETE': return AppColors.orange600;
      case 'TRANSFER': return AppColors.primary;
      default: return AppColors.slate500;
    }
  }

  String _auditTitle(String type) {
    switch (type) {
      case 'LOGIN': return 'Giriş Yapıldı';
      case 'UNSUCCESSFUL_LOGIN': return 'Başarısız Giriş Denemesi';
      case 'REGISTER': return 'Hesap Oluşturuldu';
      case 'UPDATE': return 'Bilgiler Güncellendi';
      case 'DELETE': return 'Hesap Silindi';
      case 'TRANSFER': return 'Para Transferi';
      case 'DEPOSIT': return 'Para Yükleme';
      case 'WALLET_CREATE': return 'Cüzdan Oluşturuldu';
      default: return type;
    }
  }
}
