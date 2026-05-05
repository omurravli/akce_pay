import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../models/asset.dart';
import '../providers/admin_provider.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetch();
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l.adminPanel,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
      ),
      body: Consumer<AdminProvider>(
        builder: (context, ap, _) {
          if (ap.isLoading && ap.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => ap.fetch(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildStatsGrid(l, isDark, ap.stats),
                const SizedBox(height: 16),
                Text(l.usersList,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color:
                            isDark ? Colors.white : AppColors.slate900)),
                const SizedBox(height: 8),
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
                    children: ap.users.asMap().entries.map((e) {
                      final i = e.key;
                      final u = e.value;
                      return Column(
                        children: [
                          _userTile(l, isDark, u, ap),
                          if (i < ap.users.length - 1)
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

  Widget _buildStatsGrid(
      AppLocalizations l, bool isDark, AdminStats? stats) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cards = <Widget>[
      _statCard(isDark, Icons.people_alt_rounded, AppColors.primary,
          l.totalUsers, '${stats?.totalUsers ?? 0}'),
      _statCard(isDark, Icons.bolt_rounded, AppColors.green600,
          l.activeUsers, '${stats?.activeUsers ?? 0}'),
      _statCard(
          isDark,
          Icons.swap_horiz_rounded,
          const Color(0xFF8B5CF6),
          l.totalTransactions,
          '${stats?.totalTransactions ?? 0}'),
      _statCard(
          isDark,
          Icons.payments_rounded,
          AppColors.orange600,
          l.totalVolume,
          '₺${(stats?.totalVolume ?? 0).toStringAsFixed(0)}'),
      _statCard(
          isDark,
          Icons.local_atm_rounded,
          const Color(0xFFD4A017),
          l.totalCashbackPaid,
          '₺${(stats?.totalCashbackPaid ?? 0).toStringAsFixed(2)}'),
    ];
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 10,
      crossAxisSpacing: 10,
      childAspectRatio: textScale > 1.2 ? 1.2 : 1.5,
      children: cards,
    );
  }

  Widget _statCard(bool isDark, IconData icon, Color color, String label,
      String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withOpacity(isDark ? 0.2 : 0.12),
                shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 18),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      color: isDark ? Colors.white : AppColors.slate900)),
              Text(label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.slate400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userTile(AppLocalizations l, bool isDark, AdminUserSummary u,
      AdminProvider ap) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: u.role == 'admin'
                    ? const [AppColors.primary, AppColors.primaryDark]
                    : const [Color(0xFF94A3B8), Color(0xFF64748B)],
              ),
            ),
            child: Center(
              child: Text(
                  u.username.isEmpty
                      ? '?'
                      : u.username.substring(0, 1).toUpperCase(),
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14)),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(u.username,
                          style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white
                                  : AppColors.slate900)),
                    ),
                    if (u.role == 'admin') ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(6)),
                        child: const Text('admin',
                            style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary)),
                      ),
                    ],
                  ],
                ),
                Text(u.email,
                    style: const TextStyle(
                        color: AppColors.slate400, fontSize: 11)),
                Text('₺${u.totalBalance.toStringAsFixed(2)}',
                    style: const TextStyle(
                        color: AppColors.slate500,
                        fontSize: 11,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          Switch.adaptive(
            value: u.isActive,
            onChanged: (v) => ap.toggleUserActive(u.id, v),
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
}
