// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'audit_log_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuditLogEntry {
  /// ULID — time-sortable unique identifier.
  String get id;

  /// The type of security event.
  AuditEvent get event;

  /// Device that produced this event.
  String get deviceId;

  /// Associated book ID (optional).
  String? get bookId;

  /// Associated transaction ID (optional).
  String? get transactionId;

  /// Extra JSON details. MUST NOT contain keys, PINs, or amounts.
  String? get details;

  /// When the event occurred.
  DateTime get timestamp;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuditLogEntryCopyWith<AuditLogEntry> get copyWith =>
      _$AuditLogEntryCopyWithImpl<AuditLogEntry>(
        this as AuditLogEntry,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuditLogEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    event,
    deviceId,
    bookId,
    transactionId,
    details,
    timestamp,
  );

  @override
  String toString() {
    return 'AuditLogEntry(id: $id, event: $event, deviceId: $deviceId, bookId: $bookId, transactionId: $transactionId, details: $details, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class $AuditLogEntryCopyWith<$Res> {
  factory $AuditLogEntryCopyWith(
    AuditLogEntry value,
    $Res Function(AuditLogEntry) _then,
  ) = _$AuditLogEntryCopyWithImpl;
  @useResult
  $Res call({
    String id,
    AuditEvent event,
    String deviceId,
    String? bookId,
    String? transactionId,
    String? details,
    DateTime timestamp,
  });
}

/// @nodoc
class _$AuditLogEntryCopyWithImpl<$Res>
    implements $AuditLogEntryCopyWith<$Res> {
  _$AuditLogEntryCopyWithImpl(this._self, this._then);

  final AuditLogEntry _self;
  final $Res Function(AuditLogEntry) _then;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? event = null,
    Object? deviceId = null,
    Object? bookId = freezed,
    Object? transactionId = freezed,
    Object? details = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        event: null == event
            ? _self.event
            : event // ignore: cast_nullable_to_non_nullable
                  as AuditEvent,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: freezed == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String?,
        transactionId: freezed == transactionId
            ? _self.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        details: freezed == details
            ? _self.details
            : details // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [AuditLogEntry].
extension AuditLogEntryPatterns on AuditLogEntry {
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
    TResult Function(_AuditLogEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
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
    TResult Function(_AuditLogEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry():
        return $default(_that);
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
    TResult? Function(_AuditLogEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
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
      String id,
      AuditEvent event,
      String deviceId,
      String? bookId,
      String? transactionId,
      String? details,
      DateTime timestamp,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
        return $default(
          _that.id,
          _that.event,
          _that.deviceId,
          _that.bookId,
          _that.transactionId,
          _that.details,
          _that.timestamp,
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
      String id,
      AuditEvent event,
      String deviceId,
      String? bookId,
      String? transactionId,
      String? details,
      DateTime timestamp,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry():
        return $default(
          _that.id,
          _that.event,
          _that.deviceId,
          _that.bookId,
          _that.transactionId,
          _that.details,
          _that.timestamp,
        );
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
      String id,
      AuditEvent event,
      String deviceId,
      String? bookId,
      String? transactionId,
      String? details,
      DateTime timestamp,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _AuditLogEntry() when $default != null:
        return $default(
          _that.id,
          _that.event,
          _that.deviceId,
          _that.bookId,
          _that.transactionId,
          _that.details,
          _that.timestamp,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _AuditLogEntry implements AuditLogEntry {
  const _AuditLogEntry({
    required this.id,
    required this.event,
    required this.deviceId,
    this.bookId,
    this.transactionId,
    this.details,
    required this.timestamp,
  });

  /// ULID — time-sortable unique identifier.
  @override
  final String id;

  /// The type of security event.
  @override
  final AuditEvent event;

  /// Device that produced this event.
  @override
  final String deviceId;

  /// Associated book ID (optional).
  @override
  final String? bookId;

  /// Associated transaction ID (optional).
  @override
  final String? transactionId;

  /// Extra JSON details. MUST NOT contain keys, PINs, or amounts.
  @override
  final String? details;

  /// When the event occurred.
  @override
  final DateTime timestamp;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$AuditLogEntryCopyWith<_AuditLogEntry> get copyWith =>
      __$AuditLogEntryCopyWithImpl<_AuditLogEntry>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _AuditLogEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.event, event) || other.event == event) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.transactionId, transactionId) ||
                other.transactionId == transactionId) &&
            (identical(other.details, details) || other.details == details) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    event,
    deviceId,
    bookId,
    transactionId,
    details,
    timestamp,
  );

  @override
  String toString() {
    return 'AuditLogEntry(id: $id, event: $event, deviceId: $deviceId, bookId: $bookId, transactionId: $transactionId, details: $details, timestamp: $timestamp)';
  }
}

/// @nodoc
abstract mixin class _$AuditLogEntryCopyWith<$Res>
    implements $AuditLogEntryCopyWith<$Res> {
  factory _$AuditLogEntryCopyWith(
    _AuditLogEntry value,
    $Res Function(_AuditLogEntry) _then,
  ) = __$AuditLogEntryCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    AuditEvent event,
    String deviceId,
    String? bookId,
    String? transactionId,
    String? details,
    DateTime timestamp,
  });
}

/// @nodoc
class __$AuditLogEntryCopyWithImpl<$Res>
    implements _$AuditLogEntryCopyWith<$Res> {
  __$AuditLogEntryCopyWithImpl(this._self, this._then);

  final _AuditLogEntry _self;
  final $Res Function(_AuditLogEntry) _then;

  /// Create a copy of AuditLogEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? event = null,
    Object? deviceId = null,
    Object? bookId = freezed,
    Object? transactionId = freezed,
    Object? details = freezed,
    Object? timestamp = null,
  }) {
    return _then(
      _AuditLogEntry(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        event: null == event
            ? _self.event
            : event // ignore: cast_nullable_to_non_nullable
                  as AuditEvent,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: freezed == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String?,
        transactionId: freezed == transactionId
            ? _self.transactionId
            : transactionId // ignore: cast_nullable_to_non_nullable
                  as String?,
        details: freezed == details
            ? _self.details
            : details // ignore: cast_nullable_to_non_nullable
                  as String?,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}
