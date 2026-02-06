// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Book {
  String get id;
  String get name;
  String get currency;
  String get deviceId;
  DateTime get createdAt;
  DateTime? get updatedAt;
  bool get isArchived; // Denormalized stats for performance
  int get transactionCount;
  int get survivalBalance;
  int get soulBalance;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookCopyWith<Book> get copyWith =>
      _$BookCopyWithImpl<Book>(this as Book, _$identity);

  /// Serializes this Book to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Book &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.survivalBalance, survivalBalance) ||
                other.survivalBalance == survivalBalance) &&
            (identical(other.soulBalance, soulBalance) ||
                other.soulBalance == soulBalance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    currency,
    deviceId,
    createdAt,
    updatedAt,
    isArchived,
    transactionCount,
    survivalBalance,
    soulBalance,
  );

  @override
  String toString() {
    return 'Book(id: $id, name: $name, currency: $currency, deviceId: $deviceId, createdAt: $createdAt, updatedAt: $updatedAt, isArchived: $isArchived, transactionCount: $transactionCount, survivalBalance: $survivalBalance, soulBalance: $soulBalance)';
  }
}

/// @nodoc
abstract mixin class $BookCopyWith<$Res> {
  factory $BookCopyWith(Book value, $Res Function(Book) _then) =
      _$BookCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String name,
    String currency,
    String deviceId,
    DateTime createdAt,
    DateTime? updatedAt,
    bool isArchived,
    int transactionCount,
    int survivalBalance,
    int soulBalance,
  });
}

/// @nodoc
class _$BookCopyWithImpl<$Res> implements $BookCopyWith<$Res> {
  _$BookCopyWithImpl(this._self, this._then);

  final Book _self;
  final $Res Function(Book) _then;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? currency = null,
    Object? deviceId = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? isArchived = null,
    Object? transactionCount = null,
    Object? survivalBalance = null,
    Object? soulBalance = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: null == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isArchived: null == isArchived
            ? _self.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
        transactionCount: null == transactionCount
            ? _self.transactionCount
            : transactionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        survivalBalance: null == survivalBalance
            ? _self.survivalBalance
            : survivalBalance // ignore: cast_nullable_to_non_nullable
                  as int,
        soulBalance: null == soulBalance
            ? _self.soulBalance
            : soulBalance // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Book].
extension BookPatterns on Book {
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
    TResult Function(_Book value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Book() when $default != null:
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
  TResult map<TResult extends Object?>(TResult Function(_Book value) $default) {
    final _that = this;
    switch (_that) {
      case _Book():
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
    TResult? Function(_Book value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Book() when $default != null:
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
      String name,
      String currency,
      String deviceId,
      DateTime createdAt,
      DateTime? updatedAt,
      bool isArchived,
      int transactionCount,
      int survivalBalance,
      int soulBalance,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Book() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.currency,
          _that.deviceId,
          _that.createdAt,
          _that.updatedAt,
          _that.isArchived,
          _that.transactionCount,
          _that.survivalBalance,
          _that.soulBalance,
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
      String name,
      String currency,
      String deviceId,
      DateTime createdAt,
      DateTime? updatedAt,
      bool isArchived,
      int transactionCount,
      int survivalBalance,
      int soulBalance,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Book():
        return $default(
          _that.id,
          _that.name,
          _that.currency,
          _that.deviceId,
          _that.createdAt,
          _that.updatedAt,
          _that.isArchived,
          _that.transactionCount,
          _that.survivalBalance,
          _that.soulBalance,
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
      String id,
      String name,
      String currency,
      String deviceId,
      DateTime createdAt,
      DateTime? updatedAt,
      bool isArchived,
      int transactionCount,
      int survivalBalance,
      int soulBalance,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Book() when $default != null:
        return $default(
          _that.id,
          _that.name,
          _that.currency,
          _that.deviceId,
          _that.createdAt,
          _that.updatedAt,
          _that.isArchived,
          _that.transactionCount,
          _that.survivalBalance,
          _that.soulBalance,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Book implements Book {
  const _Book({
    required this.id,
    required this.name,
    required this.currency,
    required this.deviceId,
    required this.createdAt,
    this.updatedAt,
    this.isArchived = false,
    this.transactionCount = 0,
    this.survivalBalance = 0,
    this.soulBalance = 0,
  });
  factory _Book.fromJson(Map<String, dynamic> json) => _$BookFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String currency;
  @override
  final String deviceId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  @override
  @JsonKey()
  final bool isArchived;
  // Denormalized stats for performance
  @override
  @JsonKey()
  final int transactionCount;
  @override
  @JsonKey()
  final int survivalBalance;
  @override
  @JsonKey()
  final int soulBalance;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookCopyWith<_Book> get copyWith =>
      __$BookCopyWithImpl<_Book>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Book &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isArchived, isArchived) ||
                other.isArchived == isArchived) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.survivalBalance, survivalBalance) ||
                other.survivalBalance == survivalBalance) &&
            (identical(other.soulBalance, soulBalance) ||
                other.soulBalance == soulBalance));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    name,
    currency,
    deviceId,
    createdAt,
    updatedAt,
    isArchived,
    transactionCount,
    survivalBalance,
    soulBalance,
  );

  @override
  String toString() {
    return 'Book(id: $id, name: $name, currency: $currency, deviceId: $deviceId, createdAt: $createdAt, updatedAt: $updatedAt, isArchived: $isArchived, transactionCount: $transactionCount, survivalBalance: $survivalBalance, soulBalance: $soulBalance)';
  }
}

/// @nodoc
abstract mixin class _$BookCopyWith<$Res> implements $BookCopyWith<$Res> {
  factory _$BookCopyWith(_Book value, $Res Function(_Book) _then) =
      __$BookCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String name,
    String currency,
    String deviceId,
    DateTime createdAt,
    DateTime? updatedAt,
    bool isArchived,
    int transactionCount,
    int survivalBalance,
    int soulBalance,
  });
}

/// @nodoc
class __$BookCopyWithImpl<$Res> implements _$BookCopyWith<$Res> {
  __$BookCopyWithImpl(this._self, this._then);

  final _Book _self;
  final $Res Function(_Book) _then;

  /// Create a copy of Book
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? currency = null,
    Object? deviceId = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? isArchived = null,
    Object? transactionCount = null,
    Object? survivalBalance = null,
    Object? soulBalance = null,
  }) {
    return _then(
      _Book(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        currency: null == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isArchived: null == isArchived
            ? _self.isArchived
            : isArchived // ignore: cast_nullable_to_non_nullable
                  as bool,
        transactionCount: null == transactionCount
            ? _self.transactionCount
            : transactionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        survivalBalance: null == survivalBalance
            ? _self.survivalBalance
            : survivalBalance // ignore: cast_nullable_to_non_nullable
                  as int,
        soulBalance: null == soulBalance
            ? _self.soulBalance
            : soulBalance // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
