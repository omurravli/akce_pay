import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import '../models/asset.dart';
import '../models/app_transaction.dart';
import '../providers/admin_provider.dart';
import '../providers/auth_provider.dart';
import '../services/api_service.dart';

class AdminScreen extends StatefulWidget {
  const AdminScreen({super.key});

  @override
  State<AdminScreen> createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> {
  final _searchController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AdminProvider>().fetch();
    });
    _searchController.addListener(() {
      setState(() => _query = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(l.adminPanel,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: AppColors.red500),
            tooltip: 'Admin çıkış',
            onPressed: () {
              context.read<AuthProvider>().lockAdmin();
              Navigator.pop(context);
            },
          ),
        ],
      ),
      body: Consumer<AdminProvider>(
        builder: (context, ap, _) {
          if (ap.isLoading && ap.stats == null) {
            return const Center(child: CircularProgressIndicator());
          }

          final filtered = _query.isEmpty
              ? ap.users
              : ap.users
                  .where((u) =>
                      u.username.toLowerCase().contains(_query) ||
                      u.email.toLowerCase().contains(_query))
                  .toList();

          return RefreshIndicator(
            onRefresh: () => ap.fetch(),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
              children: [
                _buildStatsGrid(l, isDark, ap.stats),
                const SizedBox(height: 16),
                // Search bar
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Kullanıcı ara...',
                    prefixIcon: const Icon(Icons.search_rounded),
                    suffixIcon: _query.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear_rounded),
                            onPressed: () => _searchController.clear(),
                          )
                        : null,
                    filled: true,
                    fillColor: isDark ? AppColors.cardDark : Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? AppColors.slate700 : AppColors.slate100),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: isDark ? AppColors.slate700 : AppColors.slate100),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(l.usersList,
                        style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppColors.slate900)),
                    Text('${filtered.length} kullanıcı',
                        style: const TextStyle(
                            fontSize: 12, color: AppColors.slate400)),
                  ],
                ),
                const SizedBox(height: 8),
                if (filtered.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(32),
                    child: Center(
                      child: Text(
                        _query.isEmpty ? 'Henüz kullanıcı yok' : 'Sonuç bulunamadı',
                        style: const TextStyle(color: AppColors.slate400),
                      ),
                    ),
                  )
                else
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                          color: isDark ? AppColors.slate700 : AppColors.slate100),
                    ),
                    child: Column(
                      children: filtered.asMap().entries.map((e) {
                        final i = e.key;
                        final u = e.value;
                        return Column(
                          children: [
                            _userTile(l, isDark, u, ap),
                            if (i < filtered.length - 1)
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

  Widget _buildStatsGrid(AppLocalizations l, bool isDark, AdminStats? stats) {
    final textScale = MediaQuery.textScalerOf(context).scale(1.0);
    final cards = <Widget>[
      _statCard(isDark, Icons.people_alt_rounded, AppColors.primary,
          l.totalUsers, '${stats?.totalUsers ?? 0}'),
      _statCard(isDark, Icons.bolt_rounded, AppColors.green600,
          l.activeUsers, '${stats?.activeUsers ?? 0}'),
      _statCard(isDark, Icons.swap_horiz_rounded, const Color(0xFF8B5CF6),
          l.totalTransactions, '${stats?.totalTransactions ?? 0}'),
      _statCard(isDark, Icons.payments_rounded, AppColors.orange600,
          l.totalVolume, '₺${(stats?.totalVolume ?? 0).toStringAsFixed(0)}'),
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

  Widget _statCard(bool isDark, IconData icon, Color color, String label, String value) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isDark ? AppColors.slate700 : AppColors.slate100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
                color: color.withValues(alpha: isDark ? 0.2 : 0.12),
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
                  style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _userTile(AppLocalizations l, bool isDark, AdminUserSummary u, AdminProvider ap) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => AdminUserDetailScreen(user: u)),
      ),
      child: Padding(
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
                    u.username.isEmpty ? '?' : u.username.substring(0, 1).toUpperCase(),
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
                                color: isDark ? Colors.white : AppColors.slate900)),
                      ),
                      if (u.role == 'admin') ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('admin',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary)),
                        ),
                      ],
                      if (!u.isActive) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                              color: AppColors.red500.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(6)),
                          child: const Text('askıya alındı',
                              style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.red500)),
                        ),
                      ],
                    ],
                  ),
                  Text(u.email,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 11)),
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
      ),
    );
  }
}

// ─── User Detail Screen ────────────────────────────────────────────────────

class AdminUserDetailScreen extends StatefulWidget {
  final AdminUserSummary user;
  const AdminUserDetailScreen({super.key, required this.user});

  @override
  State<AdminUserDetailScreen> createState() => _AdminUserDetailScreenState();
}

const _billCategories = [
  ('Elektrik',  Icons.bolt_rounded),
  ('Doğalgaz',  Icons.local_fire_department_rounded),
  ('Su',        Icons.water_drop_rounded),
  ('İnternet',  Icons.wifi_rounded),
  ('Telefon',   Icons.phone_rounded),
  ('Kira',      Icons.home_rounded),
  ('Sigorta',   Icons.shield_rounded),
  ('Diğer',     Icons.receipt_long_rounded),
];

class _AdminUserDetailScreenState extends State<AdminUserDetailScreen> {
  List<AppTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransactions();
  }

  Future<void> _fetchTransactions() async {
    setState(() => _isLoading = true);
    try {
      final res = await ApiService().getAdminUserTransactions(widget.user.id);
      if (res.statusCode == 200 && mounted) {
        final data = jsonDecode(res.body) as List;
        setState(() {
          _transactions = data.map((j) => AppTransaction.fromJson(j)).toList();
        });
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final u = widget.user;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(u.username,
            style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _fetchTransactions,
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _fetchTransactions,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // User info card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: isDark ? AppColors.cardDark : Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: isDark ? AppColors.slate700 : AppColors.slate100),
              ),
              child: Column(
                children: [
                  Container(
                    width: 60,
                    height: 60,
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
                          u.username.isEmpty ? '?' : u.username.substring(0, 1).toUpperCase(),
                          style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(u.username,
                      style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.slate900)),
                  const SizedBox(height: 4),
                  Text(u.email,
                      style: const TextStyle(color: AppColors.slate400, fontSize: 13)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      _infoChip(isDark, 'Bakiye', '₺${u.totalBalance.toStringAsFixed(2)}', AppColors.green600),
                      _infoChip(isDark, 'Rol', u.role, AppColors.primary),
                      _infoChip(
                        isDark,
                        'Durum',
                        u.isActive ? 'Aktif' : 'Askıda',
                        u.isActive ? AppColors.green600 : AppColors.red500,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              Expanded(
                child: _actionBtn(
                  isDark, 'Fatura Gönder', Icons.receipt_long_rounded,
                  const Color(0xFF0891B2), () => _showBillSheet(isDark),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _actionBtn(
                  isDark, 'Ödeme Al', Icons.credit_card_rounded,
                  AppColors.orange600, () => _showChargeSheet(isDark),
                ),
              ),
            ]),
            const SizedBox(height: 20),
            Text('İşlem Geçmişi',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: isDark ? Colors.white : AppColors.slate900)),
            const SizedBox(height: 8),
            if (_isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(32),
                      child: CircularProgressIndicator()))
            else if (_transactions.isEmpty)
              Container(
                padding: const EdgeInsets.all(32),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate100),
                ),
                child: const Center(
                  child: Text('İşlem bulunamadı',
                      style: TextStyle(color: AppColors.slate400)),
                ),
              )
            else
              Container(
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardDark : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                      color: isDark ? AppColors.slate700 : AppColors.slate100),
                ),
                child: Column(
                  children: _transactions.asMap().entries.map((entry) {
                    final i = entry.key;
                    final tx = entry.value;
                    final isDeposit = tx.senderId == null;
                    final isReceiver = tx.receiverId == u.id;
                    final credit = isDeposit || isReceiver;
                    final icon = isDeposit
                        ? Icons.add_card_rounded
                        : credit
                            ? Icons.arrow_downward_rounded
                            : Icons.send_rounded;
                    final color = credit ? AppColors.green600 : AppColors.primary;
                    final bg = credit ? const Color(0xFFDCFCE7) : const Color(0xFFDBEAFE);
                    final amountStr = '${credit ? '+' : '-'}₺${tx.amount.toStringAsFixed(2)}';
                    final dateStr =
                        '${tx.date.day.toString().padLeft(2, '0')}.${tx.date.month.toString().padLeft(2, '0')}.${tx.date.year}  '
                        '${tx.date.hour.toString().padLeft(2, '0')}:${tx.date.minute.toString().padLeft(2, '0')}';

                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Container(
                                width: 40,
                                height: 40,
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
                                          fontSize: 13,
                                          color: isDark ? Colors.white : AppColors.slate900),
                                    ),
                                    Text(dateStr,
                                        style: const TextStyle(
                                            color: AppColors.slate400, fontSize: 11)),
                                  ],
                                ),
                              ),
                              Text(amountStr,
                                  style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: credit
                                          ? AppColors.green600
                                          : (isDark ? Colors.white : AppColors.slate900))),
                            ],
                          ),
                        ),
                        if (i < _transactions.length - 1)
                          Divider(
                              height: 1,
                              indent: 66,
                              color: isDark ? AppColors.slate700 : AppColors.slate100),
                      ],
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _infoChip(bool isDark, String label, String value, Color color) {
    return Column(
      children: [
        Text(value,
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: color)),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
      ],
    );
  }

  Widget _actionBtn(bool isDark, String label, IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: color.withValues(alpha: isDark ? 0.18 : 0.1),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: color, size: 18),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: color)),
            ],
          ),
        ),
      ),
    );
  }

  void _showBillSheet(bool isDark) {
    String selectedCategory = _billCategories[0].$1;
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Fatura Gönder',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900)),
              const SizedBox(height: 4),
              Text(widget.user.username,
                  style: const TextStyle(fontSize: 13, color: AppColors.slate400)),
              const SizedBox(height: 16),
              SizedBox(
                height: 80,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: _billCategories.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (_, i) {
                    final (name, icon) = _billCategories[i];
                    final active = selectedCategory == name;
                    return GestureDetector(
                      onTap: () => setSheet(() => selectedCategory = name),
                      child: Container(
                        width: 72,
                        decoration: BoxDecoration(
                          color: active
                              ? const Color(0xFF0891B2).withValues(alpha: 0.15)
                              : (isDark ? AppColors.slate800 : AppColors.slate50),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: active ? const Color(0xFF0891B2) : Colors.transparent,
                              width: 1.5),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(icon, size: 20,
                                color: active ? const Color(0xFF0891B2) : AppColors.slate400),
                            const SizedBox(height: 4),
                            Text(name, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                                color: active ? const Color(0xFF0891B2) : AppColors.slate400)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),
              _sheetField(isDark, amountCtrl, 'Tutar (₺)', prefixText: '₺ ', numeric: true),
              const SizedBox(height: 10),
              _sheetField(isDark, descCtrl, 'Açıklama (isteğe bağlı)'),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (amount <= 0) return;
                    setSheet(() => loading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final res = await ApiService().adminIssueBill(
                      userId: widget.user.id,
                      category: selectedCategory,
                      amount: amount,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    setSheet(() => loading = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(res.statusCode == 200
                          ? '${widget.user.username} kullanıcısına $selectedCategory faturası gönderildi'
                          : 'Hata: ${jsonDecode(res.body)['error']}'),
                      duration: const Duration(seconds: 3),
                    ));
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF0891B2),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Gönder',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showChargeSheet(bool isDark) {
    final amountCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    bool loading = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: isDark ? AppColors.cardDark : Colors.white,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Padding(
          padding: EdgeInsets.fromLTRB(20, 16, 20, MediaQuery.of(ctx).viewInsets.bottom + 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(child: Container(width: 40, height: 4,
                  decoration: BoxDecoration(color: AppColors.slate300, borderRadius: BorderRadius.circular(2)))),
              const SizedBox(height: 16),
              Text('Ödeme Al',
                  style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.slate900)),
              const SizedBox(height: 4),
              Text('${widget.user.username} · Mevcut bakiye: ₺${widget.user.totalBalance.toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 13, color: AppColors.slate400)),
              const SizedBox(height: 16),
              _sheetField(isDark, amountCtrl, 'Tutar (₺)', prefixText: '₺ ', numeric: true),
              const SizedBox(height: 10),
              _sheetField(isDark, descCtrl, 'Açıklama (kart harcaması)'),
              const SizedBox(height: 16),
              SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: loading ? null : () async {
                    final amount = double.tryParse(amountCtrl.text.replaceAll(',', '.')) ?? 0;
                    if (amount <= 0) return;
                    setSheet(() => loading = true);
                    final messenger = ScaffoldMessenger.of(context);
                    final res = await ApiService().adminChargePayment(
                      userId: widget.user.id,
                      amount: amount,
                      description: descCtrl.text.trim().isEmpty ? null : descCtrl.text.trim(),
                    );
                    if (!mounted) return;
                    setSheet(() => loading = false);
                    if (ctx.mounted) Navigator.pop(ctx);
                    messenger.showSnackBar(SnackBar(
                      content: Text(res.statusCode == 200
                          ? '₺${amount.toStringAsFixed(2)} tahsil edildi'
                          : 'Hata: ${jsonDecode(res.body)['error']}'),
                      duration: const Duration(seconds: 3),
                    ));
                    if (res.statusCode == 200) _fetchTransactions();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.orange600,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  child: loading
                      ? const SizedBox(height: 18, width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Tahsil Et',
                          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sheetField(bool isDark, TextEditingController ctrl, String label,
      {String? prefixText, bool numeric = false}) {
    return TextField(
      controller: ctrl,
      keyboardType: numeric ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
      style: TextStyle(color: isDark ? Colors.white : AppColors.slate900),
      decoration: InputDecoration(
        labelText: label,
        prefixText: prefixText,
        labelStyle: const TextStyle(color: AppColors.slate400, fontSize: 13),
        filled: true,
        fillColor: isDark ? AppColors.slate800 : AppColors.slate50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
    );
  }
}
