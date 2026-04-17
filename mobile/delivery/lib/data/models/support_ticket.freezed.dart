// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'support_ticket.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SupportTicket {

 int get id;@JsonKey(name: 'user_id') int get userId; String get subject; String get description; String get category; String get priority; String get status; String? get reference;@JsonKey(name: 'resolved_at') String? get resolvedAt;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt;@JsonKey(name: 'messages_count') int? get messagesCount;@JsonKey(name: 'unread_count') int? get unreadCount;@JsonKey(name: 'latest_message') SupportMessage? get latestMessage; List<SupportMessage>? get messages;
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportTicketCopyWith<SupportTicket> get copyWith => _$SupportTicketCopyWithImpl<SupportTicket>(this as SupportTicket, _$identity);

  /// Serializes this SupportTicket to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.messagesCount, messagesCount) || other.messagesCount == messagesCount)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.latestMessage, latestMessage) || other.latestMessage == latestMessage)&&const DeepCollectionEquality().equals(other.messages, messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,subject,description,category,priority,status,reference,resolvedAt,createdAt,updatedAt,messagesCount,unreadCount,latestMessage,const DeepCollectionEquality().hash(messages));

@override
String toString() {
  return 'SupportTicket(id: $id, userId: $userId, subject: $subject, description: $description, category: $category, priority: $priority, status: $status, reference: $reference, resolvedAt: $resolvedAt, createdAt: $createdAt, updatedAt: $updatedAt, messagesCount: $messagesCount, unreadCount: $unreadCount, latestMessage: $latestMessage, messages: $messages)';
}


}

/// @nodoc
abstract mixin class $SupportTicketCopyWith<$Res>  {
  factory $SupportTicketCopyWith(SupportTicket value, $Res Function(SupportTicket) _then) = _$SupportTicketCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'user_id') int userId, String subject, String description, String category, String priority, String status, String? reference,@JsonKey(name: 'resolved_at') String? resolvedAt,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'messages_count') int? messagesCount,@JsonKey(name: 'unread_count') int? unreadCount,@JsonKey(name: 'latest_message') SupportMessage? latestMessage, List<SupportMessage>? messages
});


$SupportMessageCopyWith<$Res>? get latestMessage;

}
/// @nodoc
class _$SupportTicketCopyWithImpl<$Res>
    implements $SupportTicketCopyWith<$Res> {
  _$SupportTicketCopyWithImpl(this._self, this._then);

  final SupportTicket _self;
  final $Res Function(SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? userId = null,Object? subject = null,Object? description = null,Object? category = null,Object? priority = null,Object? status = null,Object? reference = freezed,Object? resolvedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? messagesCount = freezed,Object? unreadCount = freezed,Object? latestMessage = freezed,Object? messages = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,messagesCount: freezed == messagesCount ? _self.messagesCount : messagesCount // ignore: cast_nullable_to_non_nullable
as int?,unreadCount: freezed == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int?,latestMessage: freezed == latestMessage ? _self.latestMessage : latestMessage // ignore: cast_nullable_to_non_nullable
as SupportMessage?,messages: freezed == messages ? _self.messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessage>?,
  ));
}
/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportMessageCopyWith<$Res>? get latestMessage {
    if (_self.latestMessage == null) {
    return null;
  }

  return $SupportMessageCopyWith<$Res>(_self.latestMessage!, (value) {
    return _then(_self.copyWith(latestMessage: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportTicket].
extension SupportTicketPatterns on SupportTicket {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportTicket value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportTicket value)  $default,){
final _that = this;
switch (_that) {
case _SupportTicket():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportTicket value)?  $default,){
final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_id')  int userId,  String subject,  String description,  String category,  String priority,  String status,  String? reference, @JsonKey(name: 'resolved_at')  String? resolvedAt, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'messages_count')  int? messagesCount, @JsonKey(name: 'unread_count')  int? unreadCount, @JsonKey(name: 'latest_message')  SupportMessage? latestMessage,  List<SupportMessage>? messages)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.userId,_that.subject,_that.description,_that.category,_that.priority,_that.status,_that.reference,_that.resolvedAt,_that.createdAt,_that.updatedAt,_that.messagesCount,_that.unreadCount,_that.latestMessage,_that.messages);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'user_id')  int userId,  String subject,  String description,  String category,  String priority,  String status,  String? reference, @JsonKey(name: 'resolved_at')  String? resolvedAt, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'messages_count')  int? messagesCount, @JsonKey(name: 'unread_count')  int? unreadCount, @JsonKey(name: 'latest_message')  SupportMessage? latestMessage,  List<SupportMessage>? messages)  $default,) {final _that = this;
switch (_that) {
case _SupportTicket():
return $default(_that.id,_that.userId,_that.subject,_that.description,_that.category,_that.priority,_that.status,_that.reference,_that.resolvedAt,_that.createdAt,_that.updatedAt,_that.messagesCount,_that.unreadCount,_that.latestMessage,_that.messages);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'user_id')  int userId,  String subject,  String description,  String category,  String priority,  String status,  String? reference, @JsonKey(name: 'resolved_at')  String? resolvedAt, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt, @JsonKey(name: 'messages_count')  int? messagesCount, @JsonKey(name: 'unread_count')  int? unreadCount, @JsonKey(name: 'latest_message')  SupportMessage? latestMessage,  List<SupportMessage>? messages)?  $default,) {final _that = this;
switch (_that) {
case _SupportTicket() when $default != null:
return $default(_that.id,_that.userId,_that.subject,_that.description,_that.category,_that.priority,_that.status,_that.reference,_that.resolvedAt,_that.createdAt,_that.updatedAt,_that.messagesCount,_that.unreadCount,_that.latestMessage,_that.messages);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportTicket implements SupportTicket {
  const _SupportTicket({required this.id, @JsonKey(name: 'user_id') required this.userId, required this.subject, required this.description, required this.category, required this.priority, required this.status, this.reference, @JsonKey(name: 'resolved_at') this.resolvedAt, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, @JsonKey(name: 'messages_count') this.messagesCount, @JsonKey(name: 'unread_count') this.unreadCount, @JsonKey(name: 'latest_message') this.latestMessage, final  List<SupportMessage>? messages}): _messages = messages;
  factory _SupportTicket.fromJson(Map<String, dynamic> json) => _$SupportTicketFromJson(json);

@override final  int id;
@override@JsonKey(name: 'user_id') final  int userId;
@override final  String subject;
@override final  String description;
@override final  String category;
@override final  String priority;
@override final  String status;
@override final  String? reference;
@override@JsonKey(name: 'resolved_at') final  String? resolvedAt;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;
@override@JsonKey(name: 'messages_count') final  int? messagesCount;
@override@JsonKey(name: 'unread_count') final  int? unreadCount;
@override@JsonKey(name: 'latest_message') final  SupportMessage? latestMessage;
 final  List<SupportMessage>? _messages;
@override List<SupportMessage>? get messages {
  final value = _messages;
  if (value == null) return null;
  if (_messages is EqualUnmodifiableListView) return _messages;
  // ignore: implicit_dynamic_type
  return EqualUnmodifiableListView(value);
}


/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportTicketCopyWith<_SupportTicket> get copyWith => __$SupportTicketCopyWithImpl<_SupportTicket>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportTicketToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportTicket&&(identical(other.id, id) || other.id == id)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.subject, subject) || other.subject == subject)&&(identical(other.description, description) || other.description == description)&&(identical(other.category, category) || other.category == category)&&(identical(other.priority, priority) || other.priority == priority)&&(identical(other.status, status) || other.status == status)&&(identical(other.reference, reference) || other.reference == reference)&&(identical(other.resolvedAt, resolvedAt) || other.resolvedAt == resolvedAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.messagesCount, messagesCount) || other.messagesCount == messagesCount)&&(identical(other.unreadCount, unreadCount) || other.unreadCount == unreadCount)&&(identical(other.latestMessage, latestMessage) || other.latestMessage == latestMessage)&&const DeepCollectionEquality().equals(other._messages, _messages));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,userId,subject,description,category,priority,status,reference,resolvedAt,createdAt,updatedAt,messagesCount,unreadCount,latestMessage,const DeepCollectionEquality().hash(_messages));

@override
String toString() {
  return 'SupportTicket(id: $id, userId: $userId, subject: $subject, description: $description, category: $category, priority: $priority, status: $status, reference: $reference, resolvedAt: $resolvedAt, createdAt: $createdAt, updatedAt: $updatedAt, messagesCount: $messagesCount, unreadCount: $unreadCount, latestMessage: $latestMessage, messages: $messages)';
}


}

/// @nodoc
abstract mixin class _$SupportTicketCopyWith<$Res> implements $SupportTicketCopyWith<$Res> {
  factory _$SupportTicketCopyWith(_SupportTicket value, $Res Function(_SupportTicket) _then) = __$SupportTicketCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'user_id') int userId, String subject, String description, String category, String priority, String status, String? reference,@JsonKey(name: 'resolved_at') String? resolvedAt,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt,@JsonKey(name: 'messages_count') int? messagesCount,@JsonKey(name: 'unread_count') int? unreadCount,@JsonKey(name: 'latest_message') SupportMessage? latestMessage, List<SupportMessage>? messages
});


@override $SupportMessageCopyWith<$Res>? get latestMessage;

}
/// @nodoc
class __$SupportTicketCopyWithImpl<$Res>
    implements _$SupportTicketCopyWith<$Res> {
  __$SupportTicketCopyWithImpl(this._self, this._then);

  final _SupportTicket _self;
  final $Res Function(_SupportTicket) _then;

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? userId = null,Object? subject = null,Object? description = null,Object? category = null,Object? priority = null,Object? status = null,Object? reference = freezed,Object? resolvedAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? messagesCount = freezed,Object? unreadCount = freezed,Object? latestMessage = freezed,Object? messages = freezed,}) {
  return _then(_SupportTicket(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,subject: null == subject ? _self.subject : subject // ignore: cast_nullable_to_non_nullable
as String,description: null == description ? _self.description : description // ignore: cast_nullable_to_non_nullable
as String,category: null == category ? _self.category : category // ignore: cast_nullable_to_non_nullable
as String,priority: null == priority ? _self.priority : priority // ignore: cast_nullable_to_non_nullable
as String,status: null == status ? _self.status : status // ignore: cast_nullable_to_non_nullable
as String,reference: freezed == reference ? _self.reference : reference // ignore: cast_nullable_to_non_nullable
as String?,resolvedAt: freezed == resolvedAt ? _self.resolvedAt : resolvedAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,messagesCount: freezed == messagesCount ? _self.messagesCount : messagesCount // ignore: cast_nullable_to_non_nullable
as int?,unreadCount: freezed == unreadCount ? _self.unreadCount : unreadCount // ignore: cast_nullable_to_non_nullable
as int?,latestMessage: freezed == latestMessage ? _self.latestMessage : latestMessage // ignore: cast_nullable_to_non_nullable
as SupportMessage?,messages: freezed == messages ? _self._messages : messages // ignore: cast_nullable_to_non_nullable
as List<SupportMessage>?,
  ));
}

/// Create a copy of SupportTicket
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportMessageCopyWith<$Res>? get latestMessage {
    if (_self.latestMessage == null) {
    return null;
  }

  return $SupportMessageCopyWith<$Res>(_self.latestMessage!, (value) {
    return _then(_self.copyWith(latestMessage: value));
  });
}
}


/// @nodoc
mixin _$SupportMessage {

 int get id;@JsonKey(name: 'support_ticket_id') int get supportTicketId;@JsonKey(name: 'user_id') int get userId; String get message; String? get attachment;@JsonKey(name: 'is_from_support') bool get isFromSupport;@JsonKey(name: 'read_at') String? get readAt;@JsonKey(name: 'created_at') String? get createdAt;@JsonKey(name: 'updated_at') String? get updatedAt; SupportUser? get user;
/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportMessageCopyWith<SupportMessage> get copyWith => _$SupportMessageCopyWithImpl<SupportMessage>(this as SupportMessage, _$identity);

  /// Serializes this SupportMessage to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.attachment, attachment) || other.attachment == attachment)&&(identical(other.isFromSupport, isFromSupport) || other.isFromSupport == isFromSupport)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,supportTicketId,userId,message,attachment,isFromSupport,readAt,createdAt,updatedAt,user);

@override
String toString() {
  return 'SupportMessage(id: $id, supportTicketId: $supportTicketId, userId: $userId, message: $message, attachment: $attachment, isFromSupport: $isFromSupport, readAt: $readAt, createdAt: $createdAt, updatedAt: $updatedAt, user: $user)';
}


}

/// @nodoc
abstract mixin class $SupportMessageCopyWith<$Res>  {
  factory $SupportMessageCopyWith(SupportMessage value, $Res Function(SupportMessage) _then) = _$SupportMessageCopyWithImpl;
@useResult
$Res call({
 int id,@JsonKey(name: 'support_ticket_id') int supportTicketId,@JsonKey(name: 'user_id') int userId, String message, String? attachment,@JsonKey(name: 'is_from_support') bool isFromSupport,@JsonKey(name: 'read_at') String? readAt,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt, SupportUser? user
});


$SupportUserCopyWith<$Res>? get user;

}
/// @nodoc
class _$SupportMessageCopyWithImpl<$Res>
    implements $SupportMessageCopyWith<$Res> {
  _$SupportMessageCopyWithImpl(this._self, this._then);

  final SupportMessage _self;
  final $Res Function(SupportMessage) _then;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? supportTicketId = null,Object? userId = null,Object? message = null,Object? attachment = freezed,Object? isFromSupport = null,Object? readAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? user = freezed,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,supportTicketId: null == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,attachment: freezed == attachment ? _self.attachment : attachment // ignore: cast_nullable_to_non_nullable
as String?,isFromSupport: null == isFromSupport ? _self.isFromSupport : isFromSupport // ignore: cast_nullable_to_non_nullable
as bool,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SupportUser?,
  ));
}
/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SupportUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// Adds pattern-matching-related methods to [SupportMessage].
extension SupportMessagePatterns on SupportMessage {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportMessage value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportMessage value)  $default,){
final _that = this;
switch (_that) {
case _SupportMessage():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportMessage value)?  $default,){
final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'support_ticket_id')  int supportTicketId, @JsonKey(name: 'user_id')  int userId,  String message,  String? attachment, @JsonKey(name: 'is_from_support')  bool isFromSupport, @JsonKey(name: 'read_at')  String? readAt, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt,  SupportUser? user)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that.id,_that.supportTicketId,_that.userId,_that.message,_that.attachment,_that.isFromSupport,_that.readAt,_that.createdAt,_that.updatedAt,_that.user);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id, @JsonKey(name: 'support_ticket_id')  int supportTicketId, @JsonKey(name: 'user_id')  int userId,  String message,  String? attachment, @JsonKey(name: 'is_from_support')  bool isFromSupport, @JsonKey(name: 'read_at')  String? readAt, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt,  SupportUser? user)  $default,) {final _that = this;
switch (_that) {
case _SupportMessage():
return $default(_that.id,_that.supportTicketId,_that.userId,_that.message,_that.attachment,_that.isFromSupport,_that.readAt,_that.createdAt,_that.updatedAt,_that.user);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id, @JsonKey(name: 'support_ticket_id')  int supportTicketId, @JsonKey(name: 'user_id')  int userId,  String message,  String? attachment, @JsonKey(name: 'is_from_support')  bool isFromSupport, @JsonKey(name: 'read_at')  String? readAt, @JsonKey(name: 'created_at')  String? createdAt, @JsonKey(name: 'updated_at')  String? updatedAt,  SupportUser? user)?  $default,) {final _that = this;
switch (_that) {
case _SupportMessage() when $default != null:
return $default(_that.id,_that.supportTicketId,_that.userId,_that.message,_that.attachment,_that.isFromSupport,_that.readAt,_that.createdAt,_that.updatedAt,_that.user);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportMessage implements SupportMessage {
  const _SupportMessage({required this.id, @JsonKey(name: 'support_ticket_id') required this.supportTicketId, @JsonKey(name: 'user_id') required this.userId, required this.message, this.attachment, @JsonKey(name: 'is_from_support') this.isFromSupport = false, @JsonKey(name: 'read_at') this.readAt, @JsonKey(name: 'created_at') this.createdAt, @JsonKey(name: 'updated_at') this.updatedAt, this.user});
  factory _SupportMessage.fromJson(Map<String, dynamic> json) => _$SupportMessageFromJson(json);

@override final  int id;
@override@JsonKey(name: 'support_ticket_id') final  int supportTicketId;
@override@JsonKey(name: 'user_id') final  int userId;
@override final  String message;
@override final  String? attachment;
@override@JsonKey(name: 'is_from_support') final  bool isFromSupport;
@override@JsonKey(name: 'read_at') final  String? readAt;
@override@JsonKey(name: 'created_at') final  String? createdAt;
@override@JsonKey(name: 'updated_at') final  String? updatedAt;
@override final  SupportUser? user;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportMessageCopyWith<_SupportMessage> get copyWith => __$SupportMessageCopyWithImpl<_SupportMessage>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportMessageToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportMessage&&(identical(other.id, id) || other.id == id)&&(identical(other.supportTicketId, supportTicketId) || other.supportTicketId == supportTicketId)&&(identical(other.userId, userId) || other.userId == userId)&&(identical(other.message, message) || other.message == message)&&(identical(other.attachment, attachment) || other.attachment == attachment)&&(identical(other.isFromSupport, isFromSupport) || other.isFromSupport == isFromSupport)&&(identical(other.readAt, readAt) || other.readAt == readAt)&&(identical(other.createdAt, createdAt) || other.createdAt == createdAt)&&(identical(other.updatedAt, updatedAt) || other.updatedAt == updatedAt)&&(identical(other.user, user) || other.user == user));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,supportTicketId,userId,message,attachment,isFromSupport,readAt,createdAt,updatedAt,user);

@override
String toString() {
  return 'SupportMessage(id: $id, supportTicketId: $supportTicketId, userId: $userId, message: $message, attachment: $attachment, isFromSupport: $isFromSupport, readAt: $readAt, createdAt: $createdAt, updatedAt: $updatedAt, user: $user)';
}


}

/// @nodoc
abstract mixin class _$SupportMessageCopyWith<$Res> implements $SupportMessageCopyWith<$Res> {
  factory _$SupportMessageCopyWith(_SupportMessage value, $Res Function(_SupportMessage) _then) = __$SupportMessageCopyWithImpl;
@override @useResult
$Res call({
 int id,@JsonKey(name: 'support_ticket_id') int supportTicketId,@JsonKey(name: 'user_id') int userId, String message, String? attachment,@JsonKey(name: 'is_from_support') bool isFromSupport,@JsonKey(name: 'read_at') String? readAt,@JsonKey(name: 'created_at') String? createdAt,@JsonKey(name: 'updated_at') String? updatedAt, SupportUser? user
});


@override $SupportUserCopyWith<$Res>? get user;

}
/// @nodoc
class __$SupportMessageCopyWithImpl<$Res>
    implements _$SupportMessageCopyWith<$Res> {
  __$SupportMessageCopyWithImpl(this._self, this._then);

  final _SupportMessage _self;
  final $Res Function(_SupportMessage) _then;

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? supportTicketId = null,Object? userId = null,Object? message = null,Object? attachment = freezed,Object? isFromSupport = null,Object? readAt = freezed,Object? createdAt = freezed,Object? updatedAt = freezed,Object? user = freezed,}) {
  return _then(_SupportMessage(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,supportTicketId: null == supportTicketId ? _self.supportTicketId : supportTicketId // ignore: cast_nullable_to_non_nullable
as int,userId: null == userId ? _self.userId : userId // ignore: cast_nullable_to_non_nullable
as int,message: null == message ? _self.message : message // ignore: cast_nullable_to_non_nullable
as String,attachment: freezed == attachment ? _self.attachment : attachment // ignore: cast_nullable_to_non_nullable
as String?,isFromSupport: null == isFromSupport ? _self.isFromSupport : isFromSupport // ignore: cast_nullable_to_non_nullable
as bool,readAt: freezed == readAt ? _self.readAt : readAt // ignore: cast_nullable_to_non_nullable
as String?,createdAt: freezed == createdAt ? _self.createdAt : createdAt // ignore: cast_nullable_to_non_nullable
as String?,updatedAt: freezed == updatedAt ? _self.updatedAt : updatedAt // ignore: cast_nullable_to_non_nullable
as String?,user: freezed == user ? _self.user : user // ignore: cast_nullable_to_non_nullable
as SupportUser?,
  ));
}

/// Create a copy of SupportMessage
/// with the given fields replaced by the non-null parameter values.
@override
@pragma('vm:prefer-inline')
$SupportUserCopyWith<$Res>? get user {
    if (_self.user == null) {
    return null;
  }

  return $SupportUserCopyWith<$Res>(_self.user!, (value) {
    return _then(_self.copyWith(user: value));
  });
}
}


/// @nodoc
mixin _$SupportUser {

 int get id; String get name;
/// Create a copy of SupportUser
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportUserCopyWith<SupportUser> get copyWith => _$SupportUserCopyWithImpl<SupportUser>(this as SupportUser, _$identity);

  /// Serializes this SupportUser to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'SupportUser(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class $SupportUserCopyWith<$Res>  {
  factory $SupportUserCopyWith(SupportUser value, $Res Function(SupportUser) _then) = _$SupportUserCopyWithImpl;
@useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class _$SupportUserCopyWithImpl<$Res>
    implements $SupportUserCopyWith<$Res> {
  _$SupportUserCopyWithImpl(this._self, this._then);

  final SupportUser _self;
  final $Res Function(SupportUser) _then;

/// Create a copy of SupportUser
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? id = null,Object? name = null,}) {
  return _then(_self.copyWith(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportUser].
extension SupportUserPatterns on SupportUser {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportUser value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportUser() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportUser value)  $default,){
final _that = this;
switch (_that) {
case _SupportUser():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportUser value)?  $default,){
final _that = this;
switch (_that) {
case _SupportUser() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int id,  String name)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportUser() when $default != null:
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int id,  String name)  $default,) {final _that = this;
switch (_that) {
case _SupportUser():
return $default(_that.id,_that.name);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int id,  String name)?  $default,) {final _that = this;
switch (_that) {
case _SupportUser() when $default != null:
return $default(_that.id,_that.name);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportUser implements SupportUser {
  const _SupportUser({required this.id, required this.name});
  factory _SupportUser.fromJson(Map<String, dynamic> json) => _$SupportUserFromJson(json);

@override final  int id;
@override final  String name;

/// Create a copy of SupportUser
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportUserCopyWith<_SupportUser> get copyWith => __$SupportUserCopyWithImpl<_SupportUser>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportUserToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportUser&&(identical(other.id, id) || other.id == id)&&(identical(other.name, name) || other.name == name));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,id,name);

@override
String toString() {
  return 'SupportUser(id: $id, name: $name)';
}


}

/// @nodoc
abstract mixin class _$SupportUserCopyWith<$Res> implements $SupportUserCopyWith<$Res> {
  factory _$SupportUserCopyWith(_SupportUser value, $Res Function(_SupportUser) _then) = __$SupportUserCopyWithImpl;
@override @useResult
$Res call({
 int id, String name
});




}
/// @nodoc
class __$SupportUserCopyWithImpl<$Res>
    implements _$SupportUserCopyWith<$Res> {
  __$SupportUserCopyWithImpl(this._self, this._then);

  final _SupportUser _self;
  final $Res Function(_SupportUser) _then;

/// Create a copy of SupportUser
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? id = null,Object? name = null,}) {
  return _then(_SupportUser(
id: null == id ? _self.id : id // ignore: cast_nullable_to_non_nullable
as int,name: null == name ? _self.name : name // ignore: cast_nullable_to_non_nullable
as String,
  ));
}


}


/// @nodoc
mixin _$SupportStats {

 int get total; int get open; int get resolved; int get closed;
/// Create a copy of SupportStats
/// with the given fields replaced by the non-null parameter values.
@JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
$SupportStatsCopyWith<SupportStats> get copyWith => _$SupportStatsCopyWithImpl<SupportStats>(this as SupportStats, _$identity);

  /// Serializes this SupportStats to a JSON map.
  Map<String, dynamic> toJson();


@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is SupportStats&&(identical(other.total, total) || other.total == total)&&(identical(other.open, open) || other.open == open)&&(identical(other.resolved, resolved) || other.resolved == resolved)&&(identical(other.closed, closed) || other.closed == closed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,open,resolved,closed);

@override
String toString() {
  return 'SupportStats(total: $total, open: $open, resolved: $resolved, closed: $closed)';
}


}

/// @nodoc
abstract mixin class $SupportStatsCopyWith<$Res>  {
  factory $SupportStatsCopyWith(SupportStats value, $Res Function(SupportStats) _then) = _$SupportStatsCopyWithImpl;
@useResult
$Res call({
 int total, int open, int resolved, int closed
});




}
/// @nodoc
class _$SupportStatsCopyWithImpl<$Res>
    implements $SupportStatsCopyWith<$Res> {
  _$SupportStatsCopyWithImpl(this._self, this._then);

  final SupportStats _self;
  final $Res Function(SupportStats) _then;

/// Create a copy of SupportStats
/// with the given fields replaced by the non-null parameter values.
@pragma('vm:prefer-inline') @override $Res call({Object? total = null,Object? open = null,Object? resolved = null,Object? closed = null,}) {
  return _then(_self.copyWith(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as int,resolved: null == resolved ? _self.resolved : resolved // ignore: cast_nullable_to_non_nullable
as int,closed: null == closed ? _self.closed : closed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}

}


/// Adds pattern-matching-related methods to [SupportStats].
extension SupportStatsPatterns on SupportStats {
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

@optionalTypeArgs TResult maybeMap<TResult extends Object?>(TResult Function( _SupportStats value)?  $default,{required TResult orElse(),}){
final _that = this;
switch (_that) {
case _SupportStats() when $default != null:
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

@optionalTypeArgs TResult map<TResult extends Object?>(TResult Function( _SupportStats value)  $default,){
final _that = this;
switch (_that) {
case _SupportStats():
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

@optionalTypeArgs TResult? mapOrNull<TResult extends Object?>(TResult? Function( _SupportStats value)?  $default,){
final _that = this;
switch (_that) {
case _SupportStats() when $default != null:
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

@optionalTypeArgs TResult maybeWhen<TResult extends Object?>(TResult Function( int total,  int open,  int resolved,  int closed)?  $default,{required TResult orElse(),}) {final _that = this;
switch (_that) {
case _SupportStats() when $default != null:
return $default(_that.total,_that.open,_that.resolved,_that.closed);case _:
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

@optionalTypeArgs TResult when<TResult extends Object?>(TResult Function( int total,  int open,  int resolved,  int closed)  $default,) {final _that = this;
switch (_that) {
case _SupportStats():
return $default(_that.total,_that.open,_that.resolved,_that.closed);case _:
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

@optionalTypeArgs TResult? whenOrNull<TResult extends Object?>(TResult? Function( int total,  int open,  int resolved,  int closed)?  $default,) {final _that = this;
switch (_that) {
case _SupportStats() when $default != null:
return $default(_that.total,_that.open,_that.resolved,_that.closed);case _:
  return null;

}
}

}

/// @nodoc
@JsonSerializable()

class _SupportStats implements SupportStats {
  const _SupportStats({this.total = 0, this.open = 0, this.resolved = 0, this.closed = 0});
  factory _SupportStats.fromJson(Map<String, dynamic> json) => _$SupportStatsFromJson(json);

@override@JsonKey() final  int total;
@override@JsonKey() final  int open;
@override@JsonKey() final  int resolved;
@override@JsonKey() final  int closed;

/// Create a copy of SupportStats
/// with the given fields replaced by the non-null parameter values.
@override @JsonKey(includeFromJson: false, includeToJson: false)
@pragma('vm:prefer-inline')
_$SupportStatsCopyWith<_SupportStats> get copyWith => __$SupportStatsCopyWithImpl<_SupportStats>(this, _$identity);

@override
Map<String, dynamic> toJson() {
  return _$SupportStatsToJson(this, );
}

@override
bool operator ==(Object other) {
  return identical(this, other) || (other.runtimeType == runtimeType&&other is _SupportStats&&(identical(other.total, total) || other.total == total)&&(identical(other.open, open) || other.open == open)&&(identical(other.resolved, resolved) || other.resolved == resolved)&&(identical(other.closed, closed) || other.closed == closed));
}

@JsonKey(includeFromJson: false, includeToJson: false)
@override
int get hashCode => Object.hash(runtimeType,total,open,resolved,closed);

@override
String toString() {
  return 'SupportStats(total: $total, open: $open, resolved: $resolved, closed: $closed)';
}


}

/// @nodoc
abstract mixin class _$SupportStatsCopyWith<$Res> implements $SupportStatsCopyWith<$Res> {
  factory _$SupportStatsCopyWith(_SupportStats value, $Res Function(_SupportStats) _then) = __$SupportStatsCopyWithImpl;
@override @useResult
$Res call({
 int total, int open, int resolved, int closed
});




}
/// @nodoc
class __$SupportStatsCopyWithImpl<$Res>
    implements _$SupportStatsCopyWith<$Res> {
  __$SupportStatsCopyWithImpl(this._self, this._then);

  final _SupportStats _self;
  final $Res Function(_SupportStats) _then;

/// Create a copy of SupportStats
/// with the given fields replaced by the non-null parameter values.
@override @pragma('vm:prefer-inline') $Res call({Object? total = null,Object? open = null,Object? resolved = null,Object? closed = null,}) {
  return _then(_SupportStats(
total: null == total ? _self.total : total // ignore: cast_nullable_to_non_nullable
as int,open: null == open ? _self.open : open // ignore: cast_nullable_to_non_nullable
as int,resolved: null == resolved ? _self.resolved : resolved // ignore: cast_nullable_to_non_nullable
as int,closed: null == closed ? _self.closed : closed // ignore: cast_nullable_to_non_nullable
as int,
  ));
}


}

// dart format on
