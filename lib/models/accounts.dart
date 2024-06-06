class Account {
  late int id;
  late String title;
  String? description;
  late bool active;
  String? icon;
  late double balance;
  late double initialBalance = 0;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  Account(
      {required this.id,
      required this.title,
      this.description,
      required this.active,
      this.icon,
      required this.balance,
      required this.initialBalance,
      required this.createdAt,
      required this.updatedAt,
      required this.deletedAt});

  Account.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    active = json['active'] == 1;
    icon = json['icon'];
    balance = double.parse(json['balance'].toString());
    initialBalance = double.parse(json['initial_balance'].toString());
    createdAt = DateTime.tryParse(json['created_at']);
    updatedAt = DateTime.tryParse(json['updated_at']);
    deletedAt = DateTime.tryParse(json['deleted_at'] ?? '');
  }
}
