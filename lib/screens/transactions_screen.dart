import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../providers/auth_provider.dart';
import '../providers/transaction_provider.dart';
import '../theme.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({super.key});

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<TransactionProvider>().fetchTransactions();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final currentUserId = context.read<AuthProvider>().user?.id ?? '';

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l.recentTransactions),
        backgroundColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => context.read<TransactionProvider>().fetchTransactions(),
          ),
        ],
      ),
      body: Consumer<TransactionProvider>(
        builder: (context, txProvider, _) {
          if (txProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final txList = txProvider.transactions;

          if (txList.isEmpty) {
            return Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.history_rounded, size: 56, color: AppColors.slate400),
                  const SizedBox(height: 12),
                  Text(
                    l.noTransactionHistory,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate800,
                    ),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => context.read<TransactionProvider>().fetchTransactions(),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: txList.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, i) {
                final tx = txList[i];
                final credit = tx.isCredit(currentUserId);
                final isDeposit = tx.senderId == null;
                final icon = isDeposit
                    ? Icons.add_card_rounded
                    : credit
                        ? Icons.arrow_downward_rounded
                        : Icons.send_rounded;
                final color = credit || isDeposit ? AppColors.green600 : AppColors.primary;
                final bg = credit || isDeposit ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
                final amountStr = '${credit || isDeposit ? '+' : '-'}₺${tx.amount.toStringAsFixed(2)}';
                final dateStr = '${tx.date.day.toString().padLeft(2, '0')}.${tx.date.month.toString().padLeft(2, '0')}.${tx.date.year}  ${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';

                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          color: isDark ? color.withValues(alpha: 0.2) : bg,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(icon, color: color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              tx.description?.isNotEmpty == true
                                  ? tx.description!
                                  : (isDeposit ? 'Bakiye Yükleme' : 'Transfer'),
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                                color: isDark ? Colors.white : AppColors.slate900,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(dateStr, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                          ],
                        ),
                      ),
                      Text(
                        amountStr,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: credit || isDeposit ? AppColors.green600 : (isDark ? Colors.white : AppColors.slate900),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
