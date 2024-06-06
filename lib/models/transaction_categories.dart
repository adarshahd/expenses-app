class TransactionCategory {
  late int id;
  late int accountTransactionId;
  late int categoryId;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  TransactionCategory(
      {required this.id,
      required this.accountTransactionId,
      required this.categoryId,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  TransactionCategory.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    accountTransactionId = json['account_transaction_id'];
    categoryId = json['category_id'];
    createdAt = DateTime.tryParse(json['created_at']);
    updatedAt = DateTime.tryParse(json['updated_at']);
    deletedAt = DateTime.tryParse(json['deleted_at'] ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['account_transaction_id'] = accountTransactionId;
    data['category_id'] = categoryId;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
