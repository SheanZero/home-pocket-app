// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant_match_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MerchantMatchEntry {
  String get matchKey;
  String get surface;
  String get merchantId;
  String get displayName;
  String get categoryId;
  String get ledgerHint;

  /// Create a copy of MerchantMatchEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MerchantMatchEntryCopyWith<MerchantMatchEntry> get copyWith =>
      _$MerchantMatchEntryCopyWithImpl<MerchantMatchEntry>(
        this as MerchantMatchEntry,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MerchantMatchEntry &&
            (identical(other.matchKey, matchKey) ||
                other.matchKey == matchKey) &&
            (identical(other.surface, surface) || other.surface == surface) &&
            (identical(other.merchantId, merchantId) ||
                other.merchantId == merchantId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerHint, ledgerHint) ||
                other.ledgerHint == ledgerHint));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    matchKey,
    surface,
    merchantId,
    displayName,
    categoryId,
    ledgerHint,
  );

  @override
  String toString() {
    return 'MerchantMatchEntry(matchKey: $matchKey, surface: $surface, merchantId: $merchantId, displayName: $displayName, categoryId: $categoryId, ledgerHint: $ledgerHint)';
  }
}

/// @nodoc
abstract mixin class $MerchantMatchEntryCopyWith<$Res> {
  factory $MerchantMatchEntryCopyWith(
    MerchantMatchEntry value,
    $Res Function(MerchantMatchEntry) _then,
  ) = _$MerchantMatchEntryCopyWithImpl;
  @useResult
  $Res call({
    String matchKey,
    String surface,
    String merchantId,
    String displayName,
    String categoryId,
    String ledgerHint,
  });
}

/// @nodoc
class _$MerchantMatchEntryCopyWithImpl<$Res>
    implements $MerchantMatchEntryCopyWith<$Res> {
  _$MerchantMatchEntryCopyWithImpl(this._self, this._then);

  final MerchantMatchEntry _self;
  final $Res Function(MerchantMatchEntry) _then;

  /// Create a copy of MerchantMatchEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? matchKey = null,
    Object? surface = null,
    Object? merchantId = null,
    Object? displayName = null,
    Object? categoryId = null,
    Object? ledgerHint = null,
  }) {
    return _then(
      _self.copyWith(
        matchKey: null == matchKey
            ? _self.matchKey
            : matchKey // ignore: cast_nullable_to_non_nullable
                  as String,
        surface: null == surface
            ? _self.surface
            : surface // ignore: cast_nullable_to_non_nullable
                  as String,
        merchantId: null == merchantId
            ? _self.merchantId
            : merchantId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _self.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerHint: null == ledgerHint
            ? _self.ledgerHint
            : ledgerHint // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MerchantMatchEntry].
extension MerchantMatchEntryPatterns on MerchantMatchEntry {
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
    TResult Function(_MerchantMatchEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchEntry() when $default != null:
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
    TResult Function(_MerchantMatchEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchEntry():
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
    TResult? Function(_MerchantMatchEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchEntry() when $default != null:
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
      String matchKey,
      String surface,
      String merchantId,
      String displayName,
      String categoryId,
      String ledgerHint,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchEntry() when $default != null:
        return $default(
          _that.matchKey,
          _that.surface,
          _that.merchantId,
          _that.displayName,
          _that.categoryId,
          _that.ledgerHint,
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
      String matchKey,
      String surface,
      String merchantId,
      String displayName,
      String categoryId,
      String ledgerHint,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchEntry():
        return $default(
          _that.matchKey,
          _that.surface,
          _that.merchantId,
          _that.displayName,
          _that.categoryId,
          _that.ledgerHint,
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
      String matchKey,
      String surface,
      String merchantId,
      String displayName,
      String categoryId,
      String ledgerHint,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchEntry() when $default != null:
        return $default(
          _that.matchKey,
          _that.surface,
          _that.merchantId,
          _that.displayName,
          _that.categoryId,
          _that.ledgerHint,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MerchantMatchEntry implements MerchantMatchEntry {
  const _MerchantMatchEntry({
    required this.matchKey,
    required this.surface,
    required this.merchantId,
    required this.displayName,
    required this.categoryId,
    required this.ledgerHint,
  });

  @override
  final String matchKey;
  @override
  final String surface;
  @override
  final String merchantId;
  @override
  final String displayName;
  @override
  final String categoryId;
  @override
  final String ledgerHint;

  /// Create a copy of MerchantMatchEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MerchantMatchEntryCopyWith<_MerchantMatchEntry> get copyWith =>
      __$MerchantMatchEntryCopyWithImpl<_MerchantMatchEntry>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MerchantMatchEntry &&
            (identical(other.matchKey, matchKey) ||
                other.matchKey == matchKey) &&
            (identical(other.surface, surface) || other.surface == surface) &&
            (identical(other.merchantId, merchantId) ||
                other.merchantId == merchantId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerHint, ledgerHint) ||
                other.ledgerHint == ledgerHint));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    matchKey,
    surface,
    merchantId,
    displayName,
    categoryId,
    ledgerHint,
  );

  @override
  String toString() {
    return 'MerchantMatchEntry(matchKey: $matchKey, surface: $surface, merchantId: $merchantId, displayName: $displayName, categoryId: $categoryId, ledgerHint: $ledgerHint)';
  }
}

/// @nodoc
abstract mixin class _$MerchantMatchEntryCopyWith<$Res>
    implements $MerchantMatchEntryCopyWith<$Res> {
  factory _$MerchantMatchEntryCopyWith(
    _MerchantMatchEntry value,
    $Res Function(_MerchantMatchEntry) _then,
  ) = __$MerchantMatchEntryCopyWithImpl;
  @override
  @useResult
  $Res call({
    String matchKey,
    String surface,
    String merchantId,
    String displayName,
    String categoryId,
    String ledgerHint,
  });
}

/// @nodoc
class __$MerchantMatchEntryCopyWithImpl<$Res>
    implements _$MerchantMatchEntryCopyWith<$Res> {
  __$MerchantMatchEntryCopyWithImpl(this._self, this._then);

  final _MerchantMatchEntry _self;
  final $Res Function(_MerchantMatchEntry) _then;

  /// Create a copy of MerchantMatchEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? matchKey = null,
    Object? surface = null,
    Object? merchantId = null,
    Object? displayName = null,
    Object? categoryId = null,
    Object? ledgerHint = null,
  }) {
    return _then(
      _MerchantMatchEntry(
        matchKey: null == matchKey
            ? _self.matchKey
            : matchKey // ignore: cast_nullable_to_non_nullable
                  as String,
        surface: null == surface
            ? _self.surface
            : surface // ignore: cast_nullable_to_non_nullable
                  as String,
        merchantId: null == merchantId
            ? _self.merchantId
            : merchantId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _self.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerHint: null == ledgerHint
            ? _self.ledgerHint
            : ledgerHint // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
