import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../models/asset.dart';
import '../providers/market_provider.dart';
import '../providers/portfolio_provider.dart';
import '../providers/stocks_provider.dart';
import '../providers/wallet_provider.dart';
import '../services/demo_data.dart';

class TradingScreen extends StatefulWidget {
  const TradingScreen({super.key, this.initialSymbol, this.initialTab = 0});

  final String? initialSymbol;
  final int initialTab;

  @override
  State<TradingScreen> createState() => _TradingScreenState();
}

class _TradingScreenState extends State<TradingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabs;
  final _searchController = TextEditingController();
  Timer? _debounce;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 4, vsync: this, initialIndex: widget.initialTab);
    _searchController.addListener(_onSearchChanged);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketProvider>().fetchRates();
      context.read<StocksProvider>().fetchAll();
    });
  }

  @override
  void dispose() {
    _tabs.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _onSearchChanged() {
    _debounce?.cancel();
    final q = _searchController.text.trim();
    if (q.isEmpty) {
      context.read<StocksProvider>().clearSearch();
      setState(() {});
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 500), () {
      context.read<StocksProvider>().searchStocks(q);
      setState(() {});
    });
    setState(() {});
  }


  IconData _iconFor(String symbol) {
    if (symbol.startsWith('GOLD')) return Icons.workspace_premium_rounded;
    if (symbol.startsWith('SILVER')) return Icons.shield_moon_rounded;
    if (symbol == 'USD') return Icons.attach_money_rounded;
    if (symbol == 'EUR') return Icons.euro_rounded;
    // BIST stocks
    switch (symbol) {
      case 'THYAO': return Icons.flight_rounded;
      case 'GARAN': return Icons.account_balance_rounded;
      case 'AKBNK': return Icons.account_balance_rounded;
      case 'EREGL': return Icons.factory_rounded;
      case 'SISE':  return Icons.science_rounded;
      case 'ASELS': return Icons.radar_rounded;
      case 'KCHOL': return Icons.corporate_fare_rounded;
      default:      return Icons.show_chart_rounded;
    }
  }

  Color _colorFor(String symbol) {
    if (symbol.startsWith('GOLD')) return const Color(0xFFD4A017);
    if (symbol.startsWith('SILVER')) return const Color(0xFF94A3B8);
    if (symbol == 'USD') return const Color(0xFF22C55E);
    if (symbol == 'EUR') return const Color(0xFF3B82F6);
    // BIST stocks — distinct colours
    switch (symbol) {
      case 'THYAO': return const Color(0xFF1D4ED8);
      case 'GARAN': return const Color(0xFF059669);
      case 'AKBNK': return const Color(0xFFDC2626);
      case 'EREGL': return const Color(0xFF7C3AED);
      case 'SISE':  return const Color(0xFF0891B2);
      case 'ASELS': return const Color(0xFF65A30D);
      case 'KCHOL': return const Color(0xFFCA8A04);
      default:      return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
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
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.slate400,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: isDark ? 'Hisseler' : 'Hisseler'),
            const Tab(text: 'Emtia & Döviz'),
            Tab(text: l.portfolio),
            Tab(text: l.news),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabs,
        children: [
          _buildStocksTab(isDark),
          _buildCommoditiesTab(l, isDark),
          _buildHoldingsTab(l, isDark),
          _buildNewsTab(l, isDark),
        ],
      ),
    );
  }

  // ── News tab ──────────────────────────────────────────────────────────
  Widget _buildNewsTab(AppLocalizations l, bool isDark) {
    final newsList = DemoData.demoNews;
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: newsList.length,
      separatorBuilder: (_, __) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final news = newsList[index];
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(news.source, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                  Text(news.time, style: const TextStyle(color: AppColors.slate400, fontSize: 11)),
                ],
              ),
              const SizedBox(height: 8),
              Text(news.title, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: isDark ? Colors.white : AppColors.slate900)),
              const SizedBox(height: 6),
              Text(news.summary, style: const TextStyle(color: AppColors.slate500, fontSize: 13, height: 1.4)),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: () {},
                child: Text(l.readMore, style: const TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── Stocks tab ──────────────────────────────────────────────────────────
  Widget _buildStocksTab(bool isDark) {
    return Consumer<StocksProvider>(
      builder: (context, sp, _) {
        return Column(
          children: [
            _buildStockSearchBar(isDark, sp),
            Expanded(
              child: _searchController.text.isNotEmpty
                  ? _buildSearchResults(isDark, sp)
                  : _buildStocksList(isDark, sp, context),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStockSearchBar(bool isDark, StocksProvider sp) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: TextField(
        controller: _searchController,
        decoration: InputDecoration(
          hintText: 'Hisse ara... (ör: THYAO, PETKM)',
          hintStyle: const TextStyle(fontSize: 13),
          prefixIcon: sp.isSearching
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
              : const Icon(Icons.search_rounded, size: 20),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear_rounded, size: 18),
                  onPressed: () { _searchController.clear(); sp.clearSearch(); })
              : null,
          filled: true,
          fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          isDense: true,
        ),
      ),
    );
  }

  Widget _buildStocksList(bool isDark, StocksProvider sp, BuildContext listCtx) {
    if (sp.isLoading && sp.popular.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }
    return RefreshIndicator(
      onRefresh: () => sp.fetchAll(),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
        children: [
          if (sp.tracked.isNotEmpty) ...[
            _sectionHeader('Takip Listesi', isDark),
            ...sp.tracked.map((s) => _buildStockTile(isDark, s, sp, listCtx)),
            const SizedBox(height: 8),
          ],
          _sectionHeader('Popüler Hisseler (BIST)', isDark),
          ...sp.popular.map((s) => _buildStockTile(isDark, s, sp, listCtx)),
        ],
      ),
    );
  }

  Widget _buildSearchResults(bool isDark, StocksProvider sp) {
    if (sp.isSearching) return const Center(child: CircularProgressIndicator());
    if (sp.searchResults.isEmpty) {
      return const Center(
        child: Text('Sonuç bulunamadı', style: TextStyle(color: AppColors.slate400)),
      );
    }
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: sp.searchResults.length,
      itemBuilder: (context, i) {
        final r = sp.searchResults[i];
        final tracked = sp.isTracked(r.symbol);
        final popularRate = sp.popular.where((p) => p.symbol == r.symbol).isNotEmpty
            ? sp.popular.firstWhere((p) => p.symbol == r.symbol)
            : null;
        final detailRate = popularRate ?? MarketRate(
          symbol: r.symbol, name: r.name,
          buyPrice: 0, sellPrice: 0, changePercent: 0, updatedAt: DateTime.now(),
        );
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => _showStockDetail(context, detailRate),
          child: Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: isDark ? AppColors.cardDark : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
          ),
          child: Row(
            children: [
              Container(
                width: 40, height: 40,
                decoration: BoxDecoration(
                  color: _colorFor(r.symbol).withValues(alpha: isDark ? 0.2 : 0.12),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    r.symbol.substring(0, r.symbol.length.clamp(0, 2)),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: _colorFor(r.symbol)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(r.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                        color: isDark ? Colors.white : AppColors.slate900)),
                    Text(r.symbol, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                  ],
                ),
              ),
              GestureDetector(
                onTap: () async {
                  final messenger = ScaffoldMessenger.of(context);
                  final ok = tracked
                      ? await sp.untrackStock(r.symbol)
                      : await sp.trackStock(r.symbol, r.name);
                  if (mounted) {
                    messenger.showSnackBar(SnackBar(
                      content: Text(ok
                          ? (tracked ? '${r.symbol} takipten çıkarıldı' : '${r.symbol} takip listesine eklendi')
                          : 'İşlem başarısız, tekrar deneyin'),
                      duration: const Duration(seconds: 2),
                    ));
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: (tracked ? AppColors.red500 : AppColors.primary).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tracked ? 'Kaldır' : 'Takip Et',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: tracked ? AppColors.red500 : AppColors.primary),
                  ),
                ),
              ),
            ],
          ),
          ),
        );
      },
    );
  }

  Widget _buildStockTile(bool isDark, MarketRate r, StocksProvider sp, BuildContext tileCtx) {
    final tracked = sp.isTracked(r.symbol);
    final color = _colorFor(r.symbol);
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showStockDetail(tileCtx, r),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Container(
                  width: 40, height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(_iconFor(r.symbol), color: color, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(r.name, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                          color: isDark ? Colors.white : AppColors.slate900)),
                      Text(r.symbol, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(r.sellPrice > 0 ? '₺${r.sellPrice.toStringAsFixed(2)}' : '—',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                            color: isDark ? Colors.white : AppColors.slate900)),
                    if (r.sellPrice > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: (r.isUp ? AppColors.green500 : AppColors.red500).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        '${r.isUp ? '+' : ''}${r.changePercent.toStringAsFixed(2)}%',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold,
                            color: r.isUp ? AppColors.green600 : AppColors.red500),
                      ),
                    ),
                  ],
                ),
                const SizedBox(width: 10),
                GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => _toggleTrack(r, sp),
                  child: Padding(
                    padding: const EdgeInsets.all(4),
                    child: Icon(
                      tracked ? Icons.bookmark_rounded : Icons.bookmark_outline_rounded,
                      color: tracked ? AppColors.primary : AppColors.slate400,
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _toggleTrack(MarketRate r, StocksProvider sp) async {
    final tracked = sp.isTracked(r.symbol);
    final messenger = ScaffoldMessenger.of(context);
    final ok = tracked
        ? await sp.untrackStock(r.symbol)
        : await sp.trackStock(r.symbol, r.name);
    if (mounted) {
      messenger.showSnackBar(SnackBar(
        content: Text(ok
            ? (tracked ? '${r.symbol} takipten çıkarıldı' : '${r.symbol} takip listesine eklendi')
            : 'İşlem başarısız, tekrar deneyin'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  void _showStockDetail(BuildContext ctx, MarketRate r, {bool isStock = true}) {
    final isDark = Theme.of(ctx).brightness == Brightness.dark;
    final color = _colorFor(r.symbol);
    showModalBottomSheet(
      context: ctx,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (sheetCtx) {
        return Consumer<StocksProvider>(
          builder: (sheetCtx, sp2, _) {
            final tracked = sp2.isTracked(r.symbol);
            return Padding(
              padding: EdgeInsets.fromLTRB(20, 12, 20,
                  MediaQuery.of(sheetCtx).viewInsets.bottom + 32),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Center(child: Container(width: 40, height: 4,
                        decoration: BoxDecoration(color: AppColors.slate300,
                            borderRadius: BorderRadius.circular(2)))),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Container(
                          width: 52, height: 52,
                          decoration: BoxDecoration(
                            color: color.withValues(alpha: isDark ? 0.2 : 0.12),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(_iconFor(r.symbol), color: color, size: 26),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(r.name, style: TextStyle(fontSize: 17,
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? Colors.white : AppColors.slate900)),
                              Text('${r.symbol} · ${isStock ? 'Borsa İstanbul' : 'Emtia & Döviz'}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                            ],
                          ),
                        ),
                        if (isStock)
                          GestureDetector(
                            onTap: () async {
                              final messenger = ScaffoldMessenger.of(context);
                              final ok = tracked
                                  ? await sp2.untrackStock(r.symbol)
                                  : await sp2.trackStock(r.symbol, r.name);
                              if (mounted) {
                                messenger.showSnackBar(SnackBar(
                                  content: Text(ok
                                      ? (tracked ? 'Takipten çıkarıldı' : 'Takip listesine eklendi')
                                      : 'İşlem başarısız'),
                                  duration: const Duration(seconds: 2),
                                ));
                              }
                            },
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: (tracked ? AppColors.red500 : AppColors.primary)
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    tracked ? Icons.bookmark_remove_rounded : Icons.bookmark_add_rounded,
                                    size: 16,
                                    color: tracked ? AppColors.red500 : AppColors.primary,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    tracked ? 'Çıkar' : 'Takip Et',
                                    style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                                        color: tracked ? AppColors.red500 : AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(child: _detailCell(isDark, 'Son Fiyat',
                            r.sellPrice > 0 ? '₺${r.sellPrice.toStringAsFixed(2)}' : '—')),
                        const SizedBox(width: 10),
                        Expanded(child: _detailCell(isDark, 'Değişim',
                            r.sellPrice > 0 ? '${r.isUp ? '+' : ''}${r.changePercent.toStringAsFixed(2)}%' : '—',
                            valueColor: r.sellPrice > 0 ? (r.isUp ? AppColors.green600 : AppColors.red500) : null)),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _detailCell(isDark, 'Alış', r.buyPrice > 0 ? '₺${r.buyPrice.toStringAsFixed(2)}' : '—')),
                        const SizedBox(width: 10),
                        Expanded(child: _detailCell(isDark, 'Satış', r.sellPrice > 0 ? '₺${r.sellPrice.toStringAsFixed(2)}' : '—')),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _detailCell(isDark, 'Güncellenme',
                        '${r.updatedAt.hour.toString().padLeft(2, '0')}:${r.updatedAt.minute.toString().padLeft(2, '0')} · ${r.updatedAt.day}.${r.updatedAt.month}.${r.updatedAt.year}'),
                    const SizedBox(height: 16),
                    Divider(color: isDark ? AppColors.slate700 : AppColors.slate100),
                    const SizedBox(height: 8),
                    _TradeSheet(rate: r, isDark: isDark),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _detailCell(bool isDark, String label, String value, {Color? valueColor}) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.slate800 : AppColors.slate50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold,
              color: valueColor ?? (isDark ? Colors.white : AppColors.slate900))),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title, bool isDark) => Padding(
    padding: const EdgeInsets.only(bottom: 8, top: 4),
    child: Text(title,
        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
            color: isDark ? AppColors.slate300 : AppColors.slate600)),
  );

  // ── Commodities & currencies tab ─────────────────────────────────────────
  Widget _buildCommoditiesTab(AppLocalizations l, bool isDark) {
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
            itemBuilder: (context, i) => _buildRateCard(l, isDark, mp.rates[i]),
          ),
        );
      },
    );
  }

  Widget _buildRateCard(AppLocalizations l, bool isDark, MarketRate r) {
    final color = _colorFor(r.symbol);
    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: () => _showStockDetail(context, r, isStock: false),
          child: Padding(padding: const EdgeInsets.all(16), child: _rateCardContent(l, isDark, r, color)),
        ),
      ),
    );
  }

  Widget _rateCardContent(AppLocalizations l, bool isDark, MarketRate r, Color color) {
    return Column(
      children: [
        Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
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
                          color: isDark ? Colors.white : AppColors.slate900)),
                  Text(r.symbol,
                      style: const TextStyle(
                          color: AppColors.slate400, fontSize: 11)),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: (r.isUp ? AppColors.green500 : AppColors.red500)
                    .withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(r.isUp ? Icons.trending_up : Icons.trending_down,
                      size: 14,
                      color: r.isUp ? AppColors.green600 : AppColors.red500),
                  const SizedBox(width: 4),
                  Text(
                    '${r.isUp ? '+' : ''}${r.changePercent.toStringAsFixed(2)}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: r.isUp ? AppColors.green600 : AppColors.red500,
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
            Expanded(child: _priceCell(isDark, l.buyPrice, '₺${r.buyPrice.toStringAsFixed(2)}')),
            const SizedBox(width: 8),
            Expanded(child: _priceCell(isDark, l.sellPrice, '₺${r.sellPrice.toStringAsFixed(2)}')),
          ],
        ),
      ],
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
                    color: color.withValues(alpha: isDark ? 0.2 : 0.12),
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

}

// ── Buy / Sell sheet ─────────────────────────────────────────────────────────
class _TradeSheet extends StatefulWidget {
  final MarketRate rate;
  final bool isDark;
  const _TradeSheet({required this.rate, required this.isDark});

  @override
  State<_TradeSheet> createState() => _TradeSheetState();
}

class _TradeSheetState extends State<_TradeSheet> {
  bool _isBuying = true;
  final _ctrl = TextEditingController();
  bool _loading = false;

  String get _unit {
    final s = widget.rate.symbol;
    if (s.startsWith('GOLD') || s.startsWith('SILVER')) return 'gr';
    return 'adet';
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final r = widget.rate;
    final isDark = widget.isDark;
    return Consumer2<PortfolioProvider, WalletProvider>(
      builder: (ctx, pp, wp, _) {
        final tlBalance = wp.wallets
            .where((w) => w.walletType == 'TL')
            .fold(0.0, (s, w) => s + w.balance);
        final holdingList = pp.holdings.where((h) => h.symbol == r.symbol).toList();
        final currentHolding = holdingList.isNotEmpty ? holdingList.first : null;

        final inputVal = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;
        final estimatedUnits = (_isBuying && r.sellPrice > 0 && inputVal > 0)
            ? inputVal / r.sellPrice : 0.0;
        final estimatedProceeds = (!_isBuying && r.buyPrice > 0 && inputVal > 0)
            ? inputVal * r.buyPrice : 0.0;

        final canBuy = r.sellPrice > 0 && inputVal > 0 && inputVal <= tlBalance && !_loading;
        final canSell = r.buyPrice > 0 && inputVal > 0 && !_loading &&
            currentHolding != null && inputVal <= currentHolding.quantity + 0.000001;

        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(children: [
              Expanded(child: _tab('Al', _isBuying, true, isDark, () => setState(() { _isBuying = true; _ctrl.clear(); }))),
              const SizedBox(width: 8),
              Expanded(child: _tab('Sat', !_isBuying, false, isDark, () => setState(() { _isBuying = false; _ctrl.clear(); }))),
            ]),
            const SizedBox(height: 16),
            if (_isBuying) ...[
              _input(isDark, 'Tutar (₺)', prefixText: '₺ '),
              const SizedBox(height: 8),
              Row(children: [
                Text(estimatedUnits > 0 ? '~${estimatedUnits.toStringAsFixed(4)} $_unit' : '',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                const Spacer(),
                Text('Bakiye: ₺${tlBalance.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
              ]),
              const SizedBox(height: 16),
              _actionButton('Al', canBuy, AppColors.green600, () => _doBuy(pp)),
            ] else ...[
              if (currentHolding != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text(
                    'Portföyünüzde: ${currentHolding.quantity.toStringAsFixed(4)} $_unit',
                    style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                )
              else
                Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Text('Portföyünüzde bu varlık yok',
                      style: TextStyle(fontSize: 12,
                          color: isDark ? Colors.white54 : AppColors.slate400)),
                ),
              _input(isDark, 'Miktar ($_unit)',
                  enabled: currentHolding != null,
                  suffix: currentHolding != null
                      ? TextButton(
                          onPressed: () {
                            _ctrl.text = currentHolding.quantity.toStringAsFixed(4);
                            setState(() {});
                          },
                          child: const Text('Tümü',
                              style: TextStyle(fontSize: 12, color: AppColors.primary)))
                      : null),
              const SizedBox(height: 8),
              Text(estimatedProceeds > 0 ? '~₺${estimatedProceeds.toStringAsFixed(2)} gelir' : '',
                  style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
              const SizedBox(height: 16),
              _actionButton('Sat', canSell, AppColors.red500, () => _doSell(pp)),
            ],
          ],
        );
      },
    );
  }

  Widget _tab(String label, bool active, bool isBuy, bool isDark, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: active
              ? (isBuy ? AppColors.green600 : AppColors.red500)
              : (isDark ? AppColors.slate800 : AppColors.slate100),
          borderRadius: BorderRadius.circular(10),
        ),
        alignment: Alignment.center,
        child: Text(label,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: active ? Colors.white : AppColors.slate400)),
      ),
    );
  }

  Widget _input(bool isDark, String label,
      {String? prefixText, bool enabled = true, Widget? suffix}) {
    return TextField(
      controller: _ctrl,
      enabled: enabled,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      onChanged: (_) => setState(() {}),
      style: TextStyle(color: isDark ? Colors.white : AppColors.slate900),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
        suffixIcon: suffix,
        filled: true,
        fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }

  Widget _actionButton(String label, bool enabled, Color color, VoidCallback onTap) {
    return SizedBox(
      height: 48,
      child: ElevatedButton(
        onPressed: enabled ? onTap : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          disabledBackgroundColor: AppColors.slate300,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 0,
        ),
        child: _loading
            ? const SizedBox(height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
            : Text(label,
                style: const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
      ),
    );
  }

  Future<void> _doBuy(PortfolioProvider pp) async {
    final amount = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;
    if (amount <= 0) return;
    setState(() => _loading = true);
    final ok = await pp.buyAsset(symbol: widget.rate.symbol, amountTl: amount);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${widget.rate.symbol} satın alındı' : 'İşlem başarısız, tekrar deneyin'),
      duration: const Duration(seconds: 2),
    ));
    if (ok) _ctrl.clear();
  }

  Future<void> _doSell(PortfolioProvider pp) async {
    final qty = double.tryParse(_ctrl.text.replaceAll(',', '.')) ?? 0;
    if (qty <= 0) return;
    setState(() => _loading = true);
    final ok = await pp.sellAsset(symbol: widget.rate.symbol, quantity: qty);
    if (!mounted) return;
    setState(() => _loading = false);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(ok ? '${widget.rate.symbol} satıldı' : 'İşlem başarısız, tekrar deneyin'),
      duration: const Duration(seconds: 2),
    ));
    if (ok) _ctrl.clear();
  }
}
