import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../main.dart';
import '../providers/auth_provider.dart';
import '../providers/wallet_provider.dart';
import '../models/wallet.dart';
import 'send_money_screen.dart';
import 'pay_bills_screen.dart';
import 'activity_screen.dart';

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
    });
  }

  void _onNavTap(int index) {
    setState(() => _selectedIndex = index);
    if (index == 1) {
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

  void _showLoadBalanceDialog(BuildContext context, List<Wallet> wallets) {
    if (wallets.isEmpty) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text("Cüzdan Bulunamadı"),
          content: const Text("Para yüklemek için aktif bir banka hesabınız/cüzdanınız bulunmuyor. Lütfen önce bir cüzdan oluşturun."),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("Kapat")),
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
          title: const Text("Para Yükle", style: TextStyle(fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<Wallet>(
                value: _selectedWalletInDialog,
                decoration: const InputDecoration(labelText: "Hesap Seçin"),
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
                decoration: const InputDecoration(
                  labelText: "Tutar (₺)",
                  prefixIcon: Icon(Icons.add_card),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text("İptal")),
            ElevatedButton(
              onPressed: () async {
                final amount = double.tryParse(amountController.text);
                if (amount != null && amount > 0) {
                  final success = await context.read<WalletProvider>().loadBalance(
                    walletId: _selectedWalletInDialog.walletId,
                    amount: amount,
                    description: "Bakiye yüklendi",
                  );
                  if (mounted) {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text(success ? "İşlem başarılı" : "İşlem başarısız")),
                    );
                  }
                }
              },
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary),
              child: const Text("Yükle", style: TextStyle(color: Colors.white)),
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
              _buildPagerSection(context, l, isDark),
              _buildQuickActions(context, l, isDark),
              _buildMonthlySpending(context, l, isDark),
              _buildRecentTransactions(context, l, isDark),
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
    final user = context.watch<AuthProvider>().user;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 42,
            height: 42,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [AppColors.primary, AppColors.primaryDark],
              ),
            ),
            child: Center(
              child: Text(user?.username.substring(0, 1).toUpperCase() ?? 'A',
                  style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '${l.goodMorning} ${user?.username ?? ''}',
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
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                child: Text(
                  "Yazı Boyutu",
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.slate400),
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
                    Text(wallet.walletType == 'TL' ? "Ana Hesap" : "Döviz Hesabı", style: const TextStyle(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w500)),
                    const SizedBox(height: 4),
                    Text(wallet.iban, style: const TextStyle(color: Colors.white, fontSize: 14, fontFamily: 'Monospace')),
                    const Spacer(),
                    const Text("Bakiye", style: TextStyle(color: Colors.white70, fontSize: 12)),
                    Text("₺${wallet.balance.toStringAsFixed(2)}", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(8)),
                      child: Text("Vadesiz ${wallet.walletType}", style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
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
                    const Text("Akçe Card", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
    
    final actions = [
      (
      icon: Icons.send_rounded,
      label: l.send,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const SendMoneyScreen()))
      ),
      (
      icon: Icons.receipt_long_rounded,
      label: l.payBills,
      onTap: () => Navigator.push(context,
          MaterialPageRoute(builder: (_) => const PayBillsScreen()))
      ),
      (
      icon: Icons.add_to_photos_rounded,
      label: "Para Yükle",
      onTap: () => _showLoadBalanceDialog(context, walletProvider.wallets)
      ),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: actions.map((a) {
          return GestureDetector(
            onTap: a.onTap,
            behavior: HitTestBehavior.opaque,
            child: SizedBox(
              width: 80,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.slate800 : AppColors.slate100,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(a.icon, color: AppColors.primary, size: 22),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    a.label,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: isDark ? AppColors.slate400 : AppColors.slate600,
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

  Widget _buildMonthlySpending(
      BuildContext context, AppLocalizations l, bool isDark) {
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(l.monthlySpending,
                    style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                        color: isDark
                            ? Colors.white
                            : AppColors.slate900)),
                Text('₺1.240 / ₺2.000',
                    style: TextStyle(
                        fontSize: 13,
                        color: isDark
                            ? AppColors.slate400
                            : AppColors.slate500,
                        fontWeight: FontWeight.w500)),
              ],
            ),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: 0.62,
                backgroundColor:
                isDark ? AppColors.slate700 : AppColors.slate200,
                valueColor: const AlwaysStoppedAnimation<Color>(
                    AppColors.primary),
                minHeight: 8,
              ),
            ),
            const SizedBox(height: 8),
            Text(l.budgetUsed,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.slate400
                        : AppColors.slate500)),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentTransactions(
      BuildContext context, AppLocalizations l, bool isDark) {
    final transactions = [
      (
      icon: Icons.restaurant_rounded,
      color: AppColors.orange600,
      bg: AppColors.orange100,
      title: 'Starbucks',
      subtitle: l.today,
      amount: '-₺89,00',
      isCredit: false,
      ),
      (
      icon: Icons.shopping_bag_rounded,
      color: AppColors.blue600,
      bg: AppColors.blue100,
      title: 'Trendyol',
      subtitle: l.yesterday,
      amount: '-₺349,99',
      isCredit: false,
      ),
      (
      icon: Icons.account_balance_rounded,
      color: AppColors.green600,
      bg: const Color(0xFFDCFCE7),
      title: 'Maaş',
      subtitle: 'Mar 15',
      amount: '+₺22.500,00',
      isCredit: true,
      ),
      (
      icon: Icons.bolt_rounded,
      color: AppColors.purple600,
      bg: AppColors.purple100,
      title: 'EDAŞ Elektrik',
      subtitle: 'Mar 12',
      amount: '-₺456,00',
      isCredit: false,
      ),
    ];

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
                        builder: (_) => const ActivityScreen())),
                child: Text(l.seeAll,
                    style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
            ],
          ),
          const SizedBox(height: 12),
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
              children: transactions.asMap().entries.map((entry) {
                final i = entry.key;
                final t = entry.value;
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
                                  ? t.color.withOpacity(0.2)
                                  : t.bg,
                              shape: BoxShape.circle,
                            ),
                            child:
                            Icon(t.icon, color: t.color, size: 20),
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
                    if (i < transactions.length - 1)
                      Divider(
                          height: 1,
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
  }

  Widget _buildBottomNav(BuildContext context, AppLocalizations l,
      bool isDark, double bottomPadding) {
    final items = [
      (icon: Icons.home_rounded, label: l.home),
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
