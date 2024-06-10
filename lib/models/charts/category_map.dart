class CategoryMap {
  String? title;
  int? total;
  int? percent;
  int? color;

  CategoryMap({this.title, this.total, this.percent, this.color});

  CategoryMap.fromJson(Map<String, dynamic> json) {
    title = json['title'];
    total = json['total'];
    percent = json['percent'];
    color = json['color'];
  }

  Map<String, dynamic> toJson() {
    final Map<String, dynamic> data = <String, dynamic>{};
    data['title'] = title;
    data['total'] = total;
    data['percent'] = percent;
    data['color'] = color;
    return data;
  }
}
