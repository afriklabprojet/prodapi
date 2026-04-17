// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'wallet_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;
/// @nodoc
mixin _$WalletData {

 double get balance; String get currency; List<WalletTransaction> get transactions; double? get pendingPayouts; double? get availableBalance; bool get canDeliver; int get commissionAmount; double get totalTopups; double get totalEarnings; double get todayEarnings; double get totalCommissions; int get deliveriesCount;
/// Create a copy of WalletData
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletDataCopyWith<WalletData> get copyWith => _$WalletDataCopyWithImpl<WalletData>(this as WalletData, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletData&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other.transactions, transactions)&&(identical(other.pendingPayouts, pendingPayouts) || other.pendingPayouts == pendingPayouts)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.canDeliver, canDeliver) || other.canDeliver == canDeliver)&&(identical(other.commissionAmount, commissionAmount) || other.commissionAmount == commissionAmount)&&(identical(other.totalTopups, totalTopups) || other.totalTopups == totalTopups)&&(identical(other.totalEarnings, totalEarnings) || other.totalEarnings == totalEarnings)&&(identical(other.todayEarnings, todayEarnings) || other.todayEarnings == todayEarnings)&&(identical(other.totalCommissions, totalCommissions) || other.totalCommissions == totalCommissions)&&(identical(other.deliveriesCount, deliveriesCount) || other.deliveriesCount == deliveriesCount));
}


@override
int get hashCode => Object.hash(runtimeType,balance,currency,const DeepCollectionEquality().hash(transactions),pendingPayouts,availableBalance,canDeliver,commissionAmount,totalTopups,totalEarnings,todayEarnings,totalCommissions,deliveriesCount);

@override
String toString() {
  return 'WalletData(balance: $balance, currency: $currency, transactions: $transactions, pendingPayouts: $pendingPayouts, availableBalance: $availableBalance, canDeliver: $canDeliver, commissionAmount: $commissionAmount, totalTopups: $totalTopups, totalEarnings: $totalEarnings, todayEarnings: $todayEarnings, totalCommissions: $totalCommissions, deliveriesCount: $deliveriesCount)';
}


}

/// @nodoc
abstract mixin class $WalletDataCopyWith<$Res>  {
  factory $WalletDataCopyWith(WalletData value, $Res Function(WalletData) _then) = _$WalletDataCopyWithImpl;
@useResult
$Res call({
 double balance, String currency, List<WalletTransaction> transactions, double? pendingPayouts, double? availableBalance, bool canDeliver, int commissionAmount, double totalTopups, double totalEarnings, double todayEarnings, double totalCommissions, int deliveriesCount
});




}
/// @nodoc
class _$WalletDataCopyWithImpl<$Res>
    implements $WalletDataCopyWith<$Res> {
  _$WalletDataCopyWithImpl(this._self, this._then);

  final WalletData _self;
  final $Res Function(WalletData) _then;

/// Create a copy of WalletData
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? balance = null,Object? currency = null,Object? transactions = null,Object? pendingPayouts = freezed,Object? availableBalance = freezed,Object? canDeliver = null,Object? commissionAmount = null,Object? totalTopups = null,Object? totalEarnings = null,Object? todayEarnings = null,Object? totalCommissions = null,Object? deliveriesCount = null,}) {
  return _then(_self.copyWith(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactions: null == transactions ? _self.transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<WalletTransaction>,pendingPayouts: freezed == pendingPayouts ? _self.pendingPayouts : pendingPayouts // ignore: cast_nullable_to_non_nullable
as double?,availableBalance: freezed == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as double?,canDeliver: null == canDeliver ? _self.canDeliver : canDeliver // ignore: cast_nullable_to_non_nullable
as bool,commissionAmount: null == commissionAmount ? _self.commissionAmount : commissionAmount // ignore: cast_nullable_to_non_nullable
as int,totalTopups: null == totalTopups ? _self.totalTopups : totalTopups // ignore: cast_nullable_to_non_nullable
as double,totalEarnings: null == totalEarnings ? _self.totalEarnings : totalEarnings // ignore: cast_nullable_to_non_nullable
as double,todayEarnings: null == todayEarnings ? _self.todayEarnings : todayEarnings // ignore: cast_nullable_to_non_nullable
as double,totalCommissions: null == totalCommissions ? _self.totalCommissions : totalCommissions // ignore: cast_nullable_to_non_nullable
as double,deliveriesCount: null == deliveriesCount ? _self.deliveriesCount : deliveriesCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletData].
extension WalletDataPatterns on WalletData {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletData value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletData() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletData value)  $default,){
final _that = this;
switch (_that) {
case _WalletData():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletData value)?  $default,){
final _that = this;
switch (_that) {
case _WalletData() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( double balance,  String currency,  List<WalletTransaction> transactions,  double? pendingPayouts,  double? availableBalance,  bool canDeliver,  int commissionAmount,  double totalTopups,  double totalEarnings,  double todayEarnings,  double totalCommissions,  int deliveriesCount)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletData() when $default != null:
return $default(_that.balance,_that.currency,_that.transactions,_that.pendingPayouts,_that.availableBalance,_that.canDeliver,_that.commissionAmount,_that.totalTopups,_that.totalEarnings,_that.todayEarnings,_that.totalCommissions,_that.deliveriesCount);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( double balance,  String currency,  List<WalletTransaction> transactions,  double? pendingPayouts,  double? availableBalance,  bool canDeliver,  int commissionAmount,  double totalTopups,  double totalEarnings,  double todayEarnings,  double totalCommissions,  int deliveriesCount)  $default,) {final _that = this;
switch (_that) {
case _WalletData():
return $default(_that.balance,_that.currency,_that.transactions,_that.pendingPayouts,_that.availableBalance,_that.canDeliver,_that.commissionAmount,_that.totalTopups,_that.totalEarnings,_that.todayEarnings,_that.totalCommissions,_that.deliveriesCount);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( double balance,  String currency,  List<WalletTransaction> transactions,  double? pendingPayouts,  double? availableBalance,  bool canDeliver,  int commissionAmount,  double totalTopups,  double totalEarnings,  double todayEarnings,  double totalCommissions,  int deliveriesCount)?  $default,) {final _that = this;
switch (_that) {
case _WalletData() when $default != null:
return $default(_that.balance,_that.currency,_that.transactions,_that.pendingPayouts,_that.availableBalance,_that.canDeliver,_that.commissionAmount,_that.totalTopups,_that.totalEarnings,_that.todayEarnings,_that.totalCommissions,_that.deliveriesCount);case _:
  return null;

}
}

}

/// @nodoc


class _WalletData implements WalletData {
  const _WalletData({required this.balance, this.currency = 'XOF', final  List<WalletTransaction> transactions = const [], this.pendingPayouts = 0.0, this.availableBalance, this.canDeliver = true, this.commissionAmount = 200, this.totalTopups = 0.0, this.totalEarnings = 0.0, this.todayEarnings = 0.0, this.totalCommissions = 0.0, this.deliveriesCount = 0}): _transactions = transactions;
  

@override final  double balance;
@override@JsonKey() final  String currency;
 final  List<WalletTransaction> _transactions;
@override@JsonKey() List<WalletTransaction> get transactions {
  if (_transactions is EqualUnmodifiableListView) return _transactions;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(_transactions);
}

@override@JsonKey() final  double? pendingPayouts;
@override final  double? availableBalance;
@override@JsonKey() final  bool canDeliver;
@override@JsonKey() final  int commissionAmount;
@override@JsonKey() final  double totalTopups;
@override@JsonKey() final  double totalEarnings;
@override@JsonKey() final  double todayEarnings;
@override@JsonKey() final  double totalCommissions;
@override@JsonKey() final  int deliveriesCount;

/// Create a copy of WalletData
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletDataCopyWith<_WalletData> get copyWith => __$WalletDataCopyWithImpl<_WalletData>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletData&&(identical(other.balance, balance) || other.balance == balance)&&(identical(other.currency, currency) || other.currency == currency)&&const DeepCollectionEquality().equals(other._transactions, _transactions)&&(identical(other.pendingPayouts, pendingPayouts) || other.pendingPayouts == pendingPayouts)&&(identical(other.availableBalance, availableBalance) || other.availableBalance == availableBalance)&&(identical(other.canDeliver, canDeliver) || other.canDeliver == canDeliver)&&(identical(other.commissionAmount, commissionAmount) || other.commissionAmount == commissionAmount)&&(identical(other.totalTopups, totalTopups) || other.totalTopups == totalTopups)&&(identical(other.totalEarnings, totalEarnings) || other.totalEarnings == totalEarnings)&&(identical(other.todayEarnings, todayEarnings) || other.todayEarnings == todayEarnings)&&(identical(other.totalCommissions, totalCommissions) || other.totalCommissions == totalCommissions)&&(identical(other.deliveriesCount, deliveriesCount) || other.deliveriesCount == deliveriesCount));
}


@override
int get hashCode => Object.hash(runtimeType,balance,currency,const DeepCollectionEquality().hash(_transactions),pendingPayouts,availableBalance,canDeliver,commissionAmount,totalTopups,totalEarnings,todayEarnings,totalCommissions,deliveriesCount);

@override
String toString() {
  return 'WalletData(balance: $balance, currency: $currency, transactions: $transactions, pendingPayouts: $pendingPayouts, availableBalance: $availableBalance, canDeliver: $canDeliver, commissionAmount: $commissionAmount, totalTopups: $totalTopups, totalEarnings: $totalEarnings, todayEarnings: $todayEarnings, totalCommissions: $totalCommissions, deliveriesCount: $deliveriesCount)';
}


}

/// @nodoc
abstract mixin class _$WalletDataCopyWith<$Res> implements $WalletDataCopyWith<$Res> {
  factory _$WalletDataCopyWith(_WalletData value, $Res Function(_WalletData) _then) = __$WalletDataCopyWithImpl;
@override @useResult
$Res call({
 double balance, String currency, List<WalletTransaction> transactions, double? pendingPayouts, double? availableBalance, bool canDeliver, int commissionAmount, double totalTopups, double totalEarnings, double todayEarnings, double totalCommissions, int deliveriesCount
});




}
/// @nodoc
class __$WalletDataCopyWithImpl<$Res>
    implements _$WalletDataCopyWith<$Res> {
  __$WalletDataCopyWithImpl(this._self, this._then);

  final _WalletData _self;
  final $Res Function(_WalletData) _then;

/// Create a copy of WalletData
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? balance = null,Object? currency = null,Object? transactions = null,Object? pendingPayouts = freezed,Object? availableBalance = freezed,Object? canDeliver = null,Object? commissionAmount = null,Object? totalTopups = null,Object? totalEarnings = null,Object? todayEarnings = null,Object? totalCommissions = null,Object? deliveriesCount = null,}) {
  return _then(_WalletData(
balance: null == balance ? _self.balance : balance // ignore: cast_nullable_to_non_nullable
as double,currency: null == currency ? _self.currency : currency // ignore: cast_nullable_to_non_nullable
as String,transactions: null == transactions ? _self._transactions : transactions // ignore: cast_nullable_to_non_nullable
as List<WalletTransaction>,pendingPayouts: freezed == pendingPayouts ? _self.pendingPayouts : pendingPayouts // ignore: cast_nullable_to_non_nullable
as double?,availableBalance: freezed == availableBalance ? _self.availableBalance : availableBalance // ignore: cast_nullable_to_non_nullable
as double?,canDeliver: null == canDeliver ? _self.canDeliver : canDeliver // ignore: cast_nullable_to_non_nullable
as bool,commissionAmount: null == commissionAmount ? _self.commissionAmount : commissionAmount // ignore: cast_nullable_to_non_nullable
as int,totalTopups: null == totalTopups ? _self.totalTopups : totalTopups // ignore: cast_nullable_to_non_nullable
as double,totalEarnings: null == totalEarnings ? _self.totalEarnings : totalEarnings // ignore: cast_nullable_to_non_nullable
as double,todayEarnings: null == todayEarnings ? _self.todayEarnings : todayEarnings // ignore: cast_nullable_to_non_nullable
as double,totalCommissions: null == totalCommissions ? _self.totalCommissions : totalCommissions // ignore: cast_nullable_to_non_nullable
as double,deliveriesCount: null == deliveriesCount ? _self.deliveriesCount : deliveriesCount // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

/// @nodoc
mixin _$WalletTransaction {

 int get id; double get amount; String get type; String? get category; String? get description; String? get reference; String? get status; int? get deliveryId; DateTime get createdAt;
/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$WalletTransactionCopyWith<WalletTransaction> get copyWith => _$WalletTransactionCopyWithImpl<WalletTransaction>(this as WalletTransaction, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is WalletTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,amount,type,category,description,reference,status,deliveryId,createdAt);

@override
String toString() {
  return 'WalletTransaction(id: $id, amount: $amount, type: $type, category: $category, description: $description, reference: $reference, status: $status, deliveryId: $deliveryId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class $WalletTransactionCopyWith<$Res>  {
  factory $WalletTransactionCopyWith(WalletTransaction value, $Res Function(WalletTransaction) _then) = _$WalletTransactionCopyWithImpl;
@useResult
$Res call({
 int id, double amount, String type, String? category, String? description, String? reference, String? status, int? deliveryId, DateTime createdAt
});




}
/// @nodoc
class _$WalletTransactionCopyWithImpl<$Res>
    implements $WalletTransactionCopyWith<$Res> {
  _$WalletTransactionCopyWithImpl(this._self, this._then);

  final WalletTransaction _self;
  final $Res Function(WalletTransaction) _then;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? amount = null,Object? type = null,Object? category = freezed,Object? description = freezed,Object? reference = freezed,Object? status = freezed,Object? deliveryId = freezed,Object? createdAt = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,deliveryId: freezed == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}

}


/// Adds pattern-matching-related methods to [WalletTransaction].
extension WalletTransactionPatterns on WalletTransaction {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _WalletTransaction value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _WalletTransaction value)  $default,){
final _that = this;
switch (_that) {
case _WalletTransaction():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _WalletTransaction value)?  $default,){
final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  double amount,  String type,  String? category,  String? description,  String? reference,  String? status,  int? deliveryId,  DateTime createdAt)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that.id,_that.amount,_that.type,_that.category,_that.description,_that.reference,_that.status,_that.deliveryId,_that.createdAt);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  double amount,  String type,  String? category,  String? description,  String? reference,  String? status,  int? deliveryId,  DateTime createdAt)  $default,) {final _that = this;
switch (_that) {
case _WalletTransaction():
return $default(_that.id,_that.amount,_that.type,_that.category,_that.description,_that.reference,_that.status,_that.deliveryId,_that.createdAt);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  double amount,  String type,  String? category,  String? description,  String? reference,  String? status,  int? deliveryId,  DateTime createdAt)?  $default,) {final _that = this;
switch (_that) {
case _WalletTransaction() when $default != null:
return $default(_that.id,_that.amount,_that.type,_that.category,_that.description,_that.reference,_that.status,_that.deliveryId,_that.createdAt);case _:
  return null;

}
}

}

/// @nodoc


class _WalletTransaction extends WalletTransaction {
  const _WalletTransaction({required this.id, required this.amount, this.type = 'debit', this.category, this.description, this.reference, this.status, this.deliveryId, required this.createdAt}): super._();
  

@override final  int id;
@override final  double amount;
@override@JsonKey() final  String type;
@override final  String? category;
@override final  String? description;
@override final  String? reference;
@override final  String? status;
@override final  int? deliveryId;
@override final  DateTime createdAt;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$WalletTransactionCopyWith<_WalletTransaction> get copyWith => __$WalletTransactionCopyWithImpl<_WalletTransaction>(this, _$identity);



@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _WalletTransaction&&(identical(other.id, id) || other.id == id)&&(identical(other.amount, amount) || other.amount == amount)&&(identical(other.type, type) || other.type == type)&&(identical(other.category, category) || other.category == category)&&(identical(other.description, description) || other.description == description)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.status, status) || other.status == status)&&(identical(other.deliveryId, deliveryId) || other.deliveryId == deliveryId)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt));
}


@override
int get hashCode => Object.hash(runtimeType,id,amount,type,category,description,reference,status,deliveryId,createdAt);

@override
String toString() {
  return 'WalletTransaction(id: $id, amount: $amount, type: $type, category: $category, description: $description, reference: $reference, status: $status, deliveryId: $deliveryId, createdAt: $createdAt)';
}


}

/// @nodoc
abstract mixin class _$WalletTransactionCopyWith<$Res> implements $WalletTransactionCopyWith<$Res> {
  factory _$WalletTransactionCopyWith(_WalletTransaction value, $Res Function(_WalletTransaction) _then) = __$WalletTransactionCopyWithImpl;
@override @useResult
$Res call({
 int id, double amount, String type, String? category, String? description, String? reference, String? status, int? deliveryId, DateTime createdAt
});




}
/// @nodoc
class __$WalletTransactionCopyWithImpl<$Res>
    implements _$WalletTransactionCopyWith<$Res> {
  __$WalletTransactionCopyWithImpl(this._self, this._then);

  final _WalletTransaction _self;
  final $Res Function(_WalletTransaction) _then;

/// Create a copy of WalletTransaction
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? amount = null,Object? type = null,Object? category = freezed,Object? description = freezed,Object? reference = freezed,Object? status = freezed,Object? deliveryId = freezed,Object? createdAt = null,}) {
  return _then(_WalletTransaction(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,amount: null == amount ? _self.amount : amount // ignore: cast_nullable_to_non_nullable
as double,type: null == type ? _self.type : type // ignore: cast_nullable_to_non_nullable
as String,category: freezed == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String?,description: freezed == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String?,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,status: freezed == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String?,deliveryId: freezed == deliveryId ? _self.deliveryId : deliveryId // ignore: cast_nullable_to_non_nullable
as int?,createdAt: null == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as DateTime,
  ));
}


}

// dart format on
