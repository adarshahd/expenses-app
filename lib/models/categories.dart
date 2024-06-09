class Category {
  late int id;
  late String title;
  String? description;
  DateTime? createdAt;
  DateTime? updatedAt;
  DateTime? deletedAt;

  Category(
      {required this.id,
      required this.title,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  Category.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    title = json['title'];
    description = json['description'];
    createdAt = DateTime.tryParse(json['created_at']);
    updatedAt = DateTime.tryParse(json['updated_at']);
    deletedAt = DateTime.tryParse(json['deleted_at'] ?? '');
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['title'] = title;
    data['description'] = description;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }

  @override
  bool operator ==(Object other) {
    return other is Category && id == other.id;
  }

  @override
  int get hashCode => id.hashCode;
}
