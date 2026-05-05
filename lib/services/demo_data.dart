import '../models/asset.dart';
import '../models/user.dart';
import '../models/wallet.dart';

class DemoActivityEntry {
  final String type;
  final double amount;
  final bool isCredit;
  final DateTime createdAt;
  final String? assetSymbol;
  final String? note;

  const DemoActivityEntry({
    required this.type,
    required this.amount,
    required this.isCredit,
    required this.createdAt,
    this.assetSymbol,
    this.note,
  });
}

class DemoData {
  static const String demoEmail = 'demo@akcepay.local';
  static const String demoPassword = 'demo1234';
  static const String demoToken = 'LOCAL_DEMO_TOKEN';
  static List<Wallet> _wallets = _initialWallets();
  static List<PortfolioHolding> _holdings = [];
  static List<CashbackEntry> _cashbackEntries = [];
  static double _cashbackBalance = 0;
  static List<DemoActivityEntry> _activities = [];

  static User get demoUser => User(
        id: 'local-demo-user',
        username: 'Demo Kullanici',
        email: demoEmail,
        role: 'user',
      );

  static List<Wallet> _initialWallets() => [
        Wallet(
          walletId: 'demo-wallet-tl',
          ownerId: 'local-demo-user',
          iban: 'TR00 0000 0000 0000 0000 0000 01',
          walletType: 'TL',
          balance: 0,
        ),
      ];

  static void reset() {
    _wallets = _initialWallets();
    _holdings = [];
    _cashbackEntries = [];
    _cashbackBalance = 0;
    _activities = [];
  }

  static List<Wallet> get demoWallets => List<Wallet>.from(_wallets);

  static List<MarketRate> get demoMarketRates => [
        MarketRate(
          symbol: 'GOLD_GR',
          name: 'Gram Altin',
          buyPrice: 4280,
          sellPrice: 4305,
          changePercent: 0.42,
          updatedAt: DateTime.now(),
        ),
        MarketRate(
          symbol: 'SILVER_GR',
          name: 'Gumus (gr)',
          buyPrice: 52.1,
          sellPrice: 52.8,
          changePercent: -0.13,
          updatedAt: DateTime.now(),
        ),
        MarketRate(
          symbol: 'USD',
          name: 'Dolar',
          buyPrice: 38.55,
          sellPrice: 38.72,
          changePercent: 0.08,
          updatedAt: DateTime.now(),
        ),
        MarketRate(
          symbol: 'EUR',
          name: 'Euro',
          buyPrice: 42.05,
          sellPrice: 42.24,
          changePercent: 0.11,
          updatedAt: DateTime.now(),
        ),
      ];

  static List<PortfolioHolding> get demoHoldings =>
      List<PortfolioHolding>.from(_holdings);
  static List<CashbackEntry> get demoCashbackEntries =>
      List<CashbackEntry>.from(_cashbackEntries);
  static double get demoCashbackBalance => _cashbackBalance;
  static List<DemoActivityEntry> get demoActivities =>
      List<DemoActivityEntry>.from(_activities)
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

  static void setDemoWallets(List<Wallet> wallets) {
    _wallets = List<Wallet>.from(wallets);
  }

  static void setDemoHoldings(List<PortfolioHolding> holdings) {
    _holdings = List<PortfolioHolding>.from(holdings);
  }

  static void addDemoActivity(DemoActivityEntry entry) {
    _activities = [entry, ..._activities];
  }
}
