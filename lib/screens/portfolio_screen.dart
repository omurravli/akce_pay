import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../models/asset.dart';
import '../providers/portfolio_provider.dart';
import 'trading_screen.dart';

/// Kullanıcının varlık portföyü: toplam değer, kâr/zarar ve dağılım.
class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PortfolioProvider>().fetchHoldings();
    });
  }

  IconData _iconFor(String symbol) {
    if (symbol.startsWith('GOLD')) return Icons.workspace_premium_rounded;
    if (symbol.startsWith('SILVER')) return Icons.shield_moon_rounded;
    if (symbol == 'USD') return Icons.attach_money_rounded;
    if (symbol == 'EUR') return Icons.euro_rounded;
    return Icons.show_chart_rounded;
  }

  Color _colorFor(String symbol) {
    if (symbol.startsWith('GOLD')) return const Color(0xFFD4A017);
    if (symbol.startsWith('SILVER')) return const Color(0xFF94A3B8);
    if (symbol == 'USD') return const Color(0xFF22C55E);
    if (symbol == 'EUR') return const Color(0xFF3B82F6);
    return AppColors.primary;
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l.portfolio,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
        actions: [
          IconButton(
            tooltip: l.tradeBuySell,
            icon: const Icon(Icons.swap_vert_rounded),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const TradingScreen())),
          ),
        ],
      ),
      body: Consumer<PortfolioProvider>(
        builder: (context, pp, _) {
          if (pp.isLoading && pp.holdings.isEmpty) {
            return const Center(child: CircularProgressIndicator());
          }
          return RefreshIndicator(
            onRefresh: () => pp.fetchHoldings(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildSummaryCard(context, l, isDark, pp),
                const SizedBox(height: 16),
                _buildAllocationBar(l, isDark, pp),
                const SizedBox(height: 16),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Text(l.holdings,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isDark
                              ? Colors.white
                              : AppColors.slate900)),
                ),
                const SizedBox(height: 8),
                if (pp.holdings.isEmpty)
                  _emptyState(l, isDark)
                else
                  ...pp.holdings
                      .map((h) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _holdingTile(l, isDark, h),
                          )),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(BuildContext context, AppLocalizations l,
      bool isDark, PortfolioProvider pp) {
    final isUp = pp.totalProfitLoss >= 0;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.primary, AppColors.primaryDark],
        ),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withOpacity(0.3),
              blurRadius: 16,
              offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.portfolioValue,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.85),
                  fontSize: 13,
                  fontWeight: FontWeight.w500)),
          const SizedBox(height: 6),
          Text('₺${pp.totalMarketValue.toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.bold,
                  letterSpacing: -1)),
          const SizedBox(height: 12),
          Row(
            children: [
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (isUp ? Colors.greenAccent : Colors.redAccent)
                      .withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Icon(
                        isUp
                            ? Icons.trending_up_rounded
                            : Icons.trending_down_rounded,
                        size: 14,
                        color: isUp
                            ? Colors.greenAccent
                            : Colors.redAccent),
                    const SizedBox(width: 4),
                    Text(
                      '${isUp ? '+' : ''}₺${pp.totalProfitLoss.toStringAsFixed(2)}  (${pp.totalProfitLossPercent.toStringAsFixed(2)}%)',
                      style: TextStyle(
                          color: isUp
                              ? Colors.greenAccent
                              : Colors.redAccent,
                          fontWeight: FontWeight.bold,
                          fontSize: 12),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(l.profitLoss,
                  style: const TextStyle(
                      color: Colors.white70, fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAllocationBar(
      AppLocalizations l, bool isDark, PortfolioProvider pp) {
    if (pp.holdings.isEmpty || pp.totalMarketValue == 0) {
      return const SizedBox.shrink();
    }
    final segments = pp.holdings
        .map((h) => _Segment(h.symbol, h.name, h.marketValue,
            _colorFor(h.symbol)))
        .toList();
    final total = pp.totalMarketValue;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(l.allocation,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isDark ? Colors.white : AppColors.slate800)),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              height: 12,
              child: Row(
                children: segments.map((s) {
                  final flex = ((s.value / total) * 1000).round();
                  return Expanded(
                    flex: flex == 0 ? 1 : flex,
                    child: Container(color: s.color),
                  );
                }).toList(),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: segments.map((s) {
              final pct = (s.value / total) * 100;
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: s.color,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 6),
                  Text(
                    '${s.name} ${pct.toStringAsFixed(1)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: isDark
                            ? AppColors.slate300
                            : AppColors.slate700),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _holdingTile(
      AppLocalizations l, bool isDark, PortfolioHolding h) {
    final color = _colorFor(h.symbol);
    final isUp = h.profitLoss >= 0;
    return InkWell(
      onTap: () => Navigator.push(
          context,
          MaterialPageRoute(
              builder: (_) => TradingScreen(initialSymbol: h.symbol))),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.slate700 : AppColors.slate100),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle),
              child: Icon(_iconFor(h.symbol), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(h.name,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isDark
                              ? Colors.white
                              : AppColors.slate900)),
                  Text(
                      '${h.quantity.toStringAsFixed(2)} • ₺${h.averageCost.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: AppColors.slate400, fontSize: 11)),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('₺${h.marketValue.toStringAsFixed(2)}',
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color:
                            isDark ? Colors.white : AppColors.slate900)),
                Text(
                    '${isUp ? '+' : ''}${h.profitLossPercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isUp ? AppColors.green600 : AppColors.red500)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyState(AppLocalizations l, bool isDark) {
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
          const Icon(Icons.pie_chart_outline_rounded,
              size: 40, color: AppColors.slate400),
          const SizedBox(height: 8),
          Text(l.noHoldings,
              style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.slate800)),
          const SizedBox(height: 4),
          Text(l.startTrading,
              style: const TextStyle(
                  fontSize: 12, color: AppColors.slate400)),
        ],
      ),
    );
  }
}

class _Segment {
  final String symbol;
  final String name;
  final double value;
  final Color color;
  _Segment(this.symbol, this.name, this.value, this.color);
}
