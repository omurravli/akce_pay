import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../providers/transaction_provider.dart';
import '../providers/market_provider.dart';
import '../providers/cashback_provider.dart';
import '../providers/portfolio_provider.dart';
import '../models/wallet.dart';
import '../services/demo_data.dart';
import 'send_money_screen.dart';
import 'pay_bills_screen.dart';
import 'activity_screen.dart';
import 'transactions_screen.dart';
import 'trading_screen.dart';
import 'portfolio_screen.dart';
import 'cashback_screen.dart';
import 'admin_screen.dart';
import 'login_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WalletProvider>().fetchWallets();
      context.read<MarketProvider>().fetchRates();
      context.read<PortfolioProvider>().fetchHoldings();
      context.read<CashbackProvider>().fetch();
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    // 0: Home (current), 1: Portfolio, 2: Activity
    if (index == 1) {
      Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PortfolioScreen()));
      setState(() => _selectedIndex = 0);
    } else if (index == 2) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const ActivityScreen()));
      setState(() => _selectedIndex = 0);
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _showAdminPinDialog(BuildContext context) {
    final pinController = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Admin Girişi', style: TextStyle(fontWeight: FontWeight.bold)),
        content: TextField(
          controller: pinController,
          obscureText: true,
          autofocus: true,
          decoration: const InputDecoration(
            hintText: 'PIN',
            prefixIcon: Icon(Icons.lock_outline),
          ),
          onSubmitted: (_) => _tryAdminUnlock(ctx, pinController.text),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('İptal')),
          ElevatedButton(
            onPressed: () => _tryAdminUnlock(ctx, pinController.text),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Giriş', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _tryAdminUnlock(BuildContext ctx, String pin) {
    final success = context.read<AuthProvider>().tryUnlockAdmin(pin);
    Navigator.pop(ctx);
    if (success) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const AdminScreen()));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Yanlış PIN')),
      );
    }
  }

  void _showLoadBalanceDialog(BuildContext context, List<Wallet> wallets) {
    final l = AppLocalizations.of(context)!;
    if (wallets.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(l.walletNotFoundTitle),
          content: Text(l.walletNotFoundDescription),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.close)),
          ],
        ),
      );
      return;
    }

    final amountController = TextEditingController();
    Wallet _selectedWalletInDialog = wallets.first;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text(l.loadMoney, style: const TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Wallet>(
                value: _selectedWalletInDialog,
                decoration: InputDecoration(labelText: l.selectAccount),
                items: wallets.map((w) => DropdownMenuItem(
                  value: w,
                  child: Text("${w.walletType} - ${w.iban.substring(w.iban.length - 4)}"),
                )).toList(),
                onChanged: (v) {
                  if (v != null) {
                    setDialogState(() => _selectedWalletInDialog = v);
                  }
                },
              ),
              const SizedBox(height: 16),
              TextField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: l.amountTry,
                  prefixIcon: const Icon(Icons.add_card),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(l.cancel)),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final messenger = ScaffoldMessenger.of(context);
                  final walletProvider = context.read<WalletProvider>();
                  final txProvider = context.read<TransactionProvider>();
                  final walletId = _selectedWalletInDialog.walletId;
                  Navigator.pop(context);
                  final success = await walletProvider.loadBalance(
                    walletId: walletId,
                    amount: amount,
                    description: l.balanceLoaded,
                  );
                  if (success) txProvider.fetchTransactions();
                  messenger.showSnackBar(
                    SnackBar(content: Text(success ? l.operationSuccessful : l.operationFailed)),
                  );
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: Text(l.upload, style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomPadding = MediaQuery.of(context).viewPadding.bottom;

    return Scaffold(
      backgroundColor:
      isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      bottomNavigationBar:
      _buildBottomNav(context, l, isDark, bottomPadding),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(context, l, isDark),
              _buildDemoBanner(context, l, isDark),
              _buildPagerSection(context, l, isDark),
              _buildQuickActions(context, l, isDark),
              _buildMarketStrip(context, l, isDark),
              _buildAdminEntry(context, l, isDark),
              _buildMonthlySpending(context, l, isDark),
              _buildRecentTransactions(context, l, isDark),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(
      BuildContext context, AppLocalizations l, bool isDark) {
    final appState = AkcePayApp.of(context);
    final currentScale = appState?.textScaleFactor ?? 1.0;
    final auth = context.watch<AuthProvider>();
    final user = auth.user;
    final displayName = auth.isDemo ? l.demoUserName : (user?.username ?? '');

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Avatar – long-press to enter admin PIN
          GestureDetector(
            onLongPress: () => _showAdminPinDialog(context),
            child: Container(
              width: 42,
              height: 42,
              decoration: const BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                ),
              ),
              child: Center(
                child: Text(displayName.isEmpty ? '?' : displayName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 18)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${l.goodMorning} $displayName',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900,
              ),
            ),
          ),

          // Settings Menu (Font, Language, Theme)
          _buildSettingsMenu(context, appState, currentScale, isDark),
        ],
      ),
    );
  }

  Widget _buildSettingsMenu(BuildContext context, appState, double currentScale, bool isDark) {
    return PopupMenuButton<void>(
      offset: const Offset(0, 45),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      color: isDark ? AppColors.cardDark : Colors.white,
      icon: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.slate100,
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.settings_outlined,
          color: isDark ? AppColors.slate400 : AppColors.slate600,
          size: 20,
        ),
      ),
      itemBuilder: (context) => [
        PopupMenuItem(
          enabled: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Theme and Language Row
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Theme Toggle
                  IconButton(
                    onPressed: () {
                      appState?.setThemeMode(isDark ? ThemeMode.light : ThemeMode.dark);
                      Navigator.pop(context);
                    },
                    icon: Icon(
                      isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                  // Language Toggle
                  TextButton(
                    onPressed: () {
                      final current = Localizations.localeOf(context);
                      appState?.setLocale(current.languageCode == 'tr'
                          ? const Locale('en')
                          : const Locale('tr'));
                      Navigator.pop(context);
                    },
                    child: Text(
                      Localizations.localeOf(context).languageCode.toUpperCase(),
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const Divider(),
              Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  AppLocalizations.of(context)!.textSize,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate400),
                ),
              ),
              _FontSizeControl(
                currentScale: currentScale,
                isDark: isDark,
                onChanged: (scale) {
                  appState?.setTextScaleFactor(scale);
                  Navigator.pop(context);
                },
              ),
              const SizedBox(height: 8),
              const Divider(),
              TextButton.icon(
                onPressed: () async {
                  Navigator.pop(context);
                  await context.read<AuthProvider>().logout();
                  if (mounted) {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                          builder: (_) => const LoginScreen()),
                      (_) => false,
                    );
                  }
                },
                icon: const Icon(Icons.logout_rounded,
                    size: 18, color: AppColors.red500),
                label: Text(
                  AppLocalizations.of(context)!.logout,
                  style: TextStyle(
                      color: AppColors.red500,
                      fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPagerSection(BuildContext context, AppLocalizations l, bool isDark) {
    return Consumer<WalletProvider>(
      builder: (context, walletProvider, _) {
        final wallets = walletProvider.wallets;
        
        final totalBalance = wallets.fold<double>(0, (sum, wallet) => sum + wallet.balance);

        final List<Widget> pages = [
          _buildBalanceCard(context, l, isDark, totalBalance),
          ...wallets.map((w) => _buildWalletsCard(context, l, isDark, w)),
          _buildCardsCard(context, l, isDark),
        ];

        return Column(
          children: [
            SizedBox(
              height: 200,
              child: PageView(
                controller: _pageController,
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: pages,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(pages.length, (index) {
                final isActive = _currentPage == index;
                return AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  height: 6,
                  width: isActive ? 16 : 6,
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : AppColors.slate300,
                    borderRadius: BorderRadius.circular(3),
                  ),
                );
              }),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBalanceCard(
      BuildContext context, AppLocalizations l, bool isDark, double totalBalance) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: Container(
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
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Stack(
          children: [
            Positioned(
              top: -20,
              right: -20,
              child: Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.1)),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(l.totalBalance,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.85),
                          fontSize: 13,
                          fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  Text('₺${totalBalance.toStringAsFixed(2)}',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          letterSpacing: -1)),
                  const Spacer(),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.trending_up,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 4),
                            Text(l.thisMonth,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWalletsCard(BuildContext context, AppLocalizations l, bool isDark, Wallet wallet) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: InkWell(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF2E3192), Color(0xFF1BFFFF)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                bottom: -20,
                right: -20,
                child: Icon(Icons.account_balance_wallet, size: 120, color: Colors.white.withOpacity(0.1)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(wallet.walletType == 'TL' ? l.primaryAccount : l.foreignCurrencyAccount, style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(wallet.iban, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Monospace')),
                    const Spacer(),
                    Text(l.balance, style: const TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("₺${wallet.balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text(l.checkingAccount(wallet.walletType), style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCardsCard(BuildContext context, AppLocalizations l, bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 0),
      child: InkWell(
        onTap: () {},
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0F2027), Color(0xFF203A43), Color(0xFF2C5364)],
            ),
          ),
          child: Stack(
            children: [
              Positioned(
                top: 20,
                right: 20,
                child: Text("VISA", style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 20, fontWeight: FontWeight.bold, fontStyle: FontStyle.italic)),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.akceCard, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                    const Spacer(),
                    const Text("**** **** **** 1289", style: TextStyle(color: Colors.white, fontSize: 18, letterSpacing: 2)),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("VALID THRU", style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 8)),
                            const Text("12/26", style: TextStyle(color: Colors.white, fontSize: 12)),
                          ],
                        ),
                        const Icon(Icons.contactless, color: Colors.white, size: 24),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActions(
      BuildContext context, AppLocalizations l, bool isDark) {
    final walletProvider = context.watch<WalletProvider>();
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final actionWidth = textScale > 1.2 ? 88.0 : 76.0;
    final actionLabelHeight = textScale > 1.2 ? 34.0 : 28.0;

    final actions = [
      (
        icon: Icons.send_rounded,
        label: l.send,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const SendMoneyScreen())),
      ),
      (
        icon: Icons.receipt_long_rounded,
        label: l.payBills,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PayBillsScreen())),
      ),
      (
        icon: Icons.swap_vert_rounded,
        label: l.tradeBuySell,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const TradingScreen())),
      ),
      (
        icon: Icons.pie_chart_rounded,
        label: l.portfolio,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const PortfolioScreen())),
      ),
      (
        icon: Icons.local_atm_rounded,
        label: l.cashback,
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const CashbackScreen())),
      ),
      (
        icon: Icons.add_to_photos_rounded,
        label: l.loadMoney,
        onTap: () => _showLoadBalanceDialog(context, walletProvider.wallets),
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 20, 8, 4),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Row(
          children: actions.map((a) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 6),
              child: GestureDetector(
                onTap: a.onTap,
                behavior: HitTestBehavior.opaque,
                child: SizedBox(
                  width: actionWidth,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.slate800
                              : AppColors.slate100,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(a.icon,
                            color: AppColors.primary, size: 22),
                      ),
                      const SizedBox(height: 6),
                      SizedBox(
                        height: actionLabelHeight,
                        child: Text(
                          a.label,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppColors.slate400
                                : AppColors.slate600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildDemoBanner(
      BuildContext context, AppLocalizations l, bool isDark) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isDemo) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(isDark ? 0.18 : 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.primary.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.flash_on_rounded,
                size: 16, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(
                l.demoBanner,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===== Borsa kısa özeti (gold/silver/USD/EUR) =====
  Widget _buildMarketStrip(
      BuildContext context, AppLocalizations l, bool isDark) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final stripHeight = textScale > 1.2 ? 126.0 : 104.0;

    return Consumer<MarketProvider>(
      builder: (context, mp, _) {
        if (mp.rates.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(l.market,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                          color: isDark
                              ? Colors.white
                              : AppColors.slate900)),
                  GestureDetector(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const TradingScreen())),
                    child: Text(l.seeAll,
                        style: const TextStyle(
                            color: AppColors.primary,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SizedBox(
                height: stripHeight,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: mp.rates.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 10),
                  itemBuilder: (ctx, i) {
                    final r = mp.rates[i];
                    final isUp = r.isUp;
                    final color = r.symbol.startsWith('GOLD')
                        ? const Color(0xFFD4A017)
                        : r.symbol.startsWith('SILVER')
                            ? const Color(0xFF94A3B8)
                            : r.symbol == 'USD'
                                ? AppColors.green600
                                : AppColors.blue600;
                    return GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => TradingScreen(
                                  initialSymbol: r.symbol))),
                      child: Container(
                        width: textScale > 1.2 ? 162 : 150,
                        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.cardDark
                              : Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: isDark
                                  ? AppColors.slate700
                                  : AppColors.slate100),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  decoration: BoxDecoration(
                                    color: color.withOpacity(
                                        isDark ? 0.2 : 0.12),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    r.symbol.startsWith('GOLD')
                                        ? Icons.workspace_premium_rounded
                                        : r.symbol.startsWith('SILVER')
                                            ? Icons.shield_moon_rounded
                                            : r.symbol == 'USD'
                                                ? Icons
                                                    .attach_money_rounded
                                                : Icons.euro_rounded,
                                    size: 14,
                                    color: color,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(l.assetName(r.symbol, r.name),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 12,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate900)),
                                ),
                              ],
                            ),
                            Text('₺${r.midPrice.toStringAsFixed(2)}',
                                style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: isDark
                                        ? Colors.white
                                        : AppColors.slate900)),
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                Icon(
                                    isUp
                                        ? Icons.trending_up
                                        : Icons.trending_down,
                                    size: 12,
                                    color: isUp
                                        ? AppColors.green600
                                        : AppColors.red500),
                                const SizedBox(width: 3),
                                Text(
                                    '${isUp ? '+' : ''}${r.changePercent.toStringAsFixed(2)}%',
                                    style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: isUp
                                            ? AppColors.green600
                                            : AppColors.red500)),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ===== Admin paneli (yalnız role==admin) =====
  Widget _buildAdminEntry(
      BuildContext context, AppLocalizations l, bool isDark) {
    final auth = context.watch<AuthProvider>();
    if (!auth.isAdmin) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => Navigator.push(context,
            MaterialPageRoute(builder: (_) => const AdminScreen())),
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                AppColors.primary.withOpacity(isDark ? 0.25 : 0.1),
                AppColors.primaryDark.withOpacity(isDark ? 0.25 : 0.1),
              ],
            ),
            border: Border.all(
                color: AppColors.primary.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                    color: AppColors.primary, shape: BoxShape.circle),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l.adminPanel,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark
                                ? Colors.white
                                : AppColors.slate900)),
                    Text(l.adminStats,
                        style: const TextStyle(
                            color: AppColors.slate500, fontSize: 11)),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded,
                  color: AppColors.primary),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlySpending(
      BuildContext context, AppLocalizations l, bool isDark) {
    final auth = context.watch<AuthProvider>();
    final txProvider = context.watch<TransactionProvider>();
    final now = DateTime.now();
    final monthNames = ['Ocak','Şubat','Mart','Nisan','Mayıs','Haziran',
                        'Temmuz','Ağustos','Eylül','Ekim','Kasım','Aralık'];

    double spent = 0.0;
    if (auth.isDemo) {
      spent = 0.0;
    } else {
      final userId = auth.user?.id ?? '';
      for (final tx in txProvider.transactions) {
        if (tx.senderId == userId &&
            tx.date.month == now.month &&
            tx.date.year == now.year) {
          spent += tx.amount;
        }
      }
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? AppColors.cardDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isDark ? AppColors.slate700 : AppColors.slate100),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l.monthlySpending,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark ? Colors.white : AppColors.slate900)),
                const SizedBox(height: 4),
                Text(monthNames[now.month - 1],
                    style: const TextStyle(
                        fontSize: 12, color: AppColors.slate400)),
              ],
            ),
            Text(
              '₺${spent.toStringAsFixed(2)}',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: spent > 0 ? AppColors.red500 : (isDark ? Colors.white : AppColors.slate900),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, AppLocalizations l, bool isDark) {
    final isDemo = context.watch<AuthProvider>().isDemo;
    final demoEntries = DemoData.demoActivities.take(4).toList();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(l.recentTransactions,
                  style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color:
                      isDark ? Colors.white : AppColors.slate900)),
              GestureDetector(
                onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) => const TransactionsScreen())),
                child: Text(l.seeAll,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isDemo && demoEntries.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark
                        ? AppColors.slate700
                        : AppColors.slate100),
              ),
              child: Column(
                children: [
                  const Icon(Icons.history_rounded,
                      size: 36, color: AppColors.slate400),
                  const SizedBox(height: 8),
                  Text(
                    l.noTransactionHistory,
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.slate800,
                    ),
                  ),
                ],
              ),
            )
          else if (isDemo)
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
                children: demoEntries.asMap().entries.map((entry) {
                  final i = entry.key;
                  final t = _demoRecentTransaction(l, entry.value);
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
                                    ? t.bg.withOpacity(0.35)
                                    : t.bg,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(t.icon, color: t.color, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment:
                                    CrossAxisAlignment.start,
                                children: [
                                  Text(t.title,
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark
                                              ? Colors.white
                                              : AppColors.slate900)),
                                  Text(t.subtitle,
                                      style: const TextStyle(
                                          color: AppColors.slate400,
                                          fontSize: 12)),
                                ],
                              ),
                            ),
                            Text(
                              t.amount,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                                color: t.isCredit
                                    ? AppColors.green600
                                    : (isDark
                                        ? Colors.white
                                        : AppColors.slate900),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (i < demoEntries.length - 1)
                        Divider(
                            height: 1,
                            color: isDark
                                ? AppColors.slate700
                                : AppColors.slate100),
                    ],
                  );
                }).toList(),
              ),
            )
          else
            Consumer<TransactionProvider>(
              builder: (context, txProvider, _) {
                final currentUserId = context.read<AuthProvider>().user?.id ?? '';
                final txList = txProvider.transactions.take(4).toList();

                if (txProvider.isLoading) {
                  return const Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                  );
                }

                if (txList.isEmpty) {
                  return Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
                    ),
                    child: Column(
                      children: [
                        const Icon(Icons.history_rounded, size: 36, color: AppColors.slate400),
                        const SizedBox(height: 8),
                        Text(
                          l.noTransactionHistory,
                          style: TextStyle(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.slate800,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return Container(
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.cardDark : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
                  ),
                  child: Column(
                    children: txList.asMap().entries.map((entry) {
                      final i = entry.key;
                      final tx = entry.value;
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
                      final subtitle = '${tx.date.day}.${tx.date.month}.${tx.date.year}';

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
                                    color: isDark ? color.withValues(alpha: 0.2) : bg,
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
                                        tx.description?.isNotEmpty == true
                                            ? tx.description!
                                            : (isDeposit ? 'Bakiye Yükleme' : 'Transfer'),
                                        style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                          color: isDark ? Colors.white : AppColors.slate900,
                                        ),
                                      ),
                                      Text(subtitle, style: const TextStyle(color: AppColors.slate400, fontSize: 12)),
                                    ],
                                  ),
                                ),
                                Text(
                                  amountStr,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: credit || isDeposit
                                        ? AppColors.green600
                                        : (isDark ? Colors.white : AppColors.slate900),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (i < txList.length - 1)
                            Divider(height: 1, color: isDark ? AppColors.slate700 : AppColors.slate100),
                        ],
                      );
                    }).toList(),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  ({
    IconData icon,
    Color color,
    Color bg,
    String title,
    String subtitle,
    String amount,
    bool isCredit
  }) _demoRecentTransaction(AppLocalizations l, DemoActivityEntry entry) {
    final subtitle =
        '${entry.createdAt.hour.toString().padLeft(2, '0')}:${entry.createdAt.minute.toString().padLeft(2, '0')}';
    final amount =
        '${entry.isCredit ? '+' : '-'}₺${entry.amount.toStringAsFixed(2)}';

    switch (entry.type) {
      case 'load_balance':
        return (
          icon: Icons.add_card_rounded,
          color: AppColors.green600,
          bg: const Color(0xFFDCFCE7),
          title: l.loadMoney,
          subtitle: subtitle,
          amount: amount,
          isCredit: entry.isCredit,
        );
      case 'buy_asset':
        return (
          icon: Icons.north_rounded,
          color: AppColors.orange600,
          bg: AppColors.orange100,
          title: '${l.buy} ${l.assetName(entry.assetSymbol ?? '')}',
          subtitle: subtitle,
          amount: amount,
          isCredit: entry.isCredit,
        );
      case 'sell_asset':
        return (
          icon: Icons.south_rounded,
          color: AppColors.green600,
          bg: const Color(0xFFDCFCE7),
          title: '${l.sell} ${l.assetName(entry.assetSymbol ?? '')}',
          subtitle: subtitle,
          amount: amount,
          isCredit: entry.isCredit,
        );
      case 'send_money':
        return (
          icon: Icons.send_rounded,
          color: AppColors.primary,
          bg: const Color(0xFFDBEAFE),
          title: entry.note ?? l.sendMoney,
          subtitle: subtitle,
          amount: amount,
          isCredit: entry.isCredit,
        );
      default:
        return (
          icon: Icons.receipt_long_rounded,
          color: AppColors.slate500,
          bg: AppColors.slate100,
          title: entry.note ?? l.activity,
          subtitle: subtitle,
          amount: amount,
          isCredit: entry.isCredit,
        );
    }
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l,
      bool isDark, double bottomPadding) {
    final items = [
      (icon: Icons.home_rounded, label: l.home),
      (icon: Icons.pie_chart_rounded, label: l.portfolio),
      (icon: Icons.swap_horiz_rounded, label: l.activity),
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark
            ? AppColors.surfaceDark.withOpacity(0.95)
            : Colors.white.withOpacity(0.95),
        border: Border(
          top: BorderSide(
              color: isDark ? AppColors.slate700 : AppColors.slate200),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -4),
          )
        ],
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      child: Row(
        children: items.asMap().entries.map((e) {
          final isActive = _selectedIndex == e.key;
          return Expanded(
            child: GestureDetector(
              onTap: () => _onNavTap(e.key),
              behavior: HitTestBehavior.opaque,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    e.value.icon,
                    color: isActive
                        ? AppColors.primary
                        : (isDark
                        ? AppColors.slate500
                        : AppColors.slate400),
                    size: 22,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    e.value.label,
                    maxLines: 2,
                    textAlign: TextAlign.center,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: isActive
                          ? FontWeight.bold
                          : FontWeight.w500,
                      color: isActive
                          ? AppColors.primary
                          : (isDark
                          ? AppColors.slate500
                          : AppColors.slate400),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _FontSizeControl extends StatelessWidget {
  final double currentScale;
  final bool isDark;
  final ValueChanged<double> onChanged;

  const _FontSizeControl({
    required this.currentScale,
    required this.isDark,
    required this.onChanged,
  });

  static const _steps = [1.0, 1.2, 1.4];

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.08) : AppColors.slate100,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: _steps.map((step) {
          final isSelected = (currentScale - step).abs() < 0.01;
          final index = _steps.indexOf(step);
          final visualSize = 11.0 + (index * 2.5);

          return GestureDetector(
            onTap: () => onChanged(step),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primary : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'A',
                style: TextStyle(
                  fontSize: visualSize,
                  fontWeight: FontWeight.bold,
                  color: isSelected
                      ? Colors.white
                      : (isDark ? AppColors.slate400 : AppColors.slate600),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
