// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'paired_device.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$PairedDevice {
  String get pairId;
  String get bookId;
  String? get partnerDeviceId; // null during 'pending' state
  String? get partnerPublicKey; // null during 'pending' state
  String? get partnerDeviceName; // null during 'pending' state
  PairStatus get status;
  String? get pairCode;
  DateTime? get expiresAt; // pair code expiry
  DateTime get createdAt;
  DateTime? get confirmedAt;
  DateTime? get lastSyncAt;

  /// Create a copy of PairedDevice
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $PairedDeviceCopyWith<PairedDevice> get copyWith =>
      _$PairedDeviceCopyWithImpl<PairedDevice>(
        this as PairedDevice,
        _$identity,
      );

  /// Serializes this PairedDevice to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is PairedDevice &&
            (identical(other.pairId, pairId) || other.pairId == pairId) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.partnerDeviceId, partnerDeviceId) ||
                other.partnerDeviceId == partnerDeviceId) &&
            (identical(other.partnerPublicKey, partnerPublicKey) ||
                other.partnerPublicKey == partnerPublicKey) &&
            (identical(other.partnerDeviceName, partnerDeviceName) ||
                other.partnerDeviceName == partnerDeviceName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pairCode, pairCode) ||
                other.pairCode == pairCode) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pairId,
    bookId,
    partnerDeviceId,
    partnerPublicKey,
    partnerDeviceName,
    status,
    pairCode,
    expiresAt,
    createdAt,
    confirmedAt,
    lastSyncAt,
  );

  @override
  String toString() {
    return 'PairedDevice(pairId: $pairId, bookId: $bookId, partnerDeviceId: $partnerDeviceId, partnerPublicKey: $partnerPublicKey, partnerDeviceName: $partnerDeviceName, status: $status, pairCode: $pairCode, expiresAt: $expiresAt, createdAt: $createdAt, confirmedAt: $confirmedAt, lastSyncAt: $lastSyncAt)';
  }
}

/// @nodoc
abstract mixin class $PairedDeviceCopyWith<$Res> {
  factory $PairedDeviceCopyWith(
    PairedDevice value,
    $Res Function(PairedDevice) _then,
  ) = _$PairedDeviceCopyWithImpl;
  @useResult
  $Res call({
    String pairId,
    String bookId,
    String? partnerDeviceId,
    String? partnerPublicKey,
    String? partnerDeviceName,
    PairStatus status,
    String? pairCode,
    DateTime? expiresAt,
    DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  });
}

/// @nodoc
class _$PairedDeviceCopyWithImpl<$Res> implements $PairedDeviceCopyWith<$Res> {
  _$PairedDeviceCopyWithImpl(this._self, this._then);

  final PairedDevice _self;
  final $Res Function(PairedDevice) _then;

  /// Create a copy of PairedDevice
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? pairId = null,
    Object? bookId = null,
    Object? partnerDeviceId = freezed,
    Object? partnerPublicKey = freezed,
    Object? partnerDeviceName = freezed,
    Object? status = null,
    Object? pairCode = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
    Object? lastSyncAt = freezed,
  }) {
    return _then(
      _self.copyWith(
        pairId: null == pairId
            ? _self.pairId
            : pairId // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        partnerDeviceId: freezed == partnerDeviceId
            ? _self.partnerDeviceId
            : partnerDeviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        partnerPublicKey: freezed == partnerPublicKey
            ? _self.partnerPublicKey
            : partnerPublicKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        partnerDeviceName: freezed == partnerDeviceName
            ? _self.partnerDeviceName
            : partnerDeviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PairStatus,
        pairCode: freezed == pairCode
            ? _self.pairCode
            : pairCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: freezed == expiresAt
            ? _self.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confirmedAt: freezed == confirmedAt
            ? _self.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncAt: freezed == lastSyncAt
            ? _self.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [PairedDevice].
extension PairedDevicePatterns on PairedDevice {
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
    TResult Function(_PairedDevice value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PairedDevice() when $default != null:
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
    TResult Function(_PairedDevice value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PairedDevice():
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
    TResult? Function(_PairedDevice value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PairedDevice() when $default != null:
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
      String pairId,
      String bookId,
      String? partnerDeviceId,
      String? partnerPublicKey,
      String? partnerDeviceName,
      PairStatus status,
      String? pairCode,
      DateTime? expiresAt,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _PairedDevice() when $default != null:
        return $default(
          _that.pairId,
          _that.bookId,
          _that.partnerDeviceId,
          _that.partnerPublicKey,
          _that.partnerDeviceName,
          _that.status,
          _that.pairCode,
          _that.expiresAt,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
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
      String pairId,
      String bookId,
      String? partnerDeviceId,
      String? partnerPublicKey,
      String? partnerDeviceName,
      PairStatus status,
      String? pairCode,
      DateTime? expiresAt,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PairedDevice():
        return $default(
          _that.pairId,
          _that.bookId,
          _that.partnerDeviceId,
          _that.partnerPublicKey,
          _that.partnerDeviceName,
          _that.status,
          _that.pairCode,
          _that.expiresAt,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
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
      String pairId,
      String bookId,
      String? partnerDeviceId,
      String? partnerPublicKey,
      String? partnerDeviceName,
      PairStatus status,
      String? pairCode,
      DateTime? expiresAt,
      DateTime createdAt,
      DateTime? confirmedAt,
      DateTime? lastSyncAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _PairedDevice() when $default != null:
        return $default(
          _that.pairId,
          _that.bookId,
          _that.partnerDeviceId,
          _that.partnerPublicKey,
          _that.partnerDeviceName,
          _that.status,
          _that.pairCode,
          _that.expiresAt,
          _that.createdAt,
          _that.confirmedAt,
          _that.lastSyncAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _PairedDevice implements PairedDevice {
  const _PairedDevice({
    required this.pairId,
    required this.bookId,
    this.partnerDeviceId,
    this.partnerPublicKey,
    this.partnerDeviceName,
    required this.status,
    this.pairCode,
    this.expiresAt,
    required this.createdAt,
    this.confirmedAt,
    this.lastSyncAt,
  });
  factory _PairedDevice.fromJson(Map<String, dynamic> json) =>
      _$PairedDeviceFromJson(json);

  @override
  final String pairId;
  @override
  final String bookId;
  @override
  final String? partnerDeviceId;
  // null during 'pending' state
  @override
  final String? partnerPublicKey;
  // null during 'pending' state
  @override
  final String? partnerDeviceName;
  // null during 'pending' state
  @override
  final PairStatus status;
  @override
  final String? pairCode;
  @override
  final DateTime? expiresAt;
  // pair code expiry
  @override
  final DateTime createdAt;
  @override
  final DateTime? confirmedAt;
  @override
  final DateTime? lastSyncAt;

  /// Create a copy of PairedDevice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PairedDeviceCopyWith<_PairedDevice> get copyWith =>
      __$PairedDeviceCopyWithImpl<_PairedDevice>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$PairedDeviceToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PairedDevice &&
            (identical(other.pairId, pairId) || other.pairId == pairId) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.partnerDeviceId, partnerDeviceId) ||
                other.partnerDeviceId == partnerDeviceId) &&
            (identical(other.partnerPublicKey, partnerPublicKey) ||
                other.partnerPublicKey == partnerPublicKey) &&
            (identical(other.partnerDeviceName, partnerDeviceName) ||
                other.partnerDeviceName == partnerDeviceName) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.pairCode, pairCode) ||
                other.pairCode == pairCode) &&
            (identical(other.expiresAt, expiresAt) ||
                other.expiresAt == expiresAt) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.confirmedAt, confirmedAt) ||
                other.confirmedAt == confirmedAt) &&
            (identical(other.lastSyncAt, lastSyncAt) ||
                other.lastSyncAt == lastSyncAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    pairId,
    bookId,
    partnerDeviceId,
    partnerPublicKey,
    partnerDeviceName,
    status,
    pairCode,
    expiresAt,
    createdAt,
    confirmedAt,
    lastSyncAt,
  );

  @override
  String toString() {
    return 'PairedDevice(pairId: $pairId, bookId: $bookId, partnerDeviceId: $partnerDeviceId, partnerPublicKey: $partnerPublicKey, partnerDeviceName: $partnerDeviceName, status: $status, pairCode: $pairCode, expiresAt: $expiresAt, createdAt: $createdAt, confirmedAt: $confirmedAt, lastSyncAt: $lastSyncAt)';
  }
}

/// @nodoc
abstract mixin class _$PairedDeviceCopyWith<$Res>
    implements $PairedDeviceCopyWith<$Res> {
  factory _$PairedDeviceCopyWith(
    _PairedDevice value,
    $Res Function(_PairedDevice) _then,
  ) = __$PairedDeviceCopyWithImpl;
  @override
  @useResult
  $Res call({
    String pairId,
    String bookId,
    String? partnerDeviceId,
    String? partnerPublicKey,
    String? partnerDeviceName,
    PairStatus status,
    String? pairCode,
    DateTime? expiresAt,
    DateTime createdAt,
    DateTime? confirmedAt,
    DateTime? lastSyncAt,
  });
}

/// @nodoc
class __$PairedDeviceCopyWithImpl<$Res>
    implements _$PairedDeviceCopyWith<$Res> {
  __$PairedDeviceCopyWithImpl(this._self, this._then);

  final _PairedDevice _self;
  final $Res Function(_PairedDevice) _then;

  /// Create a copy of PairedDevice
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? pairId = null,
    Object? bookId = null,
    Object? partnerDeviceId = freezed,
    Object? partnerPublicKey = freezed,
    Object? partnerDeviceName = freezed,
    Object? status = null,
    Object? pairCode = freezed,
    Object? expiresAt = freezed,
    Object? createdAt = null,
    Object? confirmedAt = freezed,
    Object? lastSyncAt = freezed,
  }) {
    return _then(
      _PairedDevice(
        pairId: null == pairId
            ? _self.pairId
            : pairId // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        partnerDeviceId: freezed == partnerDeviceId
            ? _self.partnerDeviceId
            : partnerDeviceId // ignore: cast_nullable_to_non_nullable
                  as String?,
        partnerPublicKey: freezed == partnerPublicKey
            ? _self.partnerPublicKey
            : partnerPublicKey // ignore: cast_nullable_to_non_nullable
                  as String?,
        partnerDeviceName: freezed == partnerDeviceName
            ? _self.partnerDeviceName
            : partnerDeviceName // ignore: cast_nullable_to_non_nullable
                  as String?,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as PairStatus,
        pairCode: freezed == pairCode
            ? _self.pairCode
            : pairCode // ignore: cast_nullable_to_non_nullable
                  as String?,
        expiresAt: freezed == expiresAt
            ? _self.expiresAt
            : expiresAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        confirmedAt: freezed == confirmedAt
            ? _self.confirmedAt
            : confirmedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        lastSyncAt: freezed == lastSyncAt
            ? _self.lastSyncAt
            : lastSyncAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}
