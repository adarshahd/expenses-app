class TransactionFilterModel {
  late DateTime startDate;
  late DateTime endDate;
  late double minAmount;
  late double maxAmount;
  String? categories;
  String? type;

  TransactionFilterModel(
      {required this.startDate,
      required this.endDate,
      required this.minAmount,
      required this.maxAmount,
      this.categories,
      this.type});

  TransactionFilterModel.fromJson(Map<String, dynamic> json) {
    startDate = DateTime.tryParse(json['start_date'])!;
    endDate = DateTime.tryParse(json['end_date'])!;
    minAmount = json['min_amount'];
    maxAmount = json['max_amount'];
    categories = json['categories'];
    type = json['type'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['start_date'] = startDate;
    data['end_date'] = endDate;
    data['min_amount'] = minAmount;
    data['max_amount'] = maxAmount;
    data['categories'] = categories;
    data['type'] = type;
    return data;
  }
}
