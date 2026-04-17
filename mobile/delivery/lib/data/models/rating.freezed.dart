// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'rating.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Rating {

/// ID unique de l'évaluation
@JsonKey(fromJson: safeIntOrNull) int? get id;/// ID de la livraison associée
@JsonKey(name: 'delivery_id', fromJson: safeInt) int get deliveryId;/// ID du coursier qui évalue
@JsonKey(name: 'courier_id', fromJson: safeIntOrNull) int? get courierId;/// ID du client évalué
@JsonKey(name: 'customer_id', fromJson: safeIntOrNull) int? get customerId;/// Note de 1 à 5 étoiles
@JsonKey(fromJson: safeInt) int get rating;/// Commentaire optionnel
 String? get comment;/// Tags sélectionnés (positifs ou négatifs)
 List<String> get tags;/// Date de création
@JsonKey(name: 'created_at') DateTime? get createdAt;
/// Create a copy of Rating
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RatingCopyWith<Rating> get copyWith => _$RatingCopyWithImpl<Rating>(this as Rating, _$identity);

  /// Serializes this Rating to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Rating&&(identical(other.id, id) || other.id == id)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.courierId, courierId) || other.courierId == courierId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&const DeepCollectionEquality().equals(other.tags, tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deliveryId,courierId,customerId,rating,comment,const DeepCollectionEquality().hash(tags),createdAt);

@override
String toString() {
  return 'Rating(id: $id, deliveryId: $deliveryId, courierId: $courierId, customerId: $customerId, rating: $rating, comment: $comment, tags: $tags, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $RatingCopyWith<$Res>  {
  factory $RatingCopyWith(Rating value, $Res Function(Rating) _then) = _$RatingCopyWithImpl;
@useResult
$Res call({
@JsonKey(fromJson: safeIntOrNull) int? id,@JsonKey(name: 'delivery_id', fromJson: safeInt) int deliveryId,@JsonKey(name: 'courier_id', fromJson: safeIntOrNull) int? courierId,@JsonKey(name: 'customer_id', fromJson: safeIntOrNull) int? customerId,@JsonKey(fromJson: safeInt) int rating, String? comment, List<String> tags,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class _$RatingCopyWithImpl<$Res>
    implements $RatingCopyWith<$Res> {
  _$RatingCopyWithImpl(this._self, this._then);

  final Rating _self;
  final $Res Function(Rating) _then;

/// Create a copy of Rating
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = freezed,Object? deliveryId = null,Object? courierId = freezed,Object? customerId = freezed,Object? rating = null,Object? comment = freezed,Object? tags = null,Object? createdAt = freezed,}) {
  return _then(_self.copyWith(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as int,courierId: freezed == courierId ? _self.courierId : courierId // ignore: cast_nullable_to_non_nullable
as int?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self.tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}

}


/// Adds pattern-matching-related methods to [Rating].
extension RatingPatterns on Rating {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Rating value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Rating() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Rating value)  $default,){
final _that = this;
switch (_that) {
case _Rating():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Rating value)?  $default,){
final _that = this;
switch (_that) {
case _Rating() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeIntOrNull)  int? id, @JsonKey(name: 'delivery_id', fromJson: safeInt)  int deliveryId, @JsonKey(name: 'courier_id', fromJson: safeIntOrNull)  int? courierId, @JsonKey(name: 'customer_id', fromJson: safeIntOrNull)  int? customerId, @JsonKey(fromJson: safeInt)  int rating,  String? comment,  List<String> tags, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Rating() when $default != null:
return $default(_that.id,_that.deliveryId,_that.courierId,_that.customerId,_that.rating,_that.comment,_that.tags,_that.createdAt);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(fromJson: safeIntOrNull)  int? id, @JsonKey(name: 'delivery_id', fromJson: safeInt)  int deliveryId, @JsonKey(name: 'courier_id', fromJson: safeIntOrNull)  int? courierId, @JsonKey(name: 'customer_id', fromJson: safeIntOrNull)  int? customerId, @JsonKey(fromJson: safeInt)  int rating,  String? comment,  List<String> tags, @JsonKey(name: 'created_at')  DateTime? createdAt)  $default,) {final _that = this;
switch (_that) {
case _Rating():
return $default(_that.id,_that.deliveryId,_that.courierId,_that.customerId,_that.rating,_that.comment,_that.tags,_that.createdAt);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(fromJson: safeIntOrNull)  int? id, @JsonKey(name: 'delivery_id', fromJson: safeInt)  int deliveryId, @JsonKey(name: 'courier_id', fromJson: safeIntOrNull)  int? courierId, @JsonKey(name: 'customer_id', fromJson: safeIntOrNull)  int? customerId, @JsonKey(fromJson: safeInt)  int rating,  String? comment,  List<String> tags, @JsonKey(name: 'created_at')  DateTime? createdAt)?  $default,) {final _that = this;
switch (_that) {
case _Rating() when $default != null:
return $default(_that.id,_that.deliveryId,_that.courierId,_that.customerId,_that.rating,_that.comment,_that.tags,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Rating extends Rating {
  const _Rating({@JsonKey(fromJson: safeIntOrNull) this.id, @JsonKey(name: 'delivery_id', fromJson: safeInt) required this.deliveryId, @JsonKey(name: 'courier_id', fromJson: safeIntOrNull) this.courierId, @JsonKey(name: 'customer_id', fromJson: safeIntOrNull) this.customerId, @JsonKey(fromJson: safeInt) required this.rating, this.comment, final  List<String> tags = const [], @JsonKey(name: 'created_at') this.createdAt}): _tags = tags,super._();
  factory _Rating.fromJson(Map<String, dynamic> json) => _$RatingFromJson(json);

/// ID unique de l'évaluation
@override@JsonKey(fromJson: safeIntOrNull) final  int? id;
/// ID de la livraison associée
@override@JsonKey(name: 'delivery_id', fromJson: safeInt) final  int deliveryId;
/// ID du coursier qui évalue
@override@JsonKey(name: 'courier_id', fromJson: safeIntOrNull) final  int? courierId;
/// ID du client évalué
@override@JsonKey(name: 'customer_id', fromJson: safeIntOrNull) final  int? customerId;
/// Note de 1 à 5 étoiles
@override@JsonKey(fromJson: safeInt) final  int rating;
/// Commentaire optionnel
@override final  String? comment;
/// Tags sélectionnés (positifs ou négatifs)
 final  List<String> _tags;
/// Tags sélectionnés (positifs ou négatifs)
@override@JsonKey() List<String> get tags {
  if (_tags is EqualUnmodifiableListView) return _tags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_tags);
}

/// Date de création
@override@JsonKey(name: 'created_at') final  DateTime? createdAt;

/// Create a copy of Rating
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RatingCopyWith<_Rating> get copyWith => __$RatingCopyWithImpl<_Rating>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RatingToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Rating&&(identical(other.id, id) || other.id == id)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.courierId, courierId) || other.courierId == courierId)&&(identical(other.customerId, customerId) || other.customerId == customerId)&&(identical(other.rating, rating) || other.rating == rating)&&(identical(other.comment, comment) || other.comment == comment)&&const DeepCollectionEquality().equals(other._tags, _tags)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,deliveryId,courierId,customerId,rating,comment,const DeepCollectionEquality().hash(_tags),createdAt);

@override
String toString() {
  return 'Rating(id: $id, deliveryId: $deliveryId, courierId: $courierId, customerId: $customerId, rating: $rating, comment: $comment, tags: $tags, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$RatingCopyWith<$Res> implements $RatingCopyWith<$Res> {
  factory _$RatingCopyWith(_Rating value, $Res Function(_Rating) _then) = __$RatingCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(fromJson: safeIntOrNull) int? id,@JsonKey(name: 'delivery_id', fromJson: safeInt) int deliveryId,@JsonKey(name: 'courier_id', fromJson: safeIntOrNull) int? courierId,@JsonKey(name: 'customer_id', fromJson: safeIntOrNull) int? customerId,@JsonKey(fromJson: safeInt) int rating, String? comment, List<String> tags,@JsonKey(name: 'created_at') DateTime? createdAt
});




}
/// @nodoc
class __$RatingCopyWithImpl<$Res>
    implements _$RatingCopyWith<$Res> {
  __$RatingCopyWithImpl(this._self, this._then);

  final _Rating _self;
  final $Res Function(_Rating) _then;

/// Create a copy of Rating
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = freezed,Object? deliveryId = null,Object? courierId = freezed,Object? customerId = freezed,Object? rating = null,Object? comment = freezed,Object? tags = null,Object? createdAt = freezed,}) {
  return _then(_Rating(
id: freezed == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int?,deliveryId: null == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as int,courierId: freezed == courierId ? _self.courierId : courierId // ignore: cast_nullable_to_non_nullable
as int?,customerId: freezed == customerId ? _self.customerId : customerId // ignore: cast_nullable_to_non_nullable
as int?,rating: null == rating ? _self.rating : rating // ignore: cast_nullable_to_non_nullable
as int,comment: freezed == comment ? _self.comment : comment // ignore: cast_nullable_to_non_nullable
as String?,tags: null == tags ? _self._tags : tags // ignore: cast_nullable_to_non_nullable
as List<String>,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime?,
  ));
}


}


/// @nodoc
mixin _$RatingStats {

/// Note moyenne (1.0 - 5.0)
@JsonKey(name: 'average_rating', fromJson: safeDouble) double get averageRating;/// Nombre total d'évaluations reçues
@JsonKey(name: 'total_ratings', fromJson: safeInt) int get totalRatings;/// Répartition par note (index 0 = 1 étoile, index 4 = 5 étoiles)
@JsonKey(name: 'rating_distribution') List<int> get distribution;/// Pourcentage d'évaluations positives (>= 4 étoiles)
@JsonKey(name: 'positive_percentage', fromJson: safeDouble) double get positivePercentage;/// Tags les plus fréquents
@JsonKey(name: 'top_tags') List<String> get topTags;
/// Create a copy of RatingStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RatingStatsCopyWith<RatingStats> get copyWith => _$RatingStatsCopyWithImpl<RatingStats>(this as RatingStats, _$identity);

  /// Serializes this RatingStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RatingStats&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.totalRatings, totalRatings) || other.totalRatings == totalRatings)&&const DeepCollectionEquality().equals(other.distribution, distribution)&&(identical(other.positivePercentage, positivePercentage) || other.positivePercentage == positivePercentage)&&const DeepCollectionEquality().equals(other.topTags, topTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,averageRating,totalRatings,const DeepCollectionEquality().hash(distribution),positivePercentage,const DeepCollectionEquality().hash(topTags));

@override
String toString() {
  return 'RatingStats(averageRating: $averageRating, totalRatings: $totalRatings, distribution: $distribution, positivePercentage: $positivePercentage, topTags: $topTags)';
}


}

/// @nodoc
abstract mixin class $RatingStatsCopyWith<$Res>  {
  factory $RatingStatsCopyWith(RatingStats value, $Res Function(RatingStats) _then) = _$RatingStatsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'average_rating', fromJson: safeDouble) double averageRating,@JsonKey(name: 'total_ratings', fromJson: safeInt) int totalRatings,@JsonKey(name: 'rating_distribution') List<int> distribution,@JsonKey(name: 'positive_percentage', fromJson: safeDouble) double positivePercentage,@JsonKey(name: 'top_tags') List<String> topTags
});




}
/// @nodoc
class _$RatingStatsCopyWithImpl<$Res>
    implements $RatingStatsCopyWith<$Res> {
  _$RatingStatsCopyWithImpl(this._self, this._then);

  final RatingStats _self;
  final $Res Function(RatingStats) _then;

/// Create a copy of RatingStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? averageRating = null,Object? totalRatings = null,Object? distribution = null,Object? positivePercentage = null,Object? topTags = null,}) {
  return _then(_self.copyWith(
averageRating: null == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double,totalRatings: null == totalRatings ? _self.totalRatings : totalRatings // ignore: cast_nullable_to_non_nullable
as int,distribution: null == distribution ? _self.distribution : distribution // ignore: cast_nullable_to_non_nullable
as List<int>,positivePercentage: null == positivePercentage ? _self.positivePercentage : positivePercentage // ignore: cast_nullable_to_non_nullable
as double,topTags: null == topTags ? _self.topTags : topTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}

}


/// Adds pattern-matching-related methods to [RatingStats].
extension RatingStatsPatterns on RatingStats {
/// A variant of `map` that fallback to returning `orElse`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RatingStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RatingStats() when $default != null:
return $default(_that);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// Callbacks receives the raw object, upcasted.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case final Subclass2 value:
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RatingStats value)  $default,){
final _that = this;
switch (_that) {
case _RatingStats():
return $default(_that);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `map` that fallback to returning `null`.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case final Subclass value:
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RatingStats value)?  $default,){
final _that = this;
switch (_that) {
case _RatingStats() when $default != null:
return $default(_that);case _:
  return null;

}
}
/// A variant of `when` that fallback to an `orElse` callback.
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return orElse();
/// }
/// ```

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'average_rating', fromJson: safeDouble)  double averageRating, @JsonKey(name: 'total_ratings', fromJson: safeInt)  int totalRatings, @JsonKey(name: 'rating_distribution')  List<int> distribution, @JsonKey(name: 'positive_percentage', fromJson: safeDouble)  double positivePercentage, @JsonKey(name: 'top_tags')  List<String> topTags)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RatingStats() when $default != null:
return $default(_that.averageRating,_that.totalRatings,_that.distribution,_that.positivePercentage,_that.topTags);case _:
  return orElse();

}
}
/// A `switch`-like method, using callbacks.
///
/// As opposed to `map`, this offers destructuring.
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case Subclass2(:final field2):
///     return ...;
/// }
/// ```

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'average_rating', fromJson: safeDouble)  double averageRating, @JsonKey(name: 'total_ratings', fromJson: safeInt)  int totalRatings, @JsonKey(name: 'rating_distribution')  List<int> distribution, @JsonKey(name: 'positive_percentage', fromJson: safeDouble)  double positivePercentage, @JsonKey(name: 'top_tags')  List<String> topTags)  $default,) {final _that = this;
switch (_that) {
case _RatingStats():
return $default(_that.averageRating,_that.totalRatings,_that.distribution,_that.positivePercentage,_that.topTags);case _:
  throw StateError('Unexpected subclass');

}
}
/// A variant of `when` that fallback to returning `null`
///
/// It is equivalent to doing:
/// ```dart
/// switch (sealedClass) {
///   case Subclass(:final field):
///     return ...;
///   case _:
///     return null;
/// }
/// ```

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'average_rating', fromJson: safeDouble)  double averageRating, @JsonKey(name: 'total_ratings', fromJson: safeInt)  int totalRatings, @JsonKey(name: 'rating_distribution')  List<int> distribution, @JsonKey(name: 'positive_percentage', fromJson: safeDouble)  double positivePercentage, @JsonKey(name: 'top_tags')  List<String> topTags)?  $default,) {final _that = this;
switch (_that) {
case _RatingStats() when $default != null:
return $default(_that.averageRating,_that.totalRatings,_that.distribution,_that.positivePercentage,_that.topTags);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _RatingStats implements RatingStats {
  const _RatingStats({@JsonKey(name: 'average_rating', fromJson: safeDouble) this.averageRating = 0.0, @JsonKey(name: 'total_ratings', fromJson: safeInt) this.totalRatings = 0, @JsonKey(name: 'rating_distribution') final  List<int> distribution = const [0, 0, 0, 0, 0], @JsonKey(name: 'positive_percentage', fromJson: safeDouble) this.positivePercentage = 0.0, @JsonKey(name: 'top_tags') final  List<String> topTags = const []}): _distribution = distribution,_topTags = topTags;
  factory _RatingStats.fromJson(Map<String, dynamic> json) => _$RatingStatsFromJson(json);

/// Note moyenne (1.0 - 5.0)
@override@JsonKey(name: 'average_rating', fromJson: safeDouble) final  double averageRating;
/// Nombre total d'évaluations reçues
@override@JsonKey(name: 'total_ratings', fromJson: safeInt) final  int totalRatings;
/// Répartition par note (index 0 = 1 étoile, index 4 = 5 étoiles)
 final  List<int> _distribution;
/// Répartition par note (index 0 = 1 étoile, index 4 = 5 étoiles)
@override@JsonKey(name: 'rating_distribution') List<int> get distribution {
  if (_distribution is EqualUnmodifiableListView) return _distribution;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_distribution);
}

/// Pourcentage d'évaluations positives (>= 4 étoiles)
@override@JsonKey(name: 'positive_percentage', fromJson: safeDouble) final  double positivePercentage;
/// Tags les plus fréquents
 final  List<String> _topTags;
/// Tags les plus fréquents
@override@JsonKey(name: 'top_tags') List<String> get topTags {
  if (_topTags is EqualUnmodifiableListView) return _topTags;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_topTags);
}


/// Create a copy of RatingStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RatingStatsCopyWith<_RatingStats> get copyWith => __$RatingStatsCopyWithImpl<_RatingStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$RatingStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RatingStats&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.totalRatings, totalRatings) || other.totalRatings == totalRatings)&&const DeepCollectionEquality().equals(other._distribution, _distribution)&&(identical(other.positivePercentage, positivePercentage) || other.positivePercentage == positivePercentage)&&const DeepCollectionEquality().equals(other._topTags, _topTags));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,averageRating,totalRatings,const DeepCollectionEquality().hash(_distribution),positivePercentage,const DeepCollectionEquality().hash(_topTags));

@override
String toString() {
  return 'RatingStats(averageRating: $averageRating, totalRatings: $totalRatings, distribution: $distribution, positivePercentage: $positivePercentage, topTags: $topTags)';
}


}

/// @nodoc
abstract mixin class _$RatingStatsCopyWith<$Res> implements $RatingStatsCopyWith<$Res> {
  factory _$RatingStatsCopyWith(_RatingStats value, $Res Function(_RatingStats) _then) = __$RatingStatsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'average_rating', fromJson: safeDouble) double averageRating,@JsonKey(name: 'total_ratings', fromJson: safeInt) int totalRatings,@JsonKey(name: 'rating_distribution') List<int> distribution,@JsonKey(name: 'positive_percentage', fromJson: safeDouble) double positivePercentage,@JsonKey(name: 'top_tags') List<String> topTags
});




}
/// @nodoc
class __$RatingStatsCopyWithImpl<$Res>
    implements _$RatingStatsCopyWith<$Res> {
  __$RatingStatsCopyWithImpl(this._self, this._then);

  final _RatingStats _self;
  final $Res Function(_RatingStats) _then;

/// Create a copy of RatingStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? averageRating = null,Object? totalRatings = null,Object? distribution = null,Object? positivePercentage = null,Object? topTags = null,}) {
  return _then(_RatingStats(
averageRating: null == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double,totalRatings: null == totalRatings ? _self.totalRatings : totalRatings // ignore: cast_nullable_to_non_nullable
as int,distribution: null == distribution ? _self._distribution : distribution // ignore: cast_nullable_to_non_nullable
as List<int>,positivePercentage: null == positivePercentage ? _self.positivePercentage : positivePercentage // ignore: cast_nullable_to_non_nullable
as double,topTags: null == topTags ? _self._topTags : topTags // ignore: cast_nullable_to_non_nullable
as List<String>,
  ));
}


}

// dart format on
