import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../models/asset.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/wallet_provider.dart';

/// Borsa: Altın/Gümüş/Döviz al-sat ekranı.
class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key, this.initialSymbol});

  final String? initialSymbol;

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().fetchRates();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
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
        title: Text(l.tradeBuySell,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabs,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate400,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: l.market),
            Tab(text: l.holdings),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildMarketTab(l, isDark),
          _buildHoldingsTab(l, isDark),
        ],
      ),
    );
  }

  Widget _buildMarketTab(AppLocalizations l, bool isDark) {
    return Consumer<MarketProvider>(
      builder: (context, mp, _) {
        if (mp.isLoading && mp.rates.isEmpty) {
          return const Center(child: CircularProgressIndicator());
        }
        return RefreshIndicator(
          onRefresh: () => mp.fetchRates(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: mp.rates.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final r = mp.rates[i];
              return _buildRateCard(l, isDark, r);
            },
          ),
        );
      },
    );
  }

  Widget _buildRateCard(AppLocalizations l, bool isDark, MarketRate r) {
    final color = _colorFor(r.symbol);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withOpacity(isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconFor(r.symbol), color: color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.assetName(r.symbol, r.name),
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color:
                                isDark ? Colors.white : AppColors.slate900)),
                    Text(r.symbol,
                        style: const TextStyle(
                            color: AppColors.slate400, fontSize: 11)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: (r.isUp ? AppColors.green500 : AppColors.red500)
                      .withOpacity(0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(r.isUp ? Icons.trending_up : Icons.trending_down,
                        size: 14,
                        color:
                            r.isUp ? AppColors.green600 : AppColors.red500),
                    const SizedBox(width: 4),
                    Text(
                      '${r.isUp ? '+' : ''}${r.changePercent.toStringAsFixed(2)}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color:
                            r.isUp ? AppColors.green600 : AppColors.red500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _priceCell(
                    isDark, l.buyPrice, '₺${r.buyPrice.toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _priceCell(isDark, l.sellPrice,
                    '₺${r.sellPrice.toStringAsFixed(2)}'),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _openSellSheet(r),
                  icon: const Icon(Icons.south_rounded, size: 16),
                  label: Text(l.sell),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.red500,
                    side: const BorderSide(color: AppColors.red500),
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _openBuySheet(r),
                  icon: const Icon(Icons.north_rounded, size: 16),
                  label: Text(l.buy),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.green600,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _priceCell(bool isDark, String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate50,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  color: AppColors.slate400, fontSize: 10)),
          const SizedBox(height: 2),
          Text(value,
              style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.slate900)),
        ],
      ),
    );
  }

  Widget _buildHoldingsTab(AppLocalizations l, bool isDark) {
    return Consumer<PortfolioProvider>(
      builder: (context, pp, _) {
        if (pp.holdings.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.pie_chart_outline_rounded,
                      size: 48, color: AppColors.slate400),
                  const SizedBox(height: 12),
                  Text(l.noHoldings,
                      style: TextStyle(
                          color: isDark
                              ? Colors.white70
                              : AppColors.slate700,
                          fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(l.startTrading,
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate400)),
                ],
              ),
            ),
          );
        }
        return RefreshIndicator(
          onRefresh: () => pp.fetchHoldings(),
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            itemCount: pp.holdings.length,
            separatorBuilder: (_, __) => const SizedBox(height: 10),
            itemBuilder: (context, i) {
              final h = pp.holdings[i];
              return _buildHoldingRow(l, isDark, h);
            },
          ),
        );
      },
    );
  }

  Widget _buildHoldingRow(AppLocalizations l, bool isDark, PortfolioHolding h) {
    final color = _colorFor(h.symbol);
    final pl = h.profitLoss;
    final plPct = h.profitLossPercent;
    final isUp = pl >= 0;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: color.withOpacity(isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle),
                child: Icon(_iconFor(h.symbol), color: color, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(h.name,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color:
                                isDark ? Colors.white : AppColors.slate900)),
                    Text(
                        '${h.quantity.toStringAsFixed(2)} ${h.symbol.startsWith('GOLD') || h.symbol.startsWith('SILVER') ? 'gr' : 'adet'}',
                        style: const TextStyle(
                            fontSize: 11, color: AppColors.slate400)),
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
                          color: isDark
                              ? Colors.white
                              : AppColors.slate900)),
                  Text(
                    '${isUp ? '+' : ''}${pl.toStringAsFixed(2)} (${plPct.toStringAsFixed(2)}%)',
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color:
                            isUp ? AppColors.green600 : AppColors.red500),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: _priceCell(isDark, l.avgCost,
                    '₺${h.averageCost.toStringAsFixed(2)}'),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _priceCell(isDark, l.currentPrice,
                    '₺${h.currentPrice.toStringAsFixed(2)}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _openBuySheet(MarketRate rate) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text('${l.tradeBuyTitle} – ${rate.name}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900)),
              const SizedBox(height: 4),
              Text('₺${rate.sellPrice.toStringAsFixed(2)} / birim',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.slate400)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.tradeAmountTl,
                  prefixIcon: const Icon(Icons.payments_outlined),
                ),
              ),
              const SizedBox(height: 8),
              Consumer2<WalletProvider, PortfolioProvider>(
                builder: (context, wp, pp, _) {
                  final tl = wp.wallets
                      .where((w) => w.walletType == 'TL')
                      .toList();
                  final balance = tl.isNotEmpty ? tl.first.balance : 0.0;
                  return Text(
                      '${l.balance}: ₺${balance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          fontSize: 12, color: AppColors.slate500));
                },
              ),
              const SizedBox(height: 16),
              Consumer<PortfolioProvider>(
                builder: (context, pp, _) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: pp.isLoading
                          ? null
                          : () async {
                              final amt =
                                  double.tryParse(controller.text) ?? 0;
                              if (amt <= 0) return;
                              final ok = await pp.buyAsset(
                                  symbol: rate.symbol, amountTl: amt);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(ok
                                          ? l.tradeBuySuccess
                                          : l.tradeFailed)),
                                );
                              }
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l.tradeConfirm),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.green600,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _openSellSheet(MarketRate rate) {
    final controller = TextEditingController();
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final l = AppLocalizations.of(context)!;
    final pp = context.read<PortfolioProvider>();
    final holding = pp.holdings.where((h) => h.symbol == rate.symbol).toList();
    final maxQty = holding.isEmpty ? 0.0 : holding.first.quantity;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, 20 + MediaQuery.of(ctx).viewInsets.bottom),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                      color: AppColors.slate300,
                      borderRadius: BorderRadius.circular(2)),
                ),
              ),
              const SizedBox(height: 12),
              Text('${l.tradeSellTitle} – ${rate.name}',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900)),
              const SizedBox(height: 4),
              Text('${l.balance}: ${maxQty.toStringAsFixed(4)}',
                  style: const TextStyle(
                      fontSize: 12, color: AppColors.slate400)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.tradeQuantity,
                  prefixIcon: const Icon(Icons.scale_outlined),
                ),
              ),
              const SizedBox(height: 16),
              Consumer<PortfolioProvider>(
                builder: (context, pp, _) {
                  return SizedBox(
                    height: 50,
                    child: ElevatedButton.icon(
                      onPressed: pp.isLoading
                          ? null
                          : () async {
                              final qty =
                                  double.tryParse(controller.text) ?? 0;
                              if (qty <= 0) return;
                              final ok = await pp.sellAsset(
                                  symbol: rate.symbol, quantity: qty);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                      content: Text(ok
                                          ? l.tradeSellSuccess
                                          : l.tradeFailed)),
                                );
                              }
                            },
                      icon: const Icon(Icons.check_rounded),
                      label: Text(l.tradeConfirm),
                      style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.red500,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12))),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }
}
