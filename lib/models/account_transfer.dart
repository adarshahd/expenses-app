class AccountTransfer {
  final int id;
  final int accountFrom;
  final int accountTo;
  final double total;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime deletedAt;

  AccountTransfer({
    required this.id,
    required this.accountFrom,
    required this.accountTo,
    required this.total,
    required this.createdAt,
    required this.updatedAt,
    required this.deletedAt
  });
}