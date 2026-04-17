// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'rating.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Rating _$RatingFromJson(Map<String, dynamic> json) => _Rating(
  id: safeIntOrNull(json['id']),
  deliveryId: safeInt(json['delivery_id']),
  courierId: safeIntOrNull(json['courier_id']),
  customerId: safeIntOrNull(json['customer_id']),
  rating: safeInt(json['rating']),
  comment: json['comment'] as String?,
  tags:
      (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  createdAt: json['created_at'] == null
      ? null
      : DateTime.parse(json['created_at'] as String),
);

Map<String, dynamic> _$RatingToJson(_Rating instance) => <String, dynamic>{
  'id': instance.id,
  'delivery_id': instance.deliveryId,
  'courier_id': instance.courierId,
  'customer_id': instance.customerId,
  'rating': instance.rating,
  'comment': instance.comment,
  'tags': instance.tags,
  'created_at': instance.createdAt?.toIso8601String(),
};

_RatingStats _$RatingStatsFromJson(Map<String, dynamic> json) => _RatingStats(
  averageRating: json['average_rating'] == null
      ? 0.0
      : safeDouble(json['average_rating']),
  totalRatings: json['total_ratings'] == null
      ? 0
      : safeInt(json['total_ratings']),
  distribution:
      (json['rating_distribution'] as List<dynamic>?)
          ?.map((e) => (e as num).toInt())
          .toList() ??
      const [0, 0, 0, 0, 0],
  positivePercentage: json['positive_percentage'] == null
      ? 0.0
      : safeDouble(json['positive_percentage']),
  topTags:
      (json['top_tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
);

Map<String, dynamic> _$RatingStatsToJson(_RatingStats instance) =>
    <String, dynamic>{
      'average_rating': instance.averageRating,
      'total_ratings': instance.totalRatings,
      'rating_distribution': instance.distribution,
      'positive_percentage': instance.positivePercentage,
      'top_tags': instance.topTags,
    };
