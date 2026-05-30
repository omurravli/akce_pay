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

class DemoNewsEntry {
  final String title;
  final String source;
  final String time;
  final String summary;

  const DemoNewsEntry({
    required this.title,
    required this.source,
    required this.time,
    required this.summary,
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

  static List<DemoNewsEntry> get demoNews => [
    const DemoNewsEntry(
      title: 'Borsa İstanbul haftaya yükselişle başladı',
      source: 'Akçe Haber',
      time: '1 saat önce',
      summary: 'BIST 100 endeksi, güne %0,42 artışla 9.200 puandan başladı. Teknoloji hisselerindeki hareketlilik dikkat çekiyor.',
    ),
    const DemoNewsEntry(
      title: 'Altın fiyatlarında yeni rekor beklentisi',
      source: 'Finans Dünyası',
      time: '3 saat önce',
      summary: 'Ons altındaki küresel yükseliş, gram altını tetiklemeye devam ediyor. Analistler 4500 TL seviyesini işaret ediyor.',
    ),
    const DemoNewsEntry(
      title: 'Merkez Bankası faiz kararı açıklandı',
      source: 'Ekonomi Gazetesi',
      time: '5 saat önce',
      summary: 'Para Politikası Kurulu, politika faizini beklentiler dahilinde sabit bıraktı. Karar sonrası dolar/TL kurunda sakin seyir izleniyor.',
    ),
    const DemoNewsEntry(
      title: 'THY bilançosunda dev kâr açıkladı',
      source: 'Borsa Gündem',
      time: 'Dün',
      summary: 'Türk Hava Yolları, yılın üçüncü çeyreğinde beklentilerin üzerinde net kâr elde ettiğini duyurdu.',
    ),
  ];

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
