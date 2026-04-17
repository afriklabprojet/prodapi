// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistics.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Statistics {

 String get period;@JsonKey(name: 'start_date') String get startDate;@JsonKey(name: 'end_date') String get endDate; StatsOverview get overview; StatsPerformance get performance;@JsonKey(name: 'daily_breakdown') List<DailyStats> get dailyBreakdown;@JsonKey(name: 'peak_hours') List<PeakHour> get peakHours;@JsonKey(name: 'revenue_breakdown') RevenueBreakdown? get revenueBreakdown; StatsGoals? get goals;
/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatisticsCopyWith<Statistics> get copyWith => _$StatisticsCopyWithImpl<Statistics>(this as Statistics, _$identity);

  /// Serializes this Statistics to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is Statistics&&(identical(other.period, period) || other.period == period)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.performance, performance) || other.performance == performance)&&const DeepCollectionEquality().equals(other.dailyBreakdown, dailyBreakdown)&&const DeepCollectionEquality().equals(other.peakHours, peakHours)&&(identical(other.revenueBreakdown, revenueBreakdown) || other.revenueBreakdown == revenueBreakdown)&&(identical(other.goals, goals) || other.goals == goals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,startDate,endDate,overview,performance,const DeepCollectionEquality().hash(dailyBreakdown),const DeepCollectionEquality().hash(peakHours),revenueBreakdown,goals);

@override
String toString() {
  return 'Statistics(period: $period, startDate: $startDate, endDate: $endDate, overview: $overview, performance: $performance, dailyBreakdown: $dailyBreakdown, peakHours: $peakHours, revenueBreakdown: $revenueBreakdown, goals: $goals)';
}


}

/// @nodoc
abstract mixin class $StatisticsCopyWith<$Res>  {
  factory $StatisticsCopyWith(Statistics value, $Res Function(Statistics) _then) = _$StatisticsCopyWithImpl;
@useResult
$Res call({
 String period,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String endDate, StatsOverview overview, StatsPerformance performance,@JsonKey(name: 'daily_breakdown') List<DailyStats> dailyBreakdown,@JsonKey(name: 'peak_hours') List<PeakHour> peakHours,@JsonKey(name: 'revenue_breakdown') RevenueBreakdown? revenueBreakdown, StatsGoals? goals
});


$StatsOverviewCopyWith<$Res> get overview;$StatsPerformanceCopyWith<$Res> get performance;$RevenueBreakdownCopyWith<$Res>? get revenueBreakdown;$StatsGoalsCopyWith<$Res>? get goals;

}
/// @nodoc
class _$StatisticsCopyWithImpl<$Res>
    implements $StatisticsCopyWith<$Res> {
  _$StatisticsCopyWithImpl(this._self, this._then);

  final Statistics _self;
  final $Res Function(Statistics) _then;

/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? period = null,Object? startDate = null,Object? endDate = null,Object? overview = null,Object? performance = null,Object? dailyBreakdown = null,Object? peakHours = null,Object? revenueBreakdown = freezed,Object? goals = freezed,}) {
  return _then(_self.copyWith(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,overview: null == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as StatsOverview,performance: null == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as StatsPerformance,dailyBreakdown: null == dailyBreakdown ? _self.dailyBreakdown : dailyBreakdown // ignore: cast_nullable_to_non_nullable
as List<DailyStats>,peakHours: null == peakHours ? _self.peakHours : peakHours // ignore: cast_nullable_to_non_nullable
as List<PeakHour>,revenueBreakdown: freezed == revenueBreakdown ? _self.revenueBreakdown : revenueBreakdown // ignore: cast_nullable_to_non_nullable
as RevenueBreakdown?,goals: freezed == goals ? _self.goals : goals // ignore: cast_nullable_to_non_nullable
as StatsGoals?,
  ));
}
/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsOverviewCopyWith<$Res> get overview {
  
  return $StatsOverviewCopyWith<$Res>(_self.overview, (value) {
    return _then(_self.copyWith(overview: value));
  });
}/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsPerformanceCopyWith<$Res> get performance {
  
  return $StatsPerformanceCopyWith<$Res>(_self.performance, (value) {
    return _then(_self.copyWith(performance: value));
  });
}/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevenueBreakdownCopyWith<$Res>? get revenueBreakdown {
    if (_self.revenueBreakdown == null) {
    return null;
  }

  return $RevenueBreakdownCopyWith<$Res>(_self.revenueBreakdown!, (value) {
    return _then(_self.copyWith(revenueBreakdown: value));
  });
}/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsGoalsCopyWith<$Res>? get goals {
    if (_self.goals == null) {
    return null;
  }

  return $StatsGoalsCopyWith<$Res>(_self.goals!, (value) {
    return _then(_self.copyWith(goals: value));
  });
}
}


/// Adds pattern-matching-related methods to [Statistics].
extension StatisticsPatterns on Statistics {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _Statistics value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _Statistics() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _Statistics value)  $default,){
final _that = this;
switch (_that) {
case _Statistics():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _Statistics value)?  $default,){
final _that = this;
switch (_that) {
case _Statistics() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String period, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String endDate,  StatsOverview overview,  StatsPerformance performance, @JsonKey(name: 'daily_breakdown')  List<DailyStats> dailyBreakdown, @JsonKey(name: 'peak_hours')  List<PeakHour> peakHours, @JsonKey(name: 'revenue_breakdown')  RevenueBreakdown? revenueBreakdown,  StatsGoals? goals)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _Statistics() when $default != null:
return $default(_that.period,_that.startDate,_that.endDate,_that.overview,_that.performance,_that.dailyBreakdown,_that.peakHours,_that.revenueBreakdown,_that.goals);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String period, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String endDate,  StatsOverview overview,  StatsPerformance performance, @JsonKey(name: 'daily_breakdown')  List<DailyStats> dailyBreakdown, @JsonKey(name: 'peak_hours')  List<PeakHour> peakHours, @JsonKey(name: 'revenue_breakdown')  RevenueBreakdown? revenueBreakdown,  StatsGoals? goals)  $default,) {final _that = this;
switch (_that) {
case _Statistics():
return $default(_that.period,_that.startDate,_that.endDate,_that.overview,_that.performance,_that.dailyBreakdown,_that.peakHours,_that.revenueBreakdown,_that.goals);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String period, @JsonKey(name: 'start_date')  String startDate, @JsonKey(name: 'end_date')  String endDate,  StatsOverview overview,  StatsPerformance performance, @JsonKey(name: 'daily_breakdown')  List<DailyStats> dailyBreakdown, @JsonKey(name: 'peak_hours')  List<PeakHour> peakHours, @JsonKey(name: 'revenue_breakdown')  RevenueBreakdown? revenueBreakdown,  StatsGoals? goals)?  $default,) {final _that = this;
switch (_that) {
case _Statistics() when $default != null:
return $default(_that.period,_that.startDate,_that.endDate,_that.overview,_that.performance,_that.dailyBreakdown,_that.peakHours,_that.revenueBreakdown,_that.goals);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _Statistics implements Statistics {
  const _Statistics({required this.period, @JsonKey(name: 'start_date') required this.startDate, @JsonKey(name: 'end_date') required this.endDate, required this.overview, required this.performance, @JsonKey(name: 'daily_breakdown') final  List<DailyStats> dailyBreakdown = const [], @JsonKey(name: 'peak_hours') final  List<PeakHour> peakHours = const [], @JsonKey(name: 'revenue_breakdown') this.revenueBreakdown, this.goals}): _dailyBreakdown = dailyBreakdown,_peakHours = peakHours;
  factory _Statistics.fromJson(Map<String, dynamic> json) => _$StatisticsFromJson(json);

@override final  String period;
@override@JsonKey(name: 'start_date') final  String startDate;
@override@JsonKey(name: 'end_date') final  String endDate;
@override final  StatsOverview overview;
@override final  StatsPerformance performance;
 final  List<DailyStats> _dailyBreakdown;
@override@JsonKey(name: 'daily_breakdown') List<DailyStats> get dailyBreakdown {
  if (_dailyBreakdown is EqualUnmodifiableListView) return _dailyBreakdown;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_dailyBreakdown);
}

 final  List<PeakHour> _peakHours;
@override@JsonKey(name: 'peak_hours') List<PeakHour> get peakHours {
  if (_peakHours is EqualUnmodifiableListView) return _peakHours;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_peakHours);
}

@override@JsonKey(name: 'revenue_breakdown') final  RevenueBreakdown? revenueBreakdown;
@override final  StatsGoals? goals;

/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatisticsCopyWith<_Statistics> get copyWith => __$StatisticsCopyWithImpl<_Statistics>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatisticsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _Statistics&&(identical(other.period, period) || other.period == period)&&(identical(other.startDate, startDate) || other.startDate == startDate)&&(identical(other.endDate, endDate) || other.endDate == endDate)&&(identical(other.overview, overview) || other.overview == overview)&&(identical(other.performance, performance) || other.performance == performance)&&const DeepCollectionEquality().equals(other._dailyBreakdown, _dailyBreakdown)&&const DeepCollectionEquality().equals(other._peakHours, _peakHours)&&(identical(other.revenueBreakdown, revenueBreakdown) || other.revenueBreakdown == revenueBreakdown)&&(identical(other.goals, goals) || other.goals == goals));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,period,startDate,endDate,overview,performance,const DeepCollectionEquality().hash(_dailyBreakdown),const DeepCollectionEquality().hash(_peakHours),revenueBreakdown,goals);

@override
String toString() {
  return 'Statistics(period: $period, startDate: $startDate, endDate: $endDate, overview: $overview, performance: $performance, dailyBreakdown: $dailyBreakdown, peakHours: $peakHours, revenueBreakdown: $revenueBreakdown, goals: $goals)';
}


}

/// @nodoc
abstract mixin class _$StatisticsCopyWith<$Res> implements $StatisticsCopyWith<$Res> {
  factory _$StatisticsCopyWith(_Statistics value, $Res Function(_Statistics) _then) = __$StatisticsCopyWithImpl;
@override @useResult
$Res call({
 String period,@JsonKey(name: 'start_date') String startDate,@JsonKey(name: 'end_date') String endDate, StatsOverview overview, StatsPerformance performance,@JsonKey(name: 'daily_breakdown') List<DailyStats> dailyBreakdown,@JsonKey(name: 'peak_hours') List<PeakHour> peakHours,@JsonKey(name: 'revenue_breakdown') RevenueBreakdown? revenueBreakdown, StatsGoals? goals
});


@override $StatsOverviewCopyWith<$Res> get overview;@override $StatsPerformanceCopyWith<$Res> get performance;@override $RevenueBreakdownCopyWith<$Res>? get revenueBreakdown;@override $StatsGoalsCopyWith<$Res>? get goals;

}
/// @nodoc
class __$StatisticsCopyWithImpl<$Res>
    implements _$StatisticsCopyWith<$Res> {
  __$StatisticsCopyWithImpl(this._self, this._then);

  final _Statistics _self;
  final $Res Function(_Statistics) _then;

/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? period = null,Object? startDate = null,Object? endDate = null,Object? overview = null,Object? performance = null,Object? dailyBreakdown = null,Object? peakHours = null,Object? revenueBreakdown = freezed,Object? goals = freezed,}) {
  return _then(_Statistics(
period: null == period ? _self.period : period // ignore: cast_nullable_to_non_nullable
as String,startDate: null == startDate ? _self.startDate : startDate // ignore: cast_nullable_to_non_nullable
as String,endDate: null == endDate ? _self.endDate : endDate // ignore: cast_nullable_to_non_nullable
as String,overview: null == overview ? _self.overview : overview // ignore: cast_nullable_to_non_nullable
as StatsOverview,performance: null == performance ? _self.performance : performance // ignore: cast_nullable_to_non_nullable
as StatsPerformance,dailyBreakdown: null == dailyBreakdown ? _self._dailyBreakdown : dailyBreakdown // ignore: cast_nullable_to_non_nullable
as List<DailyStats>,peakHours: null == peakHours ? _self._peakHours : peakHours // ignore: cast_nullable_to_non_nullable
as List<PeakHour>,revenueBreakdown: freezed == revenueBreakdown ? _self.revenueBreakdown : revenueBreakdown // ignore: cast_nullable_to_non_nullable
as RevenueBreakdown?,goals: freezed == goals ? _self.goals : goals // ignore: cast_nullable_to_non_nullable
as StatsGoals?,
  ));
}

/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsOverviewCopyWith<$Res> get overview {
  
  return $StatsOverviewCopyWith<$Res>(_self.overview, (value) {
    return _then(_self.copyWith(overview: value));
  });
}/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsPerformanceCopyWith<$Res> get performance {
  
  return $StatsPerformanceCopyWith<$Res>(_self.performance, (value) {
    return _then(_self.copyWith(performance: value));
  });
}/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$RevenueBreakdownCopyWith<$Res>? get revenueBreakdown {
    if (_self.revenueBreakdown == null) {
    return null;
  }

  return $RevenueBreakdownCopyWith<$Res>(_self.revenueBreakdown!, (value) {
    return _then(_self.copyWith(revenueBreakdown: value));
  });
}/// Create a copy of Statistics
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$StatsGoalsCopyWith<$Res>? get goals {
    if (_self.goals == null) {
    return null;
  }

  return $StatsGoalsCopyWith<$Res>(_self.goals!, (value) {
    return _then(_self.copyWith(goals: value));
  });
}
}


/// @nodoc
mixin _$StatsOverview {

@JsonKey(name: 'total_deliveries', fromJson: safeInt) int get totalDeliveries;@JsonKey(name: 'total_earnings', fromJson: safeDouble) double get totalEarnings;@JsonKey(name: 'total_distance_km', fromJson: safeDouble) double get totalDistanceKm;@JsonKey(name: 'total_duration_minutes', fromJson: safeInt) int get totalDurationMinutes;@JsonKey(name: 'average_rating', fromJson: safeDouble) double get averageRating;@JsonKey(name: 'delivery_trend', fromJson: safeDouble) double get deliveryTrend;@JsonKey(name: 'earnings_trend', fromJson: safeDouble) double get earningsTrend; String get currency;
/// Create a copy of StatsOverview
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsOverviewCopyWith<StatsOverview> get copyWith => _$StatsOverviewCopyWithImpl<StatsOverview>(this as StatsOverview, _$identity);

  /// Serializes this StatsOverview to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsOverview&&(identical(other.totalDeliveries, totalDeliveries) || other.totalDeliveries == totalDeliveries)&&(identical(other.totalEarnings, totalEarnings) || other.totalEarnings == totalEarnings)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalDurationMinutes, totalDurationMinutes) || other.totalDurationMinutes == totalDurationMinutes)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.deliveryTrend, deliveryTrend) || other.deliveryTrend == deliveryTrend)&&(identical(other.earningsTrend, earningsTrend) || other.earningsTrend == earningsTrend)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalDeliveries,totalEarnings,totalDistanceKm,totalDurationMinutes,averageRating,deliveryTrend,earningsTrend,currency);

@override
String toString() {
  return 'StatsOverview(totalDeliveries: $totalDeliveries, totalEarnings: $totalEarnings, totalDistanceKm: $totalDistanceKm, totalDurationMinutes: $totalDurationMinutes, averageRating: $averageRating, deliveryTrend: $deliveryTrend, earningsTrend: $earningsTrend, currency: $currency)';
}


}

/// @nodoc
abstract mixin class $StatsOverviewCopyWith<$Res>  {
  factory $StatsOverviewCopyWith(StatsOverview value, $Res Function(StatsOverview) _then) = _$StatsOverviewCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_deliveries', fromJson: safeInt) int totalDeliveries,@JsonKey(name: 'total_earnings', fromJson: safeDouble) double totalEarnings,@JsonKey(name: 'total_distance_km', fromJson: safeDouble) double totalDistanceKm,@JsonKey(name: 'total_duration_minutes', fromJson: safeInt) int totalDurationMinutes,@JsonKey(name: 'average_rating', fromJson: safeDouble) double averageRating,@JsonKey(name: 'delivery_trend', fromJson: safeDouble) double deliveryTrend,@JsonKey(name: 'earnings_trend', fromJson: safeDouble) double earningsTrend, String currency
});




}
/// @nodoc
class _$StatsOverviewCopyWithImpl<$Res>
    implements $StatsOverviewCopyWith<$Res> {
  _$StatsOverviewCopyWithImpl(this._self, this._then);

  final StatsOverview _self;
  final $Res Function(StatsOverview) _then;

/// Create a copy of StatsOverview
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalDeliveries = null,Object? totalEarnings = null,Object? totalDistanceKm = null,Object? totalDurationMinutes = null,Object? averageRating = null,Object? deliveryTrend = null,Object? earningsTrend = null,Object? currency = null,}) {
  return _then(_self.copyWith(
totalDeliveries: null == totalDeliveries ? _self.totalDeliveries : totalDeliveries // ignore: cast_nullable_to_non_nullable
as int,totalEarnings: null == totalEarnings ? _self.totalEarnings : totalEarnings // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalDurationMinutes: null == totalDurationMinutes ? _self.totalDurationMinutes : totalDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,averageRating: null == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double,deliveryTrend: null == deliveryTrend ? _self.deliveryTrend : deliveryTrend // ignore: cast_nullable_to_non_nullable
as double,earningsTrend: null == earningsTrend ? _self.earningsTrend : earningsTrend // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsOverview].
extension StatsOverviewPatterns on StatsOverview {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsOverview value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsOverview() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsOverview value)  $default,){
final _that = this;
switch (_that) {
case _StatsOverview():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsOverview value)?  $default,){
final _that = this;
switch (_that) {
case _StatsOverview() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_deliveries', fromJson: safeInt)  int totalDeliveries, @JsonKey(name: 'total_earnings', fromJson: safeDouble)  double totalEarnings, @JsonKey(name: 'total_distance_km', fromJson: safeDouble)  double totalDistanceKm, @JsonKey(name: 'total_duration_minutes', fromJson: safeInt)  int totalDurationMinutes, @JsonKey(name: 'average_rating', fromJson: safeDouble)  double averageRating, @JsonKey(name: 'delivery_trend', fromJson: safeDouble)  double deliveryTrend, @JsonKey(name: 'earnings_trend', fromJson: safeDouble)  double earningsTrend,  String currency)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsOverview() when $default != null:
return $default(_that.totalDeliveries,_that.totalEarnings,_that.totalDistanceKm,_that.totalDurationMinutes,_that.averageRating,_that.deliveryTrend,_that.earningsTrend,_that.currency);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_deliveries', fromJson: safeInt)  int totalDeliveries, @JsonKey(name: 'total_earnings', fromJson: safeDouble)  double totalEarnings, @JsonKey(name: 'total_distance_km', fromJson: safeDouble)  double totalDistanceKm, @JsonKey(name: 'total_duration_minutes', fromJson: safeInt)  int totalDurationMinutes, @JsonKey(name: 'average_rating', fromJson: safeDouble)  double averageRating, @JsonKey(name: 'delivery_trend', fromJson: safeDouble)  double deliveryTrend, @JsonKey(name: 'earnings_trend', fromJson: safeDouble)  double earningsTrend,  String currency)  $default,) {final _that = this;
switch (_that) {
case _StatsOverview():
return $default(_that.totalDeliveries,_that.totalEarnings,_that.totalDistanceKm,_that.totalDurationMinutes,_that.averageRating,_that.deliveryTrend,_that.earningsTrend,_that.currency);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_deliveries', fromJson: safeInt)  int totalDeliveries, @JsonKey(name: 'total_earnings', fromJson: safeDouble)  double totalEarnings, @JsonKey(name: 'total_distance_km', fromJson: safeDouble)  double totalDistanceKm, @JsonKey(name: 'total_duration_minutes', fromJson: safeInt)  int totalDurationMinutes, @JsonKey(name: 'average_rating', fromJson: safeDouble)  double averageRating, @JsonKey(name: 'delivery_trend', fromJson: safeDouble)  double deliveryTrend, @JsonKey(name: 'earnings_trend', fromJson: safeDouble)  double earningsTrend,  String currency)?  $default,) {final _that = this;
switch (_that) {
case _StatsOverview() when $default != null:
return $default(_that.totalDeliveries,_that.totalEarnings,_that.totalDistanceKm,_that.totalDurationMinutes,_that.averageRating,_that.deliveryTrend,_that.earningsTrend,_that.currency);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsOverview implements StatsOverview {
  const _StatsOverview({@JsonKey(name: 'total_deliveries', fromJson: safeInt) this.totalDeliveries = 0, @JsonKey(name: 'total_earnings', fromJson: safeDouble) this.totalEarnings = 0.0, @JsonKey(name: 'total_distance_km', fromJson: safeDouble) this.totalDistanceKm = 0.0, @JsonKey(name: 'total_duration_minutes', fromJson: safeInt) this.totalDurationMinutes = 0, @JsonKey(name: 'average_rating', fromJson: safeDouble) this.averageRating = 0.0, @JsonKey(name: 'delivery_trend', fromJson: safeDouble) this.deliveryTrend = 0.0, @JsonKey(name: 'earnings_trend', fromJson: safeDouble) this.earningsTrend = 0.0, this.currency = 'FCFA'});
  factory _StatsOverview.fromJson(Map<String, dynamic> json) => _$StatsOverviewFromJson(json);

@override@JsonKey(name: 'total_deliveries', fromJson: safeInt) final  int totalDeliveries;
@override@JsonKey(name: 'total_earnings', fromJson: safeDouble) final  double totalEarnings;
@override@JsonKey(name: 'total_distance_km', fromJson: safeDouble) final  double totalDistanceKm;
@override@JsonKey(name: 'total_duration_minutes', fromJson: safeInt) final  int totalDurationMinutes;
@override@JsonKey(name: 'average_rating', fromJson: safeDouble) final  double averageRating;
@override@JsonKey(name: 'delivery_trend', fromJson: safeDouble) final  double deliveryTrend;
@override@JsonKey(name: 'earnings_trend', fromJson: safeDouble) final  double earningsTrend;
@override@JsonKey() final  String currency;

/// Create a copy of StatsOverview
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsOverviewCopyWith<_StatsOverview> get copyWith => __$StatsOverviewCopyWithImpl<_StatsOverview>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsOverviewToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsOverview&&(identical(other.totalDeliveries, totalDeliveries) || other.totalDeliveries == totalDeliveries)&&(identical(other.totalEarnings, totalEarnings) || other.totalEarnings == totalEarnings)&&(identical(other.totalDistanceKm, totalDistanceKm) || other.totalDistanceKm == totalDistanceKm)&&(identical(other.totalDurationMinutes, totalDurationMinutes) || other.totalDurationMinutes == totalDurationMinutes)&&(identical(other.averageRating, averageRating) || other.averageRating == averageRating)&&(identical(other.deliveryTrend, deliveryTrend) || other.deliveryTrend == deliveryTrend)&&(identical(other.earningsTrend, earningsTrend) || other.earningsTrend == earningsTrend)&&(identical(other.currency, currency) || other.currency == currency));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalDeliveries,totalEarnings,totalDistanceKm,totalDurationMinutes,averageRating,deliveryTrend,earningsTrend,currency);

@override
String toString() {
  return 'StatsOverview(totalDeliveries: $totalDeliveries, totalEarnings: $totalEarnings, totalDistanceKm: $totalDistanceKm, totalDurationMinutes: $totalDurationMinutes, averageRating: $averageRating, deliveryTrend: $deliveryTrend, earningsTrend: $earningsTrend, currency: $currency)';
}


}

/// @nodoc
abstract mixin class _$StatsOverviewCopyWith<$Res> implements $StatsOverviewCopyWith<$Res> {
  factory _$StatsOverviewCopyWith(_StatsOverview value, $Res Function(_StatsOverview) _then) = __$StatsOverviewCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_deliveries', fromJson: safeInt) int totalDeliveries,@JsonKey(name: 'total_earnings', fromJson: safeDouble) double totalEarnings,@JsonKey(name: 'total_distance_km', fromJson: safeDouble) double totalDistanceKm,@JsonKey(name: 'total_duration_minutes', fromJson: safeInt) int totalDurationMinutes,@JsonKey(name: 'average_rating', fromJson: safeDouble) double averageRating,@JsonKey(name: 'delivery_trend', fromJson: safeDouble) double deliveryTrend,@JsonKey(name: 'earnings_trend', fromJson: safeDouble) double earningsTrend, String currency
});




}
/// @nodoc
class __$StatsOverviewCopyWithImpl<$Res>
    implements _$StatsOverviewCopyWith<$Res> {
  __$StatsOverviewCopyWithImpl(this._self, this._then);

  final _StatsOverview _self;
  final $Res Function(_StatsOverview) _then;

/// Create a copy of StatsOverview
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalDeliveries = null,Object? totalEarnings = null,Object? totalDistanceKm = null,Object? totalDurationMinutes = null,Object? averageRating = null,Object? deliveryTrend = null,Object? earningsTrend = null,Object? currency = null,}) {
  return _then(_StatsOverview(
totalDeliveries: null == totalDeliveries ? _self.totalDeliveries : totalDeliveries // ignore: cast_nullable_to_non_nullable
as int,totalEarnings: null == totalEarnings ? _self.totalEarnings : totalEarnings // ignore: cast_nullable_to_non_nullable
as double,totalDistanceKm: null == totalDistanceKm ? _self.totalDistanceKm : totalDistanceKm // ignore: cast_nullable_to_non_nullable
as double,totalDurationMinutes: null == totalDurationMinutes ? _self.totalDurationMinutes : totalDurationMinutes // ignore: cast_nullable_to_non_nullable
as int,averageRating: null == averageRating ? _self.averageRating : averageRating // ignore: cast_nullable_to_non_nullable
as double,deliveryTrend: null == deliveryTrend ? _self.deliveryTrend : deliveryTrend // ignore: cast_nullable_to_non_nullable
as double,earningsTrend: null == earningsTrend ? _self.earningsTrend : earningsTrend // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$StatsPerformance {

@JsonKey(name: 'total_assigned', fromJson: safeInt) int get totalAssigned;@JsonKey(name: 'total_accepted', fromJson: safeInt) int get totalAccepted;@JsonKey(name: 'total_delivered', fromJson: safeInt) int get totalDelivered;@JsonKey(name: 'total_cancelled', fromJson: safeInt) int get totalCancelled;@JsonKey(name: 'acceptance_rate', fromJson: safeDouble) double get acceptanceRate;@JsonKey(name: 'completion_rate', fromJson: safeDouble) double get completionRate;@JsonKey(name: 'cancellation_rate', fromJson: safeDouble) double get cancellationRate;@JsonKey(name: 'on_time_rate', fromJson: safeDouble) double get onTimeRate;@JsonKey(name: 'satisfaction_rate', fromJson: safeDouble) double get satisfactionRate;
/// Create a copy of StatsPerformance
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsPerformanceCopyWith<StatsPerformance> get copyWith => _$StatsPerformanceCopyWithImpl<StatsPerformance>(this as StatsPerformance, _$identity);

  /// Serializes this StatsPerformance to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsPerformance&&(identical(other.totalAssigned, totalAssigned) || other.totalAssigned == totalAssigned)&&(identical(other.totalAccepted, totalAccepted) || other.totalAccepted == totalAccepted)&&(identical(other.totalDelivered, totalDelivered) || other.totalDelivered == totalDelivered)&&(identical(other.totalCancelled, totalCancelled) || other.totalCancelled == totalCancelled)&&(identical(other.acceptanceRate, acceptanceRate) || other.acceptanceRate == acceptanceRate)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.onTimeRate, onTimeRate) || other.onTimeRate == onTimeRate)&&(identical(other.satisfactionRate, satisfactionRate) || other.satisfactionRate == satisfactionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalAssigned,totalAccepted,totalDelivered,totalCancelled,acceptanceRate,completionRate,cancellationRate,onTimeRate,satisfactionRate);

@override
String toString() {
  return 'StatsPerformance(totalAssigned: $totalAssigned, totalAccepted: $totalAccepted, totalDelivered: $totalDelivered, totalCancelled: $totalCancelled, acceptanceRate: $acceptanceRate, completionRate: $completionRate, cancellationRate: $cancellationRate, onTimeRate: $onTimeRate, satisfactionRate: $satisfactionRate)';
}


}

/// @nodoc
abstract mixin class $StatsPerformanceCopyWith<$Res>  {
  factory $StatsPerformanceCopyWith(StatsPerformance value, $Res Function(StatsPerformance) _then) = _$StatsPerformanceCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'total_assigned', fromJson: safeInt) int totalAssigned,@JsonKey(name: 'total_accepted', fromJson: safeInt) int totalAccepted,@JsonKey(name: 'total_delivered', fromJson: safeInt) int totalDelivered,@JsonKey(name: 'total_cancelled', fromJson: safeInt) int totalCancelled,@JsonKey(name: 'acceptance_rate', fromJson: safeDouble) double acceptanceRate,@JsonKey(name: 'completion_rate', fromJson: safeDouble) double completionRate,@JsonKey(name: 'cancellation_rate', fromJson: safeDouble) double cancellationRate,@JsonKey(name: 'on_time_rate', fromJson: safeDouble) double onTimeRate,@JsonKey(name: 'satisfaction_rate', fromJson: safeDouble) double satisfactionRate
});




}
/// @nodoc
class _$StatsPerformanceCopyWithImpl<$Res>
    implements $StatsPerformanceCopyWith<$Res> {
  _$StatsPerformanceCopyWithImpl(this._self, this._then);

  final StatsPerformance _self;
  final $Res Function(StatsPerformance) _then;

/// Create a copy of StatsPerformance
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? totalAssigned = null,Object? totalAccepted = null,Object? totalDelivered = null,Object? totalCancelled = null,Object? acceptanceRate = null,Object? completionRate = null,Object? cancellationRate = null,Object? onTimeRate = null,Object? satisfactionRate = null,}) {
  return _then(_self.copyWith(
totalAssigned: null == totalAssigned ? _self.totalAssigned : totalAssigned // ignore: cast_nullable_to_non_nullable
as int,totalAccepted: null == totalAccepted ? _self.totalAccepted : totalAccepted // ignore: cast_nullable_to_non_nullable
as int,totalDelivered: null == totalDelivered ? _self.totalDelivered : totalDelivered // ignore: cast_nullable_to_non_nullable
as int,totalCancelled: null == totalCancelled ? _self.totalCancelled : totalCancelled // ignore: cast_nullable_to_non_nullable
as int,acceptanceRate: null == acceptanceRate ? _self.acceptanceRate : acceptanceRate // ignore: cast_nullable_to_non_nullable
as double,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as double,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as double,onTimeRate: null == onTimeRate ? _self.onTimeRate : onTimeRate // ignore: cast_nullable_to_non_nullable
as double,satisfactionRate: null == satisfactionRate ? _self.satisfactionRate : satisfactionRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsPerformance].
extension StatsPerformancePatterns on StatsPerformance {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsPerformance value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsPerformance() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsPerformance value)  $default,){
final _that = this;
switch (_that) {
case _StatsPerformance():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsPerformance value)?  $default,){
final _that = this;
switch (_that) {
case _StatsPerformance() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_assigned', fromJson: safeInt)  int totalAssigned, @JsonKey(name: 'total_accepted', fromJson: safeInt)  int totalAccepted, @JsonKey(name: 'total_delivered', fromJson: safeInt)  int totalDelivered, @JsonKey(name: 'total_cancelled', fromJson: safeInt)  int totalCancelled, @JsonKey(name: 'acceptance_rate', fromJson: safeDouble)  double acceptanceRate, @JsonKey(name: 'completion_rate', fromJson: safeDouble)  double completionRate, @JsonKey(name: 'cancellation_rate', fromJson: safeDouble)  double cancellationRate, @JsonKey(name: 'on_time_rate', fromJson: safeDouble)  double onTimeRate, @JsonKey(name: 'satisfaction_rate', fromJson: safeDouble)  double satisfactionRate)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsPerformance() when $default != null:
return $default(_that.totalAssigned,_that.totalAccepted,_that.totalDelivered,_that.totalCancelled,_that.acceptanceRate,_that.completionRate,_that.cancellationRate,_that.onTimeRate,_that.satisfactionRate);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'total_assigned', fromJson: safeInt)  int totalAssigned, @JsonKey(name: 'total_accepted', fromJson: safeInt)  int totalAccepted, @JsonKey(name: 'total_delivered', fromJson: safeInt)  int totalDelivered, @JsonKey(name: 'total_cancelled', fromJson: safeInt)  int totalCancelled, @JsonKey(name: 'acceptance_rate', fromJson: safeDouble)  double acceptanceRate, @JsonKey(name: 'completion_rate', fromJson: safeDouble)  double completionRate, @JsonKey(name: 'cancellation_rate', fromJson: safeDouble)  double cancellationRate, @JsonKey(name: 'on_time_rate', fromJson: safeDouble)  double onTimeRate, @JsonKey(name: 'satisfaction_rate', fromJson: safeDouble)  double satisfactionRate)  $default,) {final _that = this;
switch (_that) {
case _StatsPerformance():
return $default(_that.totalAssigned,_that.totalAccepted,_that.totalDelivered,_that.totalCancelled,_that.acceptanceRate,_that.completionRate,_that.cancellationRate,_that.onTimeRate,_that.satisfactionRate);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'total_assigned', fromJson: safeInt)  int totalAssigned, @JsonKey(name: 'total_accepted', fromJson: safeInt)  int totalAccepted, @JsonKey(name: 'total_delivered', fromJson: safeInt)  int totalDelivered, @JsonKey(name: 'total_cancelled', fromJson: safeInt)  int totalCancelled, @JsonKey(name: 'acceptance_rate', fromJson: safeDouble)  double acceptanceRate, @JsonKey(name: 'completion_rate', fromJson: safeDouble)  double completionRate, @JsonKey(name: 'cancellation_rate', fromJson: safeDouble)  double cancellationRate, @JsonKey(name: 'on_time_rate', fromJson: safeDouble)  double onTimeRate, @JsonKey(name: 'satisfaction_rate', fromJson: safeDouble)  double satisfactionRate)?  $default,) {final _that = this;
switch (_that) {
case _StatsPerformance() when $default != null:
return $default(_that.totalAssigned,_that.totalAccepted,_that.totalDelivered,_that.totalCancelled,_that.acceptanceRate,_that.completionRate,_that.cancellationRate,_that.onTimeRate,_that.satisfactionRate);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsPerformance implements StatsPerformance {
  const _StatsPerformance({@JsonKey(name: 'total_assigned', fromJson: safeInt) this.totalAssigned = 0, @JsonKey(name: 'total_accepted', fromJson: safeInt) this.totalAccepted = 0, @JsonKey(name: 'total_delivered', fromJson: safeInt) this.totalDelivered = 0, @JsonKey(name: 'total_cancelled', fromJson: safeInt) this.totalCancelled = 0, @JsonKey(name: 'acceptance_rate', fromJson: safeDouble) this.acceptanceRate = 0.0, @JsonKey(name: 'completion_rate', fromJson: safeDouble) this.completionRate = 0.0, @JsonKey(name: 'cancellation_rate', fromJson: safeDouble) this.cancellationRate = 0.0, @JsonKey(name: 'on_time_rate', fromJson: safeDouble) this.onTimeRate = 0.0, @JsonKey(name: 'satisfaction_rate', fromJson: safeDouble) this.satisfactionRate = 0.0});
  factory _StatsPerformance.fromJson(Map<String, dynamic> json) => _$StatsPerformanceFromJson(json);

@override@JsonKey(name: 'total_assigned', fromJson: safeInt) final  int totalAssigned;
@override@JsonKey(name: 'total_accepted', fromJson: safeInt) final  int totalAccepted;
@override@JsonKey(name: 'total_delivered', fromJson: safeInt) final  int totalDelivered;
@override@JsonKey(name: 'total_cancelled', fromJson: safeInt) final  int totalCancelled;
@override@JsonKey(name: 'acceptance_rate', fromJson: safeDouble) final  double acceptanceRate;
@override@JsonKey(name: 'completion_rate', fromJson: safeDouble) final  double completionRate;
@override@JsonKey(name: 'cancellation_rate', fromJson: safeDouble) final  double cancellationRate;
@override@JsonKey(name: 'on_time_rate', fromJson: safeDouble) final  double onTimeRate;
@override@JsonKey(name: 'satisfaction_rate', fromJson: safeDouble) final  double satisfactionRate;

/// Create a copy of StatsPerformance
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsPerformanceCopyWith<_StatsPerformance> get copyWith => __$StatsPerformanceCopyWithImpl<_StatsPerformance>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsPerformanceToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsPerformance&&(identical(other.totalAssigned, totalAssigned) || other.totalAssigned == totalAssigned)&&(identical(other.totalAccepted, totalAccepted) || other.totalAccepted == totalAccepted)&&(identical(other.totalDelivered, totalDelivered) || other.totalDelivered == totalDelivered)&&(identical(other.totalCancelled, totalCancelled) || other.totalCancelled == totalCancelled)&&(identical(other.acceptanceRate, acceptanceRate) || other.acceptanceRate == acceptanceRate)&&(identical(other.completionRate, completionRate) || other.completionRate == completionRate)&&(identical(other.cancellationRate, cancellationRate) || other.cancellationRate == cancellationRate)&&(identical(other.onTimeRate, onTimeRate) || other.onTimeRate == onTimeRate)&&(identical(other.satisfactionRate, satisfactionRate) || other.satisfactionRate == satisfactionRate));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,totalAssigned,totalAccepted,totalDelivered,totalCancelled,acceptanceRate,completionRate,cancellationRate,onTimeRate,satisfactionRate);

@override
String toString() {
  return 'StatsPerformance(totalAssigned: $totalAssigned, totalAccepted: $totalAccepted, totalDelivered: $totalDelivered, totalCancelled: $totalCancelled, acceptanceRate: $acceptanceRate, completionRate: $completionRate, cancellationRate: $cancellationRate, onTimeRate: $onTimeRate, satisfactionRate: $satisfactionRate)';
}


}

/// @nodoc
abstract mixin class _$StatsPerformanceCopyWith<$Res> implements $StatsPerformanceCopyWith<$Res> {
  factory _$StatsPerformanceCopyWith(_StatsPerformance value, $Res Function(_StatsPerformance) _then) = __$StatsPerformanceCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'total_assigned', fromJson: safeInt) int totalAssigned,@JsonKey(name: 'total_accepted', fromJson: safeInt) int totalAccepted,@JsonKey(name: 'total_delivered', fromJson: safeInt) int totalDelivered,@JsonKey(name: 'total_cancelled', fromJson: safeInt) int totalCancelled,@JsonKey(name: 'acceptance_rate', fromJson: safeDouble) double acceptanceRate,@JsonKey(name: 'completion_rate', fromJson: safeDouble) double completionRate,@JsonKey(name: 'cancellation_rate', fromJson: safeDouble) double cancellationRate,@JsonKey(name: 'on_time_rate', fromJson: safeDouble) double onTimeRate,@JsonKey(name: 'satisfaction_rate', fromJson: safeDouble) double satisfactionRate
});




}
/// @nodoc
class __$StatsPerformanceCopyWithImpl<$Res>
    implements _$StatsPerformanceCopyWith<$Res> {
  __$StatsPerformanceCopyWithImpl(this._self, this._then);

  final _StatsPerformance _self;
  final $Res Function(_StatsPerformance) _then;

/// Create a copy of StatsPerformance
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? totalAssigned = null,Object? totalAccepted = null,Object? totalDelivered = null,Object? totalCancelled = null,Object? acceptanceRate = null,Object? completionRate = null,Object? cancellationRate = null,Object? onTimeRate = null,Object? satisfactionRate = null,}) {
  return _then(_StatsPerformance(
totalAssigned: null == totalAssigned ? _self.totalAssigned : totalAssigned // ignore: cast_nullable_to_non_nullable
as int,totalAccepted: null == totalAccepted ? _self.totalAccepted : totalAccepted // ignore: cast_nullable_to_non_nullable
as int,totalDelivered: null == totalDelivered ? _self.totalDelivered : totalDelivered // ignore: cast_nullable_to_non_nullable
as int,totalCancelled: null == totalCancelled ? _self.totalCancelled : totalCancelled // ignore: cast_nullable_to_non_nullable
as int,acceptanceRate: null == acceptanceRate ? _self.acceptanceRate : acceptanceRate // ignore: cast_nullable_to_non_nullable
as double,completionRate: null == completionRate ? _self.completionRate : completionRate // ignore: cast_nullable_to_non_nullable
as double,cancellationRate: null == cancellationRate ? _self.cancellationRate : cancellationRate // ignore: cast_nullable_to_non_nullable
as double,onTimeRate: null == onTimeRate ? _self.onTimeRate : onTimeRate // ignore: cast_nullable_to_non_nullable
as double,satisfactionRate: null == satisfactionRate ? _self.satisfactionRate : satisfactionRate // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$DailyStats {

 String get date;@JsonKey(name: 'day_name') String get dayName;@JsonKey(fromJson: safeInt) int get deliveries;@JsonKey(fromJson: safeDouble) double get earnings;
/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$DailyStatsCopyWith<DailyStats> get copyWith => _$DailyStatsCopyWithImpl<DailyStats>(this as DailyStats, _$identity);

  /// Serializes this DailyStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is DailyStats&&(identical(other.date, date) || other.date == date)&&(identical(other.dayName, dayName) || other.dayName == dayName)&&(identical(other.deliveries, deliveries) || other.deliveries == deliveries)&&(identical(other.earnings, earnings) || other.earnings == earnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,dayName,deliveries,earnings);

@override
String toString() {
  return 'DailyStats(date: $date, dayName: $dayName, deliveries: $deliveries, earnings: $earnings)';
}


}

/// @nodoc
abstract mixin class $DailyStatsCopyWith<$Res>  {
  factory $DailyStatsCopyWith(DailyStats value, $Res Function(DailyStats) _then) = _$DailyStatsCopyWithImpl;
@useResult
$Res call({
 String date,@JsonKey(name: 'day_name') String dayName,@JsonKey(fromJson: safeInt) int deliveries,@JsonKey(fromJson: safeDouble) double earnings
});




}
/// @nodoc
class _$DailyStatsCopyWithImpl<$Res>
    implements $DailyStatsCopyWith<$Res> {
  _$DailyStatsCopyWithImpl(this._self, this._then);

  final DailyStats _self;
  final $Res Function(DailyStats) _then;

/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? date = null,Object? dayName = null,Object? deliveries = null,Object? earnings = null,}) {
  return _then(_self.copyWith(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,dayName: null == dayName ? _self.dayName : dayName // ignore: cast_nullable_to_non_nullable
as String,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as int,earnings: null == earnings ? _self.earnings : earnings // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [DailyStats].
extension DailyStatsPatterns on DailyStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _DailyStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _DailyStats value)  $default,){
final _that = this;
switch (_that) {
case _DailyStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _DailyStats value)?  $default,){
final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String date, @JsonKey(name: 'day_name')  String dayName, @JsonKey(fromJson: safeInt)  int deliveries, @JsonKey(fromJson: safeDouble)  double earnings)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
return $default(_that.date,_that.dayName,_that.deliveries,_that.earnings);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String date, @JsonKey(name: 'day_name')  String dayName, @JsonKey(fromJson: safeInt)  int deliveries, @JsonKey(fromJson: safeDouble)  double earnings)  $default,) {final _that = this;
switch (_that) {
case _DailyStats():
return $default(_that.date,_that.dayName,_that.deliveries,_that.earnings);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String date, @JsonKey(name: 'day_name')  String dayName, @JsonKey(fromJson: safeInt)  int deliveries, @JsonKey(fromJson: safeDouble)  double earnings)?  $default,) {final _that = this;
switch (_that) {
case _DailyStats() when $default != null:
return $default(_that.date,_that.dayName,_that.deliveries,_that.earnings);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _DailyStats implements DailyStats {
  const _DailyStats({required this.date, @JsonKey(name: 'day_name') required this.dayName, @JsonKey(fromJson: safeInt) this.deliveries = 0, @JsonKey(fromJson: safeDouble) this.earnings = 0.0});
  factory _DailyStats.fromJson(Map<String, dynamic> json) => _$DailyStatsFromJson(json);

@override final  String date;
@override@JsonKey(name: 'day_name') final  String dayName;
@override@JsonKey(fromJson: safeInt) final  int deliveries;
@override@JsonKey(fromJson: safeDouble) final  double earnings;

/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$DailyStatsCopyWith<_DailyStats> get copyWith => __$DailyStatsCopyWithImpl<_DailyStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$DailyStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _DailyStats&&(identical(other.date, date) || other.date == date)&&(identical(other.dayName, dayName) || other.dayName == dayName)&&(identical(other.deliveries, deliveries) || other.deliveries == deliveries)&&(identical(other.earnings, earnings) || other.earnings == earnings));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,date,dayName,deliveries,earnings);

@override
String toString() {
  return 'DailyStats(date: $date, dayName: $dayName, deliveries: $deliveries, earnings: $earnings)';
}


}

/// @nodoc
abstract mixin class _$DailyStatsCopyWith<$Res> implements $DailyStatsCopyWith<$Res> {
  factory _$DailyStatsCopyWith(_DailyStats value, $Res Function(_DailyStats) _then) = __$DailyStatsCopyWithImpl;
@override @useResult
$Res call({
 String date,@JsonKey(name: 'day_name') String dayName,@JsonKey(fromJson: safeInt) int deliveries,@JsonKey(fromJson: safeDouble) double earnings
});




}
/// @nodoc
class __$DailyStatsCopyWithImpl<$Res>
    implements _$DailyStatsCopyWith<$Res> {
  __$DailyStatsCopyWithImpl(this._self, this._then);

  final _DailyStats _self;
  final $Res Function(_DailyStats) _then;

/// Create a copy of DailyStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? date = null,Object? dayName = null,Object? deliveries = null,Object? earnings = null,}) {
  return _then(_DailyStats(
date: null == date ? _self.date : date // ignore: cast_nullable_to_non_nullable
as String,dayName: null == dayName ? _self.dayName : dayName // ignore: cast_nullable_to_non_nullable
as String,deliveries: null == deliveries ? _self.deliveries : deliveries // ignore: cast_nullable_to_non_nullable
as int,earnings: null == earnings ? _self.earnings : earnings // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$PeakHour {

 String get hour; String get label;@JsonKey(fromJson: safeInt) int get count;@JsonKey(fromJson: safeDouble) double get percentage;
/// Create a copy of PeakHour
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$PeakHourCopyWith<PeakHour> get copyWith => _$PeakHourCopyWithImpl<PeakHour>(this as PeakHour, _$identity);

  /// Serializes this PeakHour to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is PeakHour&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count)&&(identical(other.percentage, percentage) || other.percentage == percentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hour,label,count,percentage);

@override
String toString() {
  return 'PeakHour(hour: $hour, label: $label, count: $count, percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class $PeakHourCopyWith<$Res>  {
  factory $PeakHourCopyWith(PeakHour value, $Res Function(PeakHour) _then) = _$PeakHourCopyWithImpl;
@useResult
$Res call({
 String hour, String label,@JsonKey(fromJson: safeInt) int count,@JsonKey(fromJson: safeDouble) double percentage
});




}
/// @nodoc
class _$PeakHourCopyWithImpl<$Res>
    implements $PeakHourCopyWith<$Res> {
  _$PeakHourCopyWithImpl(this._self, this._then);

  final PeakHour _self;
  final $Res Function(PeakHour) _then;

/// Create a copy of PeakHour
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? hour = null,Object? label = null,Object? count = null,Object? percentage = null,}) {
  return _then(_self.copyWith(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [PeakHour].
extension PeakHourPatterns on PeakHour {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _PeakHour value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _PeakHour() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _PeakHour value)  $default,){
final _that = this;
switch (_that) {
case _PeakHour():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _PeakHour value)?  $default,){
final _that = this;
switch (_that) {
case _PeakHour() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( String hour,  String label, @JsonKey(fromJson: safeInt)  int count, @JsonKey(fromJson: safeDouble)  double percentage)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _PeakHour() when $default != null:
return $default(_that.hour,_that.label,_that.count,_that.percentage);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( String hour,  String label, @JsonKey(fromJson: safeInt)  int count, @JsonKey(fromJson: safeDouble)  double percentage)  $default,) {final _that = this;
switch (_that) {
case _PeakHour():
return $default(_that.hour,_that.label,_that.count,_that.percentage);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( String hour,  String label, @JsonKey(fromJson: safeInt)  int count, @JsonKey(fromJson: safeDouble)  double percentage)?  $default,) {final _that = this;
switch (_that) {
case _PeakHour() when $default != null:
return $default(_that.hour,_that.label,_that.count,_that.percentage);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _PeakHour implements PeakHour {
  const _PeakHour({required this.hour, required this.label, @JsonKey(fromJson: safeInt) this.count = 0, @JsonKey(fromJson: safeDouble) this.percentage = 0.0});
  factory _PeakHour.fromJson(Map<String, dynamic> json) => _$PeakHourFromJson(json);

@override final  String hour;
@override final  String label;
@override@JsonKey(fromJson: safeInt) final  int count;
@override@JsonKey(fromJson: safeDouble) final  double percentage;

/// Create a copy of PeakHour
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$PeakHourCopyWith<_PeakHour> get copyWith => __$PeakHourCopyWithImpl<_PeakHour>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$PeakHourToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _PeakHour&&(identical(other.hour, hour) || other.hour == hour)&&(identical(other.label, label) || other.label == label)&&(identical(other.count, count) || other.count == count)&&(identical(other.percentage, percentage) || other.percentage == percentage));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,hour,label,count,percentage);

@override
String toString() {
  return 'PeakHour(hour: $hour, label: $label, count: $count, percentage: $percentage)';
}


}

/// @nodoc
abstract mixin class _$PeakHourCopyWith<$Res> implements $PeakHourCopyWith<$Res> {
  factory _$PeakHourCopyWith(_PeakHour value, $Res Function(_PeakHour) _then) = __$PeakHourCopyWithImpl;
@override @useResult
$Res call({
 String hour, String label,@JsonKey(fromJson: safeInt) int count,@JsonKey(fromJson: safeDouble) double percentage
});




}
/// @nodoc
class __$PeakHourCopyWithImpl<$Res>
    implements _$PeakHourCopyWith<$Res> {
  __$PeakHourCopyWithImpl(this._self, this._then);

  final _PeakHour _self;
  final $Res Function(_PeakHour) _then;

/// Create a copy of PeakHour
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? hour = null,Object? label = null,Object? count = null,Object? percentage = null,}) {
  return _then(_PeakHour(
hour: null == hour ? _self.hour : hour // ignore: cast_nullable_to_non_nullable
as String,label: null == label ? _self.label : label // ignore: cast_nullable_to_non_nullable
as String,count: null == count ? _self.count : count // ignore: cast_nullable_to_non_nullable
as int,percentage: null == percentage ? _self.percentage : percentage // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}

/// @nodoc
mixin _$RevenueBreakdown {

 double get deliveryCommissionsAmount; double get deliveryCommissionsPercent; double get challengeBonusesAmount; double get challengeBonusesPercent; double get rushBonusesAmount; double get rushBonusesPercent; double get total;
/// Create a copy of RevenueBreakdown
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$RevenueBreakdownCopyWith<RevenueBreakdown> get copyWith => _$RevenueBreakdownCopyWithImpl<RevenueBreakdown>(this as RevenueBreakdown, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is RevenueBreakdown&&(identical(other.deliveryCommissionsAmount, deliveryCommissionsAmount) || other.deliveryCommissionsAmount == deliveryCommissionsAmount)&&(identical(other.deliveryCommissionsPercent, deliveryCommissionsPercent) || other.deliveryCommissionsPercent == deliveryCommissionsPercent)&&(identical(other.challengeBonusesAmount, challengeBonusesAmount) || other.challengeBonusesAmount == challengeBonusesAmount)&&(identical(other.challengeBonusesPercent, challengeBonusesPercent) || other.challengeBonusesPercent == challengeBonusesPercent)&&(identical(other.rushBonusesAmount, rushBonusesAmount) || other.rushBonusesAmount == rushBonusesAmount)&&(identical(other.rushBonusesPercent, rushBonusesPercent) || other.rushBonusesPercent == rushBonusesPercent)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryCommissionsAmount,deliveryCommissionsPercent,challengeBonusesAmount,challengeBonusesPercent,rushBonusesAmount,rushBonusesPercent,total);

@override
String toString() {
  return 'RevenueBreakdown(deliveryCommissionsAmount: $deliveryCommissionsAmount, deliveryCommissionsPercent: $deliveryCommissionsPercent, challengeBonusesAmount: $challengeBonusesAmount, challengeBonusesPercent: $challengeBonusesPercent, rushBonusesAmount: $rushBonusesAmount, rushBonusesPercent: $rushBonusesPercent, total: $total)';
}


}

/// @nodoc
abstract mixin class $RevenueBreakdownCopyWith<$Res>  {
  factory $RevenueBreakdownCopyWith(RevenueBreakdown value, $Res Function(RevenueBreakdown) _then) = _$RevenueBreakdownCopyWithImpl;
@useResult
$Res call({
 double deliveryCommissionsAmount, double deliveryCommissionsPercent, double challengeBonusesAmount, double challengeBonusesPercent, double rushBonusesAmount, double rushBonusesPercent, double total
});




}
/// @nodoc
class _$RevenueBreakdownCopyWithImpl<$Res>
    implements $RevenueBreakdownCopyWith<$Res> {
  _$RevenueBreakdownCopyWithImpl(this._self, this._then);

  final RevenueBreakdown _self;
  final $Res Function(RevenueBreakdown) _then;

/// Create a copy of RevenueBreakdown
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? deliveryCommissionsAmount = null,Object? deliveryCommissionsPercent = null,Object? challengeBonusesAmount = null,Object? challengeBonusesPercent = null,Object? rushBonusesAmount = null,Object? rushBonusesPercent = null,Object? total = null,}) {
  return _then(_self.copyWith(
deliveryCommissionsAmount: null == deliveryCommissionsAmount ? _self.deliveryCommissionsAmount : deliveryCommissionsAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCommissionsPercent: null == deliveryCommissionsPercent ? _self.deliveryCommissionsPercent : deliveryCommissionsPercent // ignore: cast_nullable_to_non_nullable
as double,challengeBonusesAmount: null == challengeBonusesAmount ? _self.challengeBonusesAmount : challengeBonusesAmount // ignore: cast_nullable_to_non_nullable
as double,challengeBonusesPercent: null == challengeBonusesPercent ? _self.challengeBonusesPercent : challengeBonusesPercent // ignore: cast_nullable_to_non_nullable
as double,rushBonusesAmount: null == rushBonusesAmount ? _self.rushBonusesAmount : rushBonusesAmount // ignore: cast_nullable_to_non_nullable
as double,rushBonusesPercent: null == rushBonusesPercent ? _self.rushBonusesPercent : rushBonusesPercent // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}

}


/// Adds pattern-matching-related methods to [RevenueBreakdown].
extension RevenueBreakdownPatterns on RevenueBreakdown {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _RevenueBreakdown value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _RevenueBreakdown() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _RevenueBreakdown value)  $default,){
final _that = this;
switch (_that) {
case _RevenueBreakdown():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _RevenueBreakdown value)?  $default,){
final _that = this;
switch (_that) {
case _RevenueBreakdown() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double deliveryCommissionsAmount,  double deliveryCommissionsPercent,  double challengeBonusesAmount,  double challengeBonusesPercent,  double rushBonusesAmount,  double rushBonusesPercent,  double total)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _RevenueBreakdown() when $default != null:
return $default(_that.deliveryCommissionsAmount,_that.deliveryCommissionsPercent,_that.challengeBonusesAmount,_that.challengeBonusesPercent,_that.rushBonusesAmount,_that.rushBonusesPercent,_that.total);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double deliveryCommissionsAmount,  double deliveryCommissionsPercent,  double challengeBonusesAmount,  double challengeBonusesPercent,  double rushBonusesAmount,  double rushBonusesPercent,  double total)  $default,) {final _that = this;
switch (_that) {
case _RevenueBreakdown():
return $default(_that.deliveryCommissionsAmount,_that.deliveryCommissionsPercent,_that.challengeBonusesAmount,_that.challengeBonusesPercent,_that.rushBonusesAmount,_that.rushBonusesPercent,_that.total);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double deliveryCommissionsAmount,  double deliveryCommissionsPercent,  double challengeBonusesAmount,  double challengeBonusesPercent,  double rushBonusesAmount,  double rushBonusesPercent,  double total)?  $default,) {final _that = this;
switch (_that) {
case _RevenueBreakdown() when $default != null:
return $default(_that.deliveryCommissionsAmount,_that.deliveryCommissionsPercent,_that.challengeBonusesAmount,_that.challengeBonusesPercent,_that.rushBonusesAmount,_that.rushBonusesPercent,_that.total);case _:
  return null;

}
}

}

/// @nodoc


class _RevenueBreakdown extends RevenueBreakdown {
  const _RevenueBreakdown({this.deliveryCommissionsAmount = 0.0, this.deliveryCommissionsPercent = 0.0, this.challengeBonusesAmount = 0.0, this.challengeBonusesPercent = 0.0, this.rushBonusesAmount = 0.0, this.rushBonusesPercent = 0.0, this.total = 0.0}): super._();
  

@override@JsonKey() final  double deliveryCommissionsAmount;
@override@JsonKey() final  double deliveryCommissionsPercent;
@override@JsonKey() final  double challengeBonusesAmount;
@override@JsonKey() final  double challengeBonusesPercent;
@override@JsonKey() final  double rushBonusesAmount;
@override@JsonKey() final  double rushBonusesPercent;
@override@JsonKey() final  double total;

/// Create a copy of RevenueBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$RevenueBreakdownCopyWith<_RevenueBreakdown> get copyWith => __$RevenueBreakdownCopyWithImpl<_RevenueBreakdown>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _RevenueBreakdown&&(identical(other.deliveryCommissionsAmount, deliveryCommissionsAmount) || other.deliveryCommissionsAmount == deliveryCommissionsAmount)&&(identical(other.deliveryCommissionsPercent, deliveryCommissionsPercent) || other.deliveryCommissionsPercent == deliveryCommissionsPercent)&&(identical(other.challengeBonusesAmount, challengeBonusesAmount) || other.challengeBonusesAmount == challengeBonusesAmount)&&(identical(other.challengeBonusesPercent, challengeBonusesPercent) || other.challengeBonusesPercent == challengeBonusesPercent)&&(identical(other.rushBonusesAmount, rushBonusesAmount) || other.rushBonusesAmount == rushBonusesAmount)&&(identical(other.rushBonusesPercent, rushBonusesPercent) || other.rushBonusesPercent == rushBonusesPercent)&&(identical(other.total, total) || other.total == total));
}


@override
int get hashCode => Object.hash(runtimeType,deliveryCommissionsAmount,deliveryCommissionsPercent,challengeBonusesAmount,challengeBonusesPercent,rushBonusesAmount,rushBonusesPercent,total);

@override
String toString() {
  return 'RevenueBreakdown(deliveryCommissionsAmount: $deliveryCommissionsAmount, deliveryCommissionsPercent: $deliveryCommissionsPercent, challengeBonusesAmount: $challengeBonusesAmount, challengeBonusesPercent: $challengeBonusesPercent, rushBonusesAmount: $rushBonusesAmount, rushBonusesPercent: $rushBonusesPercent, total: $total)';
}


}

/// @nodoc
abstract mixin class _$RevenueBreakdownCopyWith<$Res> implements $RevenueBreakdownCopyWith<$Res> {
  factory _$RevenueBreakdownCopyWith(_RevenueBreakdown value, $Res Function(_RevenueBreakdown) _then) = __$RevenueBreakdownCopyWithImpl;
@override @useResult
$Res call({
 double deliveryCommissionsAmount, double deliveryCommissionsPercent, double challengeBonusesAmount, double challengeBonusesPercent, double rushBonusesAmount, double rushBonusesPercent, double total
});




}
/// @nodoc
class __$RevenueBreakdownCopyWithImpl<$Res>
    implements _$RevenueBreakdownCopyWith<$Res> {
  __$RevenueBreakdownCopyWithImpl(this._self, this._then);

  final _RevenueBreakdown _self;
  final $Res Function(_RevenueBreakdown) _then;

/// Create a copy of RevenueBreakdown
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? deliveryCommissionsAmount = null,Object? deliveryCommissionsPercent = null,Object? challengeBonusesAmount = null,Object? challengeBonusesPercent = null,Object? rushBonusesAmount = null,Object? rushBonusesPercent = null,Object? total = null,}) {
  return _then(_RevenueBreakdown(
deliveryCommissionsAmount: null == deliveryCommissionsAmount ? _self.deliveryCommissionsAmount : deliveryCommissionsAmount // ignore: cast_nullable_to_non_nullable
as double,deliveryCommissionsPercent: null == deliveryCommissionsPercent ? _self.deliveryCommissionsPercent : deliveryCommissionsPercent // ignore: cast_nullable_to_non_nullable
as double,challengeBonusesAmount: null == challengeBonusesAmount ? _self.challengeBonusesAmount : challengeBonusesAmount // ignore: cast_nullable_to_non_nullable
as double,challengeBonusesPercent: null == challengeBonusesPercent ? _self.challengeBonusesPercent : challengeBonusesPercent // ignore: cast_nullable_to_non_nullable
as double,rushBonusesAmount: null == rushBonusesAmount ? _self.rushBonusesAmount : rushBonusesAmount // ignore: cast_nullable_to_non_nullable
as double,rushBonusesPercent: null == rushBonusesPercent ? _self.rushBonusesPercent : rushBonusesPercent // ignore: cast_nullable_to_non_nullable
as double,total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as double,
  ));
}


}


/// @nodoc
mixin _$StatsGoals {

@JsonKey(name: 'weekly_target', fromJson: safeInt) int get weeklyTarget;@JsonKey(name: 'current_progress', fromJson: safeInt) int get currentProgress;@JsonKey(name: 'progress_percentage', fromJson: safeDouble) double get progressPercentage;@JsonKey(fromJson: safeInt) int get remaining;
/// Create a copy of StatsGoals
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$StatsGoalsCopyWith<StatsGoals> get copyWith => _$StatsGoalsCopyWithImpl<StatsGoals>(this as StatsGoals, _$identity);

  /// Serializes this StatsGoals to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is StatsGoals&&(identical(other.weeklyTarget, weeklyTarget) || other.weeklyTarget == weeklyTarget)&&(identical(other.currentProgress, currentProgress) || other.currentProgress == currentProgress)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.remaining, remaining) || other.remaining == remaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weeklyTarget,currentProgress,progressPercentage,remaining);

@override
String toString() {
  return 'StatsGoals(weeklyTarget: $weeklyTarget, currentProgress: $currentProgress, progressPercentage: $progressPercentage, remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class $StatsGoalsCopyWith<$Res>  {
  factory $StatsGoalsCopyWith(StatsGoals value, $Res Function(StatsGoals) _then) = _$StatsGoalsCopyWithImpl;
@useResult
$Res call({
@JsonKey(name: 'weekly_target', fromJson: safeInt) int weeklyTarget,@JsonKey(name: 'current_progress', fromJson: safeInt) int currentProgress,@JsonKey(name: 'progress_percentage', fromJson: safeDouble) double progressPercentage,@JsonKey(fromJson: safeInt) int remaining
});




}
/// @nodoc
class _$StatsGoalsCopyWithImpl<$Res>
    implements $StatsGoalsCopyWith<$Res> {
  _$StatsGoalsCopyWithImpl(this._self, this._then);

  final StatsGoals _self;
  final $Res Function(StatsGoals) _then;

/// Create a copy of StatsGoals
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? weeklyTarget = null,Object? currentProgress = null,Object? progressPercentage = null,Object? remaining = null,}) {
  return _then(_self.copyWith(
weeklyTarget: null == weeklyTarget ? _self.weeklyTarget : weeklyTarget // ignore: cast_nullable_to_non_nullable
as int,currentProgress: null == currentProgress ? _self.currentProgress : currentProgress // ignore: cast_nullable_to_non_nullable
as int,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [StatsGoals].
extension StatsGoalsPatterns on StatsGoals {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _StatsGoals value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _StatsGoals() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _StatsGoals value)  $default,){
final _that = this;
switch (_that) {
case _StatsGoals():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _StatsGoals value)?  $default,){
final _that = this;
switch (_that) {
case _StatsGoals() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function(@JsonKey(name: 'weekly_target', fromJson: safeInt)  int weeklyTarget, @JsonKey(name: 'current_progress', fromJson: safeInt)  int currentProgress, @JsonKey(name: 'progress_percentage', fromJson: safeDouble)  double progressPercentage, @JsonKey(fromJson: safeInt)  int remaining)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _StatsGoals() when $default != null:
return $default(_that.weeklyTarget,_that.currentProgress,_that.progressPercentage,_that.remaining);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function(@JsonKey(name: 'weekly_target', fromJson: safeInt)  int weeklyTarget, @JsonKey(name: 'current_progress', fromJson: safeInt)  int currentProgress, @JsonKey(name: 'progress_percentage', fromJson: safeDouble)  double progressPercentage, @JsonKey(fromJson: safeInt)  int remaining)  $default,) {final _that = this;
switch (_that) {
case _StatsGoals():
return $default(_that.weeklyTarget,_that.currentProgress,_that.progressPercentage,_that.remaining);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function(@JsonKey(name: 'weekly_target', fromJson: safeInt)  int weeklyTarget, @JsonKey(name: 'current_progress', fromJson: safeInt)  int currentProgress, @JsonKey(name: 'progress_percentage', fromJson: safeDouble)  double progressPercentage, @JsonKey(fromJson: safeInt)  int remaining)?  $default,) {final _that = this;
switch (_that) {
case _StatsGoals() when $default != null:
return $default(_that.weeklyTarget,_that.currentProgress,_that.progressPercentage,_that.remaining);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _StatsGoals implements StatsGoals {
  const _StatsGoals({@JsonKey(name: 'weekly_target', fromJson: safeInt) this.weeklyTarget = 0, @JsonKey(name: 'current_progress', fromJson: safeInt) this.currentProgress = 0, @JsonKey(name: 'progress_percentage', fromJson: safeDouble) this.progressPercentage = 0.0, @JsonKey(fromJson: safeInt) this.remaining = 0});
  factory _StatsGoals.fromJson(Map<String, dynamic> json) => _$StatsGoalsFromJson(json);

@override@JsonKey(name: 'weekly_target', fromJson: safeInt) final  int weeklyTarget;
@override@JsonKey(name: 'current_progress', fromJson: safeInt) final  int currentProgress;
@override@JsonKey(name: 'progress_percentage', fromJson: safeDouble) final  double progressPercentage;
@override@JsonKey(fromJson: safeInt) final  int remaining;

/// Create a copy of StatsGoals
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$StatsGoalsCopyWith<_StatsGoals> get copyWith => __$StatsGoalsCopyWithImpl<_StatsGoals>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$StatsGoalsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _StatsGoals&&(identical(other.weeklyTarget, weeklyTarget) || other.weeklyTarget == weeklyTarget)&&(identical(other.currentProgress, currentProgress) || other.currentProgress == currentProgress)&&(identical(other.progressPercentage, progressPercentage) || other.progressPercentage == progressPercentage)&&(identical(other.remaining, remaining) || other.remaining == remaining));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,weeklyTarget,currentProgress,progressPercentage,remaining);

@override
String toString() {
  return 'StatsGoals(weeklyTarget: $weeklyTarget, currentProgress: $currentProgress, progressPercentage: $progressPercentage, remaining: $remaining)';
}


}

/// @nodoc
abstract mixin class _$StatsGoalsCopyWith<$Res> implements $StatsGoalsCopyWith<$Res> {
  factory _$StatsGoalsCopyWith(_StatsGoals value, $Res Function(_StatsGoals) _then) = __$StatsGoalsCopyWithImpl;
@override @useResult
$Res call({
@JsonKey(name: 'weekly_target', fromJson: safeInt) int weeklyTarget,@JsonKey(name: 'current_progress', fromJson: safeInt) int currentProgress,@JsonKey(name: 'progress_percentage', fromJson: safeDouble) double progressPercentage,@JsonKey(fromJson: safeInt) int remaining
});




}
/// @nodoc
class __$StatsGoalsCopyWithImpl<$Res>
    implements _$StatsGoalsCopyWith<$Res> {
  __$StatsGoalsCopyWithImpl(this._self, this._then);

  final _StatsGoals _self;
  final $Res Function(_StatsGoals) _then;

/// Create a copy of StatsGoals
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? weeklyTarget = null,Object? currentProgress = null,Object? progressPercentage = null,Object? remaining = null,}) {
  return _then(_StatsGoals(
weeklyTarget: null == weeklyTarget ? _self.weeklyTarget : weeklyTarget // ignore: cast_nullable_to_non_nullable
as int,currentProgress: null == currentProgress ? _self.currentProgress : currentProgress // ignore: cast_nullable_to_non_nullable
as int,progressPercentage: null == progressPercentage ? _self.progressPercentage : progressPercentage // ignore: cast_nullable_to_non_nullable
as double,remaining: null == remaining ? _self.remaining : remaining // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
