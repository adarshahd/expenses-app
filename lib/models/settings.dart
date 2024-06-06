class Setting {
  late int id;
  late String key;
  late String value;
  String? description;
  String? createdAt;
  String? updatedAt;
  String? deletedAt;

  Setting(
      {required this.id,
      required this.key,
      required this.value,
      this.description,
      this.createdAt,
      this.updatedAt,
      this.deletedAt});

  Setting.fromJson(Map<String, dynamic> json) {
    id = json['id'];
    key = json['key'];
    value = json['value'];
    description = json['description'];
    createdAt = json['created_at'];
    updatedAt = json['updated_at'];
    deletedAt = json['deleted_at'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['id'] = id;
    data['key'] = key;
    data['value'] = value;
    data['description'] = description;
    data['created_at'] = createdAt;
    data['updated_at'] = updatedAt;
    data['deleted_at'] = deletedAt;
    return data;
  }
}
