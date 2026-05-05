/// Bir varlık türü (altın, gümüş, döviz vs.) için piyasa kuru bilgisi.
/// Backend `/api/market/rates` endpoint'i bu yapıda dönecek.
class MarketRate {
  final String symbol; // 'GOLD_GR', 'SILVER_GR', 'USD', 'EUR' vs.
  final String name; // 'Gram Altın', 'Gümüş', 'Dolar' ...
  final double buyPrice; // TL cinsinden alış
  final double sellPrice; // TL cinsinden satış
  final double changePercent; // 24s değişim %
  final DateTime updatedAt;

  MarketRate({
    required this.symbol,
    required this.name,
    required this.buyPrice,
    required this.sellPrice,
    required this.changePercent,
    required this.updatedAt,
  });

  double get midPrice => (buyPrice + sellPrice) / 2;
  bool get isUp => changePercent >= 0;

  factory MarketRate.fromJson(Map<String, dynamic> json) {
    return MarketRate(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      buyPrice: (json['buy_price'] as num).toDouble(),
      sellPrice: (json['sell_price'] as num).toDouble(),
      changePercent: (json['change_percent'] as num?)?.toDouble() ?? 0,
      updatedAt: DateTime.tryParse(json['updated_at'] ?? '') ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
        'symbol': symbol,
        'name': name,
        'buy_price': buyPrice,
        'sell_price': sellPrice,
        'change_percent': changePercent,
        'updated_at': updatedAt.toIso8601String(),
      };
}

/// Kullanıcının portföyündeki bir holding (sahip olduğu varlık).
/// Backend `/api/portfolio/holdings` endpoint'i bu yapıda dönecek.
class PortfolioHolding {
  final String symbol; // 'GOLD_GR', 'SILVER_GR' ...
  final String name;
  final double quantity; // miktar (gram, adet vs.)
  final double averageCost; // ortalama alış (birim başı, TL)
  final double currentPrice; // güncel piyasa fiyatı (birim başı, TL)

  PortfolioHolding({
    required this.symbol,
    required this.name,
    required this.quantity,
    required this.averageCost,
    required this.currentPrice,
  });

  double get marketValue => quantity * currentPrice;
  double get costBasis => quantity * averageCost;
  double get profitLoss => marketValue - costBasis;
  double get profitLossPercent =>
      costBasis == 0 ? 0 : (profitLoss / costBasis) * 100;

  factory PortfolioHolding.fromJson(Map<String, dynamic> json) {
    return PortfolioHolding(
      symbol: json['symbol'] ?? '',
      name: json['name'] ?? '',
      quantity: (json['quantity'] as num).toDouble(),
      averageCost: (json['average_cost'] as num).toDouble(),
      currentPrice: (json['current_price'] as num).toDouble(),
    );
  }
}

/// Cashback giriş kaydı.
/// Backend `/api/cashback/entries` endpoint'i bu yapıda dönecek.
class CashbackEntry {
  final int id;
  final String description;
  final String category; // 'shopping', 'bills', 'transfer', 'trade'
  final double spentAmount; // harcanan tutar
  final double cashbackAmount; // kazanılan cashback
  final double rate; // 0.01 = %1
  final DateTime createdAt;

  CashbackEntry({
    required this.id,
    required this.description,
    required this.category,
    required this.spentAmount,
    required this.cashbackAmount,
    required this.rate,
    required this.createdAt,
  });

  factory CashbackEntry.fromJson(Map<String, dynamic> json) {
    return CashbackEntry(
      id: json['id'] ?? 0,
      description: json['description'] ?? '',
      category: json['category'] ?? 'shopping',
      spentAmount: (json['spent_amount'] as num).toDouble(),
      cashbackAmount: (json['cashback_amount'] as num).toDouble(),
      rate: (json['rate'] as num).toDouble(),
      createdAt: DateTime.tryParse(json['created_at'] ?? '') ?? DateTime.now(),
    );
  }
}

/// Admin panelinde gösterilecek özet metrikler.
/// Backend `/api/admin/stats` endpoint'i bu yapıda dönecek.
class AdminStats {
  final int totalUsers;
  final int activeUsers;
  final double totalVolume;
  final int totalTransactions;
  final double totalCashbackPaid;

  AdminStats({
    required this.totalUsers,
    required this.activeUsers,
    required this.totalVolume,
    required this.totalTransactions,
    required this.totalCashbackPaid,
  });

  factory AdminStats.fromJson(Map<String, dynamic> json) {
    return AdminStats(
      totalUsers: json['total_users'] ?? 0,
      activeUsers: json['active_users'] ?? 0,
      totalVolume: (json['total_volume'] as num?)?.toDouble() ?? 0,
      totalTransactions: json['total_transactions'] ?? 0,
      totalCashbackPaid:
          (json['total_cashback_paid'] as num?)?.toDouble() ?? 0,
    );
  }
}

class AdminUserSummary {
  final String id;
  final String username;
  final String email;
  final String role;
  final double totalBalance;
  final bool isActive;

  const AdminUserSummary({
    required this.id,
    required this.username,
    required this.email,
    required this.role,
    required this.totalBalance,
    required this.isActive,
  });

  factory AdminUserSummary.fromJson(Map<String, dynamic> json) {
    return AdminUserSummary(
      id: json['id']?.toString() ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'user',
      totalBalance: (json['total_balance'] as num?)?.toDouble() ?? 0,
      isActive: json['is_active'] ?? true,
    );
  }
}
