class AppTransaction {
  final String transactionId;
  final String? senderId;
  final String? receiverId;
  final String? senderWalletId;
  final String? receiverWalletId;
  final double amount;
  final String? description;
  final String? type;
  final String? status;
  final DateTime date;

  AppTransaction({
    required this.transactionId,
    this.senderId,
    this.receiverId,
    this.senderWalletId,
    this.receiverWalletId,
    required this.amount,
    this.description,
    this.type,
    this.status,
    required this.date,
  });

  bool isCredit(String currentUserId) => receiverId == currentUserId;

  factory AppTransaction.fromJson(Map<String, dynamic> json) {
    return AppTransaction(
      transactionId: json['transaction_id']?.toString() ?? '',
      senderId: json['sender_id']?.toString(),
      receiverId: json['receiver_id']?.toString(),
      senderWalletId: json['sender_wallet_id']?.toString(),
      receiverWalletId: json['receiver_wallet_id']?.toString(),
      amount: (json['amount'] as num).toDouble(),
      description: json['description'],
      type: json['type'],
      status: json['status'],
      date: DateTime.parse(json['date']),
    );
  }
}
