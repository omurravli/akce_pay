import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme.dart';
import '../services/api_service.dart';
import '../providers/wallet_provider.dart';
import 'success_screen.dart';

class Bill {
  final int id;
  final String category;
  final double amount;
  final String? description;
  final String dueDate;
  final String status;

  Bill({
    required this.id,
    required this.category,
    required this.amount,
    this.description,
    required this.dueDate,
    required this.status,
  });

  factory Bill.fromJson(Map<String, dynamic> j) => Bill(
        id: j['id'] as int,
        category: j['category'] as String,
        amount: double.parse(j['amount'].toString()),
        description: j['description'] as String?,
        dueDate: (j['due_date'] as String).substring(0, 10),
        status: j['status'] as String,
      );

  bool get isPending => status == 'pending';
}

class _CategoryStyle {
  final IconData icon;
  final Color color;
  final Color bgColor;
  const _CategoryStyle(this.icon, this.color, this.bgColor);
}

const _styles = <String, _CategoryStyle>{
  'Elektrik':   _CategoryStyle(Icons.bolt_rounded,            AppColors.orange600,    AppColors.orange100),
  'Doğalgaz':   _CategoryStyle(Icons.local_fire_department_rounded, Color(0xFF9333EA), Color(0xFFF3E8FF)),
  'Su':         _CategoryStyle(Icons.water_drop_rounded,      AppColors.blue600,      AppColors.blue100),
  'İnternet':   _CategoryStyle(Icons.wifi_rounded,            AppColors.primary,      Color(0xFFDBEAFE)),
  'Telefon':    _CategoryStyle(Icons.phone_android_rounded,   Color(0xFF0F766E),      Color(0xFFCCFBF1)),
  'Kira':       _CategoryStyle(Icons.home_rounded,            Color(0xFF0F766E),      Color(0xFFCCFBF1)),
  'Sigorta':    _CategoryStyle(Icons.shield_rounded,          AppColors.blue600,      AppColors.blue100),
  'Diğer':      _CategoryStyle(Icons.receipt_long_rounded,    AppColors.slate500,     AppColors.slate100),
};

_CategoryStyle _styleFor(String cat) =>
    _styles[cat] ?? const _CategoryStyle(Icons.receipt_long_rounded, AppColors.slate500, AppColors.slate100);

class PayBillsScreen extends StatefulWidget {
  const PayBillsScreen({super.key});

  @override
  State<PayBillsScreen> createState() => _PayBillsScreenState();
}

class _PayBillsScreenState extends State<PayBillsScreen> {
  List<Bill> _bills = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchBills();
  }

  Future<void> _fetchBills() async {
    setState(() { _loading = true; _error = null; });
    try {
      final res = await ApiService().getBills();
      if (res.statusCode == 200) {
        final list = (jsonDecode(res.body) as List).map((j) => Bill.fromJson(j)).toList();
        setState(() { _bills = list; _loading = false; });
      } else {
        setState(() { _error = 'Faturalar yüklenemedi'; _loading = false; });
      }
    } catch (_) {
      setState(() { _error = 'Bağlantı hatası'; _loading = false; });
    }
  }

  Future<void> _pay(Bill bill) async {
    final wallet = context.read<WalletProvider>();
    final messenger = ScaffoldMessenger.of(context);
    final nav = Navigator.of(context);

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final s = _styleFor(bill.category);
        return AlertDialog(
          backgroundColor: isDark ? AppColors.cardDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Text('Fatura Öde',
              style: TextStyle(color: isDark ? Colors.white : AppColors.slate900,
                  fontWeight: FontWeight.bold)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Container(width: 40, height: 40,
                    decoration: BoxDecoration(color: s.bgColor, shape: BoxShape.circle),
                    child: Icon(s.icon, color: s.color, size: 20)),
                const SizedBox(width: 12),
                Expanded(child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bill.category,
                        style: TextStyle(fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.slate900)),
                    if (bill.description != null && bill.description!.isNotEmpty)
                      Text(bill.description!,
                          style: const TextStyle(fontSize: 12, color: AppColors.slate400)),
                  ],
                )),
              ]),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Tutar', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                Text('₺${bill.amount.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              ]),
              const SizedBox(height: 4),
              Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                const Text('Son ödeme', style: TextStyle(color: AppColors.slate500, fontSize: 13)),
                Text(bill.dueDate, style: const TextStyle(fontSize: 13)),
              ]),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('İptal', style: TextStyle(color: AppColors.slate400)),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(ctx, true),
              style: ElevatedButton.styleFrom(
                  backgroundColor: s.color,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  elevation: 0),
              child: const Text('Öde', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    final res = await ApiService().payBill(bill.id);
    if (!mounted) return;

    if (res.statusCode == 200) {
      await wallet.fetchWallets();
      if (!mounted) return;
      nav.pushReplacement(MaterialPageRoute(
        builder: (_) => SuccessScreen(
          amount: '₺${bill.amount.toStringAsFixed(2)}',
          recipient: bill.category,
          isSend: false,
        ),
      ));
    } else {
      final msg = jsonDecode(res.body)['error'] ?? 'Ödeme başarısız';
      messenger.showSnackBar(SnackBar(content: Text(msg)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      appBar: AppBar(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        title: Text('Faturalar',
            style: TextStyle(fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : AppColors.slate900)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded,
              color: isDark ? AppColors.slate300 : AppColors.slate700, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded, size: 22),
            color: isDark ? AppColors.slate300 : AppColors.slate700,
            onPressed: _fetchBills,
          ),
        ],
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(height: 1,
              color: isDark ? AppColors.slate700 : AppColors.slate100),
        ),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError(isDark)
              : _buildBody(isDark),
    );
  }

  Widget _buildError(bool isDark) {
    return Center(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.slate400),
        const SizedBox(height: 12),
        Text(_error!, style: const TextStyle(color: AppColors.slate400)),
        const SizedBox(height: 16),
        ElevatedButton(onPressed: _fetchBills, child: const Text('Tekrar Dene')),
      ]),
    );
  }

  Widget _buildBody(bool isDark) {
    final pending = _bills.where((b) => b.isPending).toList();
    final paid = _bills.where((b) => !b.isPending).toList();

    if (_bills.isEmpty) {
      return Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.check_circle_outline_rounded, size: 64,
              color: AppColors.green500.withValues(alpha: 0.7)),
          const SizedBox(height: 16),
          Text('Bekleyen faturanız yok',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.slate900)),
          const SizedBox(height: 6),
          const Text('Harika! Tüm faturalarınız ödendi.',
              style: TextStyle(color: AppColors.slate400)),
        ]),
      );
    }

    return RefreshIndicator(
      onRefresh: _fetchBills,
      child: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        children: [
          if (pending.isNotEmpty) ...[
            _sectionHeader(isDark, '${pending.length} Bekleyen Fatura',
                Icons.warning_amber_rounded, AppColors.orange600),
            const SizedBox(height: 10),
            ...pending.map((b) => _billCard(b, isDark, payable: true)),
          ],
          if (paid.isNotEmpty) ...[
            const SizedBox(height: 20),
            _sectionHeader(isDark, 'Ödenen Faturalar',
                Icons.check_circle_rounded, AppColors.green500),
            const SizedBox(height: 10),
            ...paid.map((b) => _billCard(b, isDark, payable: false)),
          ],
        ],
      ),
    );
  }

  Widget _sectionHeader(bool isDark, String title, IconData icon, Color color) {
    return Row(children: [
      Icon(icon, size: 16, color: color),
      const SizedBox(width: 6),
      Text(title,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
              color: color, letterSpacing: 0.5)),
    ]);
  }

  Widget _billCard(Bill bill, bool isDark, {required bool payable}) {
    final s = _styleFor(bill.category);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: payable
                ? s.color.withValues(alpha: 0.25)
                : (isDark ? AppColors.slate700 : AppColors.slate100)),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.04), blurRadius: 8, offset: const Offset(0, 2)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: payable ? () => _pay(bill) : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 44, height: 44,
                decoration: BoxDecoration(
                    color: payable ? s.bgColor : AppColors.slate100,
                    shape: BoxShape.circle),
                child: Icon(s.icon, color: payable ? s.color : AppColors.slate400, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(bill.category,
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14,
                          color: isDark ? Colors.white : AppColors.slate900)),
                  if (bill.description != null && bill.description!.isNotEmpty)
                    Text(bill.description!,
                        style: const TextStyle(fontSize: 11, color: AppColors.slate400)),
                  const SizedBox(height: 2),
                  Row(children: [
                    Icon(Icons.calendar_today_rounded, size: 10,
                        color: payable ? AppColors.orange600 : AppColors.slate400),
                    const SizedBox(width: 3),
                    Text(
                      payable ? 'Son ödeme: ${bill.dueDate}' : 'Ödendi',
                      style: TextStyle(fontSize: 11,
                          color: payable ? AppColors.orange600 : AppColors.green500,
                          fontWeight: FontWeight.w500),
                    ),
                  ]),
                ],
              )),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('₺${bill.amount.toStringAsFixed(2)}',
                    style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.bold,
                      color: payable ? s.color : AppColors.slate400,
                    )),
                if (payable)
                  Container(
                    margin: const EdgeInsets.only(top: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                    decoration: BoxDecoration(
                        color: s.color, borderRadius: BorderRadius.circular(20)),
                    child: const Text('Öde',
                        style: TextStyle(color: Colors.white, fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  )
                else
                  const Icon(Icons.check_circle_rounded, size: 18, color: AppColors.green500),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}
