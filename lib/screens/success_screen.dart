import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'dashboard_screen.dart';

class SuccessScreen extends StatefulWidget {
  final String amount;
  final String recipient;
  final bool isSend;

  const SuccessScreen({
    super.key,
    required this.amount,
    required this.recipient,
    required this.isSend,
  });

  @override
  State<SuccessScreen> createState() => _SuccessScreenState();
}

class _SuccessScreenState extends State<SuccessScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(parent: _controller, curve: Curves.elasticOut);
    _fadeAnim = CurvedAnimation(parent: _controller, curve: Curves.easeIn);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context)!;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.surfaceDark : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Animated check
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.green500.withOpacity(0.15),
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      color: AppColors.green500, size: 64),
                ),
              ),
              const SizedBox(height: 28),

              FadeTransition(
                opacity: _fadeAnim,
                child: Column(
                  children: [
                    Text(l.successMessage,
                        style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.slate900,
                            letterSpacing: -0.5)),
                    const SizedBox(height: 8),
                    Text(l.successSubtitle,
                        style: const TextStyle(
                            color: AppColors.slate500, fontSize: 14)),
                    const SizedBox(height: 32),

                    // Receipt card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardDark : AppColors.slate50,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: isDark
                                ? AppColors.slate700
                                : AppColors.slate100),
                      ),
                      child: Column(
                        children: [
                          _receiptRow(
                            context,
                            isDark,
                            label: widget.isSend ? 'Alıcı' : 'Fatura',
                            value: widget.recipient,
                          ),
                          const SizedBox(height: 12),
                          Divider(
                              color: isDark
                                  ? AppColors.slate700
                                  : AppColors.slate200),
                          const SizedBox(height: 12),
                          _receiptRow(
                            context,
                            isDark,
                            label: l.amount,
                            value: widget.amount,
                            valueStyle: const TextStyle(
                                color: AppColors.primary,
                                fontSize: 22,
                                fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 12),
                          Divider(
                              color: isDark
                                  ? AppColors.slate700
                                  : AppColors.slate200),
                          const SizedBox(height: 12),
                          _receiptRow(
                            context,
                            isDark,
                            label: 'Tarih',
                            value: '17.03.2026 20:42',
                          ),
                          const SizedBox(height: 12),
                          _receiptRow(
                            context,
                            isDark,
                            label: 'Ref No',
                            value: 'AKC-20260317-8421',
                            valueStyle: const TextStyle(
                                color: AppColors.slate500,
                                fontSize: 12,
                                fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 32),

                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () {
                          Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const DashboardScreen()),
                            (route) => false,
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                          elevation: 3,
                          shadowColor: AppColors.primary.withOpacity(0.4),
                        ),
                        child: Text(l.backToHome,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600)),
                      ),
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

  Widget _receiptRow(BuildContext context, bool isDark,
      {required String label,
      required String value,
      TextStyle? valueStyle}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: const TextStyle(
                color: AppColors.slate500, fontSize: 13)),
        Text(value,
            style: valueStyle ??
                TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                    color: isDark ? Colors.white : AppColors.slate800)),
      ],
    );
  }
}
