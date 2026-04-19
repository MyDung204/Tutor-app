class Badge {
  final int id;
  final String name;
  final String slug;
  final String? iconUrl;
  final String? description;
  final String? colorHex;

  Badge({
    required this.id,
    required this.name,
    required this.slug,
    this.iconUrl,
    this.description,
    this.colorHex,
  });

  factory Badge.fromJson(Map<String, dynamic> json) {
    return Badge(
      id: json['id'] as int,
      name: json['name'] as String,
      slug: json['slug'] as String,
      iconUrl: json['icon_url'] as String?,
      description: json['description'] as String?,
      colorHex: json['color_hex'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'slug': slug,
      'icon_url': iconUrl,
      'description': description,
      'color_hex': colorHex,
    };
  }
}
