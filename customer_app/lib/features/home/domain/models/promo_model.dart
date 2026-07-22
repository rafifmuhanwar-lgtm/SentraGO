class PromoModel {
  final String id;
  final String title;
  final String description;
  final String code;

  const PromoModel({
    required this.id,
    required this.title,
    required this.description,
    required this.code,
  });

  factory PromoModel.fromJson(Map<String, dynamic> json) {
    return PromoModel(
      id: json['\$id'] ?? json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}
