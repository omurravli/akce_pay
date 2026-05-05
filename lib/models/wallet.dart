class Wallet {
  final int walletId;
  final String ownerId;
  final String iban;
  final String walletType; // TL, USD, EUR, GOLD, SILVER
  final double balance;

  Wallet({
    required this.walletId,
    required this.ownerId,
    required this.iban,
    required this.walletType,
    required this.balance,
  });

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      walletId: json['wallet_id'],
      ownerId: json['owner_id']?.toString() ?? '',
      iban: json['iban'] ?? '',
      walletType: json['wallet_type'] ?? 'TL',
      balance: (json['balance'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'wallet_id': walletId,
      'owner_id': ownerId,
      'iban': iban,
      'wallet_type': walletType,
      'balance': balance,
    };
  }
}
