/// Modèle d'élément promotionnel pour la page d'accueil
class PromoItem {
  final String title;
  final String? description;
  final String? imageUrl;
  final String? actionUrl;
  final String? actionLabel;
  final String? badge;
  final String? subtitle;
  final List<int>? gradientColorValues;
  final String? actionType;

  const PromoItem({
    required this.title,
    this.description,
    this.imageUrl,
    this.actionUrl,
    this.actionLabel,
    this.badge,
    this.subtitle,
    this.gradientColorValues,
    this.actionType,
  });

  factory PromoItem.fromJson(Map<String, dynamic> json) {
    return PromoItem(
      title: json['title'] as String? ?? '',
      description: json['description'] as String?,
      imageUrl: json['image_url'] as String?,
      actionUrl: json['action_url'] as String?,
      actionLabel: json['action_label'] as String?,
      badge: json['badge'] as String?,
      subtitle: json['subtitle'] as String?,
      actionType: json['action_type'] as String?,
      gradientColorValues: (json['gradient_colors'] as List<dynamic>?)
          ?.map((e) => e as int)
          .toList(),
    );
  }
}
