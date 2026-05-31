import 'package:flutter/material.dart';
import '../l10n/app_localizations.dart';
import '../theme.dart';
import 'trading_screen.dart';
import 'send_money_screen.dart';
import 'pay_bills_screen.dart';
import 'portfolio_screen.dart';
import 'activity_screen.dart';

class ChatBottomSheet extends StatefulWidget {
  const ChatBottomSheet({super.key});

  @override
  State<ChatBottomSheet> createState() => _ChatBottomSheetState();
}

class _ChatBottomSheetState extends State<ChatBottomSheet> {
  final List<Map<String, dynamic>> _messages = [];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Pending navigation for affirmative confirmation
  String? _pendingRoute;
  String? _pendingLabel;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        final l = AppLocalizations.of(context);
        _addBotMessage(l.chatWelcome);
      }
    });
  }

  void _addBotMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add({'isUser': false, 'text': text});
    });
    _scrollToBottom();
  }

  void _addUserMessage(String text) {
    if (!mounted) return;
    setState(() {
      _messages.add({'isUser': true, 'text': text});
    });
    _scrollToBottom();
  }

  void _handleUserMessage(String text) {
    final trimmedText = text.trim();
    if (trimmedText.isEmpty) return;

    final input = trimmedText.toLowerCase();
    _addUserMessage(trimmedText);
    _controller.clear();

    Future.delayed(const Duration(milliseconds: 600), () {
      if (!mounted) return;
      final l = AppLocalizations.of(context);

      // Onay kelimeleri kontrolü
      final isAffirmative = input == 'evet' || 
                           input == 'yes' || 
                           input == 'ok' || 
                           input == 'tamam' || 
                           input == 'olur';

      if (isAffirmative && _pendingRoute != null) {
        final route = _pendingRoute!;
        final label = _pendingLabel!;
        _pendingRoute = null;
        _pendingLabel = null;
        _handleNavigation(route, label, confirmedByText: true);
        return;
      }

      // Her yeni mesajda eski bekleyen işlemi temizle
      _pendingRoute = null;
      _pendingLabel = null;

      // Akıllı anahtar kelime eşleştirme ve öneri hazırlama
      if (input.contains('borsa') || input.contains('market') || input.contains('hisse') || input.contains('kur') || input.contains('piyasa')) {
        _pendingRoute = 'market';
        _pendingLabel = l.chatGoToMarket;
        _addBotMessage(l.chatDidYouMean(l.chatGoToMarket));
      } else if (input.contains('haber') || input.contains('news') || input.contains('gündem')) {
        _pendingRoute = 'news';
        _pendingLabel = l.chatGoToNews;
        _addBotMessage(l.chatDidYouMean(l.chatGoToNews));
      } else if (input.contains('gönder') || input.contains('transfer') || input.contains('send') || (input.contains('para') && !input.contains('yükle'))) {
        _pendingRoute = 'send';
        _pendingLabel = l.chatGoToTransfer;
        _addBotMessage(l.chatDidYouMean(l.chatGoToTransfer));
      } else if (input.contains('fatura') || input.contains('bill') || input.contains('öde')) {
        _pendingRoute = 'bills';
        _pendingLabel = l.chatGoToBills;
        _addBotMessage(l.chatDidYouMean(l.chatGoToBills));
      } else if (input.contains('portf') || input.contains('varlık') || input.contains('holding')) {
        _pendingRoute = 'portfolio';
        _pendingLabel = l.chatGoToPortfolio;
        _addBotMessage(l.chatDidYouMean(l.chatGoToPortfolio));
      } else if (input.contains('geçmiş') || input.contains('aktivite') || input.contains('hareket') || input.contains('history') || input.contains('işlem')) {
        _pendingRoute = 'activity';
        _pendingLabel = l.chatGoToActivity;
        _addBotMessage(l.chatDidYouMean(l.chatGoToActivity));
      } else {
        _addBotMessage(l.chatUnknown);
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 100), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _handleNavigation(String route, String label, {bool confirmedByText = false}) {
    if (confirmedByText) {
      final l = AppLocalizations.of(context);
      _addBotMessage(l.isTr ? "Tamam, hemen yönlendiriyorum..." : "Okay, redirecting you now...");
    } else {
      _addUserMessage(label);
    }
    
    Future.delayed(const Duration(milliseconds: 800), () {
      if (!mounted) return;
      Navigator.pop(context); // Close chat sheet
      
      Widget destination;
      switch (route) {
        case 'market':
          destination = const TradingScreen();
          break;
        case 'news':
          destination = const TradingScreen(initialTab: 3);
          break;
        case 'send':
          destination = const SendMoneyScreen();
          break;
        case 'bills':
          destination = const PayBillsScreen();
          break;
        case 'portfolio':
          destination = const PortfolioScreen();
          break;
        case 'activity':
          destination = const ActivityScreen();
          break;
        default:
          return;
      }
      
      Navigator.push(context, MaterialPageRoute(builder: (_) => destination));
    });
  }

  @override
  Widget build(BuildContext context) {
    final l = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      height: MediaQuery.of(context).size.height * 0.75,
      padding: EdgeInsets.only(bottom: bottomInset),
      decoration: BoxDecoration(
        color: isDark ? AppColors.backgroundDark : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          Container(
            margin: const EdgeInsets.symmetric(vertical: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.slate300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                const CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: Icon(Icons.smart_toy_rounded, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Text(
                  l.akceChat,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length,
              itemBuilder: (context, index) {
                final msg = _messages[index];
                final isUser = msg['isUser'] == true;
                final text = (msg['text'] ?? '').toString();
                return Align(
                  alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
                  child: Container(
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                    decoration: BoxDecoration(
                      color: isUser 
                          ? AppColors.primary 
                          : (isDark ? AppColors.slate800 : AppColors.slate100),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16),
                        topRight: const Radius.circular(16),
                        bottomLeft: Radius.circular(isUser ? 16 : 0),
                        bottomRight: Radius.circular(isUser ? 0 : 16),
                      ),
                    ),
                    child: Text(
                      text,
                      style: TextStyle(
                        color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: Row(
              children: [
                _buildQuickAction(l.chatGoToNews, () => _handleNavigation('news', l.chatGoToNews)),
                _buildQuickAction(l.chatGoToMarket, () => _handleNavigation('market', l.chatGoToMarket)),
                _buildQuickAction(l.chatGoToTransfer, () => _handleNavigation('send', l.chatGoToTransfer)),
                _buildQuickAction(l.chatGoToBills, () => _handleNavigation('bills', l.chatGoToBills)),
                _buildQuickAction(l.chatGoToPortfolio, () => _handleNavigation('portfolio', l.chatGoToPortfolio)),
                _buildQuickAction(l.chatGoToActivity, () => _handleNavigation('activity', l.chatGoToActivity)),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _controller,
                    decoration: InputDecoration(
                      hintText: l.chatHint,
                      filled: true,
                      fillColor: isDark ? AppColors.slate800 : AppColors.slate100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(24),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: _handleUserMessage,
                  ),
                ),
                const SizedBox(width: 8),
                CircleAvatar(
                  backgroundColor: AppColors.primary,
                  child: IconButton(
                    icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                    onPressed: () => _handleUserMessage(_controller.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickAction(String label, VoidCallback onTap) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: ActionChip(
        label: Text(label, style: const TextStyle(fontSize: 12)),
        onPressed: onTap,
        backgroundColor: isDark ? AppColors.slate800 : Colors.white,
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
    );
  }
}
