// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'sync_message.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SyncMessage {
  String get messageId;
  String get fromDeviceId;
  String get payload; // encrypted base64
  Map<String, int> get vectorClock;
  int get operationCount;
  DateTime get createdAt;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SyncMessageCopyWith<SyncMessage> get copyWith =>
      _$SyncMessageCopyWithImpl<SyncMessage>(this as SyncMessage, _$identity);

  /// Serializes this SyncMessage to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SyncMessage &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.fromDeviceId, fromDeviceId) ||
                other.fromDeviceId == fromDeviceId) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            const DeepCollectionEquality().equals(
              other.vectorClock,
              vectorClock,
            ) &&
            (identical(other.operationCount, operationCount) ||
                other.operationCount == operationCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    messageId,
    fromDeviceId,
    payload,
    const DeepCollectionEquality().hash(vectorClock),
    operationCount,
    createdAt,
  );

  @override
  String toString() {
    return 'SyncMessage(messageId: $messageId, fromDeviceId: $fromDeviceId, payload: $payload, vectorClock: $vectorClock, operationCount: $operationCount, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class $SyncMessageCopyWith<$Res> {
  factory $SyncMessageCopyWith(
    SyncMessage value,
    $Res Function(SyncMessage) _then,
  ) = _$SyncMessageCopyWithImpl;
  @useResult
  $Res call({
    String messageId,
    String fromDeviceId,
    String payload,
    Map<String, int> vectorClock,
    int operationCount,
    DateTime createdAt,
  });
}

/// @nodoc
class _$SyncMessageCopyWithImpl<$Res> implements $SyncMessageCopyWith<$Res> {
  _$SyncMessageCopyWithImpl(this._self, this._then);

  final SyncMessage _self;
  final $Res Function(SyncMessage) _then;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? messageId = null,
    Object? fromDeviceId = null,
    Object? payload = null,
    Object? vectorClock = null,
    Object? operationCount = null,
    Object? createdAt = null,
  }) {
    return _then(
      _self.copyWith(
        messageId: null == messageId
            ? _self.messageId
            : messageId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromDeviceId: null == fromDeviceId
            ? _self.fromDeviceId
            : fromDeviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        payload: null == payload
            ? _self.payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as String,
        vectorClock: null == vectorClock
            ? _self.vectorClock
            : vectorClock // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        operationCount: null == operationCount
            ? _self.operationCount
            : operationCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [SyncMessage].
extension SyncMessagePatterns on SyncMessage {
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

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_SyncMessage value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_SyncMessage value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage():
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_SyncMessage value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
        return $default(_that);
      case _:
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

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
      String messageId,
      String fromDeviceId,
      String payload,
      Map<String, int> vectorClock,
      int operationCount,
      DateTime createdAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
        return $default(
          _that.messageId,
          _that.fromDeviceId,
          _that.payload,
          _that.vectorClock,
          _that.operationCount,
          _that.createdAt,
        );
      case _:
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

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
      String messageId,
      String fromDeviceId,
      String payload,
      Map<String, int> vectorClock,
      int operationCount,
      DateTime createdAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage():
        return $default(
          _that.messageId,
          _that.fromDeviceId,
          _that.payload,
          _that.vectorClock,
          _that.operationCount,
          _that.createdAt,
        );
      case _:
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

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
      String messageId,
      String fromDeviceId,
      String payload,
      Map<String, int> vectorClock,
      int operationCount,
      DateTime createdAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _SyncMessage() when $default != null:
        return $default(
          _that.messageId,
          _that.fromDeviceId,
          _that.payload,
          _that.vectorClock,
          _that.operationCount,
          _that.createdAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _SyncMessage implements SyncMessage {
  const _SyncMessage({
    required this.messageId,
    required this.fromDeviceId,
    required this.payload,
    required final Map<String, int> vectorClock,
    required this.operationCount,
    required this.createdAt,
  }) : _vectorClock = vectorClock;
  factory _SyncMessage.fromJson(Map<String, dynamic> json) =>
      _$SyncMessageFromJson(json);

  @override
  final String messageId;
  @override
  final String fromDeviceId;
  @override
  final String payload;
  // encrypted base64
  final Map<String, int> _vectorClock;
  // encrypted base64
  @override
  Map<String, int> get vectorClock {
    if (_vectorClock is EqualUnmodifiableMapView) return _vectorClock;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_vectorClock);
  }

  @override
  final int operationCount;
  @override
  final DateTime createdAt;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SyncMessageCopyWith<_SyncMessage> get copyWith =>
      __$SyncMessageCopyWithImpl<_SyncMessage>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$SyncMessageToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SyncMessage &&
            (identical(other.messageId, messageId) ||
                other.messageId == messageId) &&
            (identical(other.fromDeviceId, fromDeviceId) ||
                other.fromDeviceId == fromDeviceId) &&
            (identical(other.payload, payload) || other.payload == payload) &&
            const DeepCollectionEquality().equals(
              other._vectorClock,
              _vectorClock,
            ) &&
            (identical(other.operationCount, operationCount) ||
                other.operationCount == operationCount) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    messageId,
    fromDeviceId,
    payload,
    const DeepCollectionEquality().hash(_vectorClock),
    operationCount,
    createdAt,
  );

  @override
  String toString() {
    return 'SyncMessage(messageId: $messageId, fromDeviceId: $fromDeviceId, payload: $payload, vectorClock: $vectorClock, operationCount: $operationCount, createdAt: $createdAt)';
  }
}

/// @nodoc
abstract mixin class _$SyncMessageCopyWith<$Res>
    implements $SyncMessageCopyWith<$Res> {
  factory _$SyncMessageCopyWith(
    _SyncMessage value,
    $Res Function(_SyncMessage) _then,
  ) = __$SyncMessageCopyWithImpl;
  @override
  @useResult
  $Res call({
    String messageId,
    String fromDeviceId,
    String payload,
    Map<String, int> vectorClock,
    int operationCount,
    DateTime createdAt,
  });
}

/// @nodoc
class __$SyncMessageCopyWithImpl<$Res> implements _$SyncMessageCopyWith<$Res> {
  __$SyncMessageCopyWithImpl(this._self, this._then);

  final _SyncMessage _self;
  final $Res Function(_SyncMessage) _then;

  /// Create a copy of SyncMessage
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? messageId = null,
    Object? fromDeviceId = null,
    Object? payload = null,
    Object? vectorClock = null,
    Object? operationCount = null,
    Object? createdAt = null,
  }) {
    return _then(
      _SyncMessage(
        messageId: null == messageId
            ? _self.messageId
            : messageId // ignore: cast_nullable_to_non_nullable
                  as String,
        fromDeviceId: null == fromDeviceId
            ? _self.fromDeviceId
            : fromDeviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        payload: null == payload
            ? _self.payload
            : payload // ignore: cast_nullable_to_non_nullable
                  as String,
        vectorClock: null == vectorClock
            ? _self._vectorClock
            : vectorClock // ignore: cast_nullable_to_non_nullable
                  as Map<String, int>,
        operationCount: null == operationCount
            ? _self.operationCount
            : operationCount // ignore: cast_nullable_to_non_nullable
                  as int,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}
