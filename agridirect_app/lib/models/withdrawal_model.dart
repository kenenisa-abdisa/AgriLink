class WithdrawalModel {
  final String id;
  final String farmerId;
  final double amount;
  final double fee;
  final double netAmount;
  final String method;
  final String? accountNumber;
  final String status;
  final DateTime createdAt;

  WithdrawalModel({
    required this.id,
    required this.farmerId,
    required this.amount,
    required this.fee,
    required this.netAmount,
    required this.method,
    this.accountNumber,
    required this.status,
    required this.createdAt,
  });

  factory WithdrawalModel.fromJson(Map<String, dynamic> json) {
    return WithdrawalModel(
      id: json['id'],
      farmerId: json['farmer_id'],
      amount: (json['amount'] as num).toDouble(),
      fee: (json['fee'] as num).toDouble(),
      netAmount: (json['net_amount'] as num).toDouble(),
      method: json['method'],
      accountNumber: json['account_number'],
      status: json['status'],
      createdAt: DateTime.parse(json['created_at']),
    );
  }
}
