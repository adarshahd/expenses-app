class AccountTransaction {
  late int id;
  late int accountId;
  String? title;
  String? description;
  late int total;
  late String type;
  late DateTime transactionTime;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  AccountTransaction(
      {required this.id,
      required this.accountId,
      required this.title,
      this.description,
      required this.total,
      required this.type,
      required this.transactionTime,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  AccountTransaction.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountId = json['account_id'];
    title = json['title'];
    description = json['description'];
    total = int.parse((json['total']).toString());
    type = json['type'];
    transactionTime = DateTime.parse(json['transaction_time']);
    createdAt = DateTime.tryParse(json['created_at']);
    updatedAt = DateTime.tryParse(json['updated_at']);
    deletedAt = DateTime.tryParse(json['deleted_at'] ?? '');
  }
}
