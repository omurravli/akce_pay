import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../models/asset.dart';
import '../providers/cashback_provider.dart';

class CashbackScreen extends StatefulWidget {
  const CashbackScreen({super.key});

  @override
  State<CashbackScreen> createState() => _CashbackScreenState();
}

class _CashbackScreenState extends State<CashbackScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CashbackProvider>().fetch();
    });
  }

  IconData _iconForCategory(String c) {
    switch (c) {
      case 'shopping':
        return Icons.shopping_bag_rounded;
      case 'bills':
        return Icons.receipt_long_rounded;
      case 'transfer':
        return Icons.send_rounded;
      case 'trade':
        return Icons.show_chart_rounded;
    }
    return Icons.local_atm_rounded;
  }

  Color _colorForCategory(String c) {
    switch (c) {
      case 'shopping':
        return AppColors.blue600;
      case 'bills':
        return AppColors.orange600;
      case 'transfer':
        return AppColors.primary;
      case 'trade':
        return const Color(0xFFD4A017);
    }
    return AppColors.slate500;
  }

  String _categoryLabel(AppLocalizations l, String c) {
    switch (c) {
      case 'shopping':
        return l.categoryShopping;
      case 'bills':
        return l.categoryBills;
      case 'transfer':
        return l.categoryTransfer;
      case 'trade':
        return l.categoryTrade;
    }
    return c;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l.cashback,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
      ),
      body: Consumer<CashbackProvider>(
        builder: (context, cb, _) {
          return RefreshIndicator(
            onRefresh: () => cb.fetch(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildBalanceCard(context, l, isDark, cb),
                const SizedBox(height: 16),
                _buildHowItWorks(l, isDark, cb),
                const SizedBox(height: 16),
                Text(l.cashbackHistory,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            isDark ? Colors.white : AppColors.slate900)),
                const SizedBox(height: 8),
                if (cb.entries.isEmpty)
                  _empty(l, isDark)
                else
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark
                              ? AppColors.slate700
                              : AppColors.slate100),
                    ),
                    child: Column(
                      children: cb.entries.asMap().entries.map((e) {
                        final i = e.key;
                        final c = e.value;
                        return Column(
                          children: [
                            _entryTile(l, isDark, c),
                            if (i < cb.entries.length - 1)
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildBalanceCard(BuildContext context, AppLocalizations l,
      bool isDark, CashbackProvider cb) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF16A34A), Color(0xFF15803D)],
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.green600.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_atm_rounded, color: Colors.white),
              const SizedBox(width: 8),
              Text(l.cashbackBalance,
                  style: const TextStyle(
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 8),
          Text('₺${cb.balance.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1)),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: cb.balance <= 0 || cb.isLoading
                  ? null
                  : () async {
                      final ok = await cb.withdrawToTlWallet();
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Text(ok
                                ? l.cashbackWithdrawSuccess
                                : l.tradeFailed)));
                      }
                    },
              icon: const Icon(Icons.account_balance_wallet_rounded,
                  size: 18),
              label: Text(l.withdrawToWallet),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppColors.green600,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHowItWorks(
      AppLocalizations l, bool isDark, CashbackProvider cb) {
    final rates = cb.rateByCategory;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.cashbackRates,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: isDark ? Colors.white : AppColors.slate800)),
          const SizedBox(height: 10),
          ...rates.entries.map((e) {
            final pct = (e.value * 100).toStringAsFixed(1);
            final color = _colorForCategory(e.key);
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                        color: color.withOpacity(isDark ? 0.2 : 0.12),
                        shape: BoxShape.circle),
                    child: Icon(_iconForCategory(e.key),
                        color: color, size: 16),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(_categoryLabel(l, e.key),
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                            color: isDark
                                ? Colors.white
                                : AppColors.slate800)),
                  ),
                  Text('%$pct',
                      style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _entryTile(AppLocalizations l, bool isDark, CashbackEntry c) {
    final color = _colorForCategory(c.category);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.12),
                shape: BoxShape.circle),
            child: Icon(_iconForCategory(c.category), color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(c.description,
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                        color:
                            isDark ? Colors.white : AppColors.slate900)),
                Text(
                    '${_categoryLabel(l, c.category)} • ₺${c.spentAmount.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.slate400, fontSize: 11)),
              ],
            ),
          ),
          Text('+₺${c.cashbackAmount.toStringAsFixed(2)}',
              style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: AppColors.green600)),
        ],
      ),
    );
  }

  Widget _empty(AppLocalizations l, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(32),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        children: [
          const Icon(Icons.local_atm_outlined,
              size: 40, color: AppColors.slate400),
          const SizedBox(height: 8),
          Text(l.cashbackEmpty,
              style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate800)),
        ],
      ),
    );
  }
}
