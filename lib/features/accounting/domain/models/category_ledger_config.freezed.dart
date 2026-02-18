// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'category_ledger_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryLedgerConfig {
  String get categoryId;
  LedgerType get ledgerType;
  DateTime get updatedAt;

  /// Create a copy of CategoryLedgerConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CategoryLedgerConfigCopyWith<CategoryLedgerConfig> get copyWith =>
      _$CategoryLedgerConfigCopyWithImpl<CategoryLedgerConfig>(
        this as CategoryLedgerConfig,
        _$identity,
      );

  /// Serializes this CategoryLedgerConfig to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CategoryLedgerConfig &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, categoryId, ledgerType, updatedAt);

  @override
  String toString() {
    return 'CategoryLedgerConfig(categoryId: $categoryId, ledgerType: $ledgerType, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $CategoryLedgerConfigCopyWith<$Res> {
  factory $CategoryLedgerConfigCopyWith(
    CategoryLedgerConfig value,
    $Res Function(CategoryLedgerConfig) _then,
  ) = _$CategoryLedgerConfigCopyWithImpl;
  @useResult
  $Res call({String categoryId, LedgerType ledgerType, DateTime updatedAt});
}

/// @nodoc
class _$CategoryLedgerConfigCopyWithImpl<$Res>
    implements $CategoryLedgerConfigCopyWith<$Res> {
  _$CategoryLedgerConfigCopyWithImpl(this._self, this._then);

  final CategoryLedgerConfig _self;
  final $Res Function(CategoryLedgerConfig) _then;

  /// Create a copy of CategoryLedgerConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? ledgerType = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _self.copyWith(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: null == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType,
        updatedAt: null == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CategoryLedgerConfig].
extension CategoryLedgerConfigPatterns on CategoryLedgerConfig {
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
    TResult Function(_CategoryLedgerConfig value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryLedgerConfig() when $default != null:
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
    TResult Function(_CategoryLedgerConfig value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryLedgerConfig():
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
    TResult? Function(_CategoryLedgerConfig value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryLedgerConfig() when $default != null:
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
      String categoryId,
      LedgerType ledgerType,
      DateTime updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryLedgerConfig() when $default != null:
        return $default(_that.categoryId, _that.ledgerType, _that.updatedAt);
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
      String categoryId,
      LedgerType ledgerType,
      DateTime updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryLedgerConfig():
        return $default(_that.categoryId, _that.ledgerType, _that.updatedAt);
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
      String categoryId,
      LedgerType ledgerType,
      DateTime updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryLedgerConfig() when $default != null:
        return $default(_that.categoryId, _that.ledgerType, _that.updatedAt);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CategoryLedgerConfig implements CategoryLedgerConfig {
  const _CategoryLedgerConfig({
    required this.categoryId,
    required this.ledgerType,
    required this.updatedAt,
  });
  factory _CategoryLedgerConfig.fromJson(Map<String, dynamic> json) =>
      _$CategoryLedgerConfigFromJson(json);

  @override
  final String categoryId;
  @override
  final LedgerType ledgerType;
  @override
  final DateTime updatedAt;

  /// Create a copy of CategoryLedgerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CategoryLedgerConfigCopyWith<_CategoryLedgerConfig> get copyWith =>
      __$CategoryLedgerConfigCopyWithImpl<_CategoryLedgerConfig>(
        this,
        _$identity,
      );

  @override
  Map<String, dynamic> toJson() {
    return _$CategoryLedgerConfigToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CategoryLedgerConfig &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, categoryId, ledgerType, updatedAt);

  @override
  String toString() {
    return 'CategoryLedgerConfig(categoryId: $categoryId, ledgerType: $ledgerType, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$CategoryLedgerConfigCopyWith<$Res>
    implements $CategoryLedgerConfigCopyWith<$Res> {
  factory _$CategoryLedgerConfigCopyWith(
    _CategoryLedgerConfig value,
    $Res Function(_CategoryLedgerConfig) _then,
  ) = __$CategoryLedgerConfigCopyWithImpl;
  @override
  @useResult
  $Res call({String categoryId, LedgerType ledgerType, DateTime updatedAt});
}

/// @nodoc
class __$CategoryLedgerConfigCopyWithImpl<$Res>
    implements _$CategoryLedgerConfigCopyWith<$Res> {
  __$CategoryLedgerConfigCopyWithImpl(this._self, this._then);

  final _CategoryLedgerConfig _self;
  final $Res Function(_CategoryLedgerConfig) _then;

  /// Create a copy of CategoryLedgerConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? ledgerType = null,
    Object? updatedAt = null,
  }) {
    return _then(
      _CategoryLedgerConfig(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: null == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType,
        updatedAt: null == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
      ),
    );
  }
}
