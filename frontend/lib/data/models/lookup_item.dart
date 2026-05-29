class LookupItemModel {
  final int id;
  final String name;

  const LookupItemModel({required this.id, required this.name});

  factory LookupItemModel.fromJson(Map<String, dynamic> json) {
    return LookupItemModel(
      id: json['id'] as int,
      name: json['name']?.toString() ?? '-',
    );
  }
}
