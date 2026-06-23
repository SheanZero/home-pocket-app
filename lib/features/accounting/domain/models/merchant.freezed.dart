// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MerchantMatchKey {
  String get surface;
  String get matchKey;
  String get kind;

  /// Create a copy of MerchantMatchKey
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MerchantMatchKeyCopyWith<MerchantMatchKey> get copyWith =>
      _$MerchantMatchKeyCopyWithImpl<MerchantMatchKey>(
        this as MerchantMatchKey,
        _$identity,
      );

  /// Serializes this MerchantMatchKey to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MerchantMatchKey &&
            (identical(other.surface, surface) || other.surface == surface) &&
            (identical(other.matchKey, matchKey) ||
                other.matchKey == matchKey) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, surface, matchKey, kind);

  @override
  String toString() {
    return 'MerchantMatchKey(surface: $surface, matchKey: $matchKey, kind: $kind)';
  }
}

/// @nodoc
abstract mixin class $MerchantMatchKeyCopyWith<$Res> {
  factory $MerchantMatchKeyCopyWith(
    MerchantMatchKey value,
    $Res Function(MerchantMatchKey) _then,
  ) = _$MerchantMatchKeyCopyWithImpl;
  @useResult
  $Res call({String surface, String matchKey, String kind});
}

/// @nodoc
class _$MerchantMatchKeyCopyWithImpl<$Res>
    implements $MerchantMatchKeyCopyWith<$Res> {
  _$MerchantMatchKeyCopyWithImpl(this._self, this._then);

  final MerchantMatchKey _self;
  final $Res Function(MerchantMatchKey) _then;

  /// Create a copy of MerchantMatchKey
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? surface = null,
    Object? matchKey = null,
    Object? kind = null,
  }) {
    return _then(
      _self.copyWith(
        surface: null == surface
            ? _self.surface
            : surface // ignore: cast_nullable_to_non_nullable
                  as String,
        matchKey: null == matchKey
            ? _self.matchKey
            : matchKey // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _self.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MerchantMatchKey].
extension MerchantMatchKeyPatterns on MerchantMatchKey {
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
    TResult Function(_MerchantMatchKey value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchKey() when $default != null:
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
    TResult Function(_MerchantMatchKey value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchKey():
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
    TResult? Function(_MerchantMatchKey value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchKey() when $default != null:
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
    TResult Function(String surface, String matchKey, String kind)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchKey() when $default != null:
        return $default(_that.surface, _that.matchKey, _that.kind);
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
    TResult Function(String surface, String matchKey, String kind) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchKey():
        return $default(_that.surface, _that.matchKey, _that.kind);
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
    TResult? Function(String surface, String matchKey, String kind)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantMatchKey() when $default != null:
        return $default(_that.surface, _that.matchKey, _that.kind);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MerchantMatchKey implements MerchantMatchKey {
  const _MerchantMatchKey({
    required this.surface,
    required this.matchKey,
    required this.kind,
  });
  factory _MerchantMatchKey.fromJson(Map<String, dynamic> json) =>
      _$MerchantMatchKeyFromJson(json);

  @override
  final String surface;
  @override
  final String matchKey;
  @override
  final String kind;

  /// Create a copy of MerchantMatchKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MerchantMatchKeyCopyWith<_MerchantMatchKey> get copyWith =>
      __$MerchantMatchKeyCopyWithImpl<_MerchantMatchKey>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MerchantMatchKeyToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MerchantMatchKey &&
            (identical(other.surface, surface) || other.surface == surface) &&
            (identical(other.matchKey, matchKey) ||
                other.matchKey == matchKey) &&
            (identical(other.kind, kind) || other.kind == kind));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, surface, matchKey, kind);

  @override
  String toString() {
    return 'MerchantMatchKey(surface: $surface, matchKey: $matchKey, kind: $kind)';
  }
}

/// @nodoc
abstract mixin class _$MerchantMatchKeyCopyWith<$Res>
    implements $MerchantMatchKeyCopyWith<$Res> {
  factory _$MerchantMatchKeyCopyWith(
    _MerchantMatchKey value,
    $Res Function(_MerchantMatchKey) _then,
  ) = __$MerchantMatchKeyCopyWithImpl;
  @override
  @useResult
  $Res call({String surface, String matchKey, String kind});
}

/// @nodoc
class __$MerchantMatchKeyCopyWithImpl<$Res>
    implements _$MerchantMatchKeyCopyWith<$Res> {
  __$MerchantMatchKeyCopyWithImpl(this._self, this._then);

  final _MerchantMatchKey _self;
  final $Res Function(_MerchantMatchKey) _then;

  /// Create a copy of MerchantMatchKey
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? surface = null,
    Object? matchKey = null,
    Object? kind = null,
  }) {
    return _then(
      _MerchantMatchKey(
        surface: null == surface
            ? _self.surface
            : surface // ignore: cast_nullable_to_non_nullable
                  as String,
        matchKey: null == matchKey
            ? _self.matchKey
            : matchKey // ignore: cast_nullable_to_non_nullable
                  as String,
        kind: null == kind
            ? _self.kind
            : kind // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$Merchant {
  /// Stable string id (e.g. "mer_seven_eleven") — drives idempotent re-seed.
  String get id;

  /// Japanese display name (required — ja is the default locale).
  String get nameJa;

  /// Chinese display name (nullable — falls back to nameJa at render time).
  String? get nameZh;

  /// English display name (nullable — falls back to nameJa at render time).
  String? get nameEn;

  /// Region code (default 'JP' at the data layer).
  String get region;

  /// Real L2 category id (e.g. "cat_food_convenience_store").
  String get categoryId;

  /// Seed-derived ledger hint ('daily' | 'joy') — non-authoritative (D-09).
  String get ledgerHint;

  /// Expanded surface forms (name + aliases + per-locale) for this merchant.
  List<MerchantMatchKey> get surfaces;

  /// Create a copy of Merchant
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MerchantCopyWith<Merchant> get copyWith =>
      _$MerchantCopyWithImpl<Merchant>(this as Merchant, _$identity);

  /// Serializes this Merchant to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Merchant &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameJa, nameJa) || other.nameJa == nameJa) &&
            (identical(other.nameZh, nameZh) || other.nameZh == nameZh) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerHint, ledgerHint) ||
                other.ledgerHint == ledgerHint) &&
            const DeepCollectionEquality().equals(other.surfaces, surfaces));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nameJa,
    nameZh,
    nameEn,
    region,
    categoryId,
    ledgerHint,
    const DeepCollectionEquality().hash(surfaces),
  );

  @override
  String toString() {
    return 'Merchant(id: $id, nameJa: $nameJa, nameZh: $nameZh, nameEn: $nameEn, region: $region, categoryId: $categoryId, ledgerHint: $ledgerHint, surfaces: $surfaces)';
  }
}

/// @nodoc
abstract mixin class $MerchantCopyWith<$Res> {
  factory $MerchantCopyWith(Merchant value, $Res Function(Merchant) _then) =
      _$MerchantCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String nameJa,
    String? nameZh,
    String? nameEn,
    String region,
    String categoryId,
    String ledgerHint,
    List<MerchantMatchKey> surfaces,
  });
}

/// @nodoc
class _$MerchantCopyWithImpl<$Res> implements $MerchantCopyWith<$Res> {
  _$MerchantCopyWithImpl(this._self, this._then);

  final Merchant _self;
  final $Res Function(Merchant) _then;

  /// Create a copy of Merchant
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? nameJa = null,
    Object? nameZh = freezed,
    Object? nameEn = freezed,
    Object? region = null,
    Object? categoryId = null,
    Object? ledgerHint = null,
    Object? surfaces = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nameJa: null == nameJa
            ? _self.nameJa
            : nameJa // ignore: cast_nullable_to_non_nullable
                  as String,
        nameZh: freezed == nameZh
            ? _self.nameZh
            : nameZh // ignore: cast_nullable_to_non_nullable
                  as String?,
        nameEn: freezed == nameEn
            ? _self.nameEn
            : nameEn // ignore: cast_nullable_to_non_nullable
                  as String?,
        region: null == region
            ? _self.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerHint: null == ledgerHint
            ? _self.ledgerHint
            : ledgerHint // ignore: cast_nullable_to_non_nullable
                  as String,
        surfaces: null == surfaces
            ? _self.surfaces
            : surfaces // ignore: cast_nullable_to_non_nullable
                  as List<MerchantMatchKey>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Merchant].
extension MerchantPatterns on Merchant {
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
    TResult Function(_Merchant value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Merchant() when $default != null:
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
    TResult Function(_Merchant value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Merchant():
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
    TResult? Function(_Merchant value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Merchant() when $default != null:
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
      String nameJa,
      String? nameZh,
      String? nameEn,
      String region,
      String categoryId,
      String ledgerHint,
      List<MerchantMatchKey> surfaces,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Merchant() when $default != null:
        return $default(
          _that.id,
          _that.nameJa,
          _that.nameZh,
          _that.nameEn,
          _that.region,
          _that.categoryId,
          _that.ledgerHint,
          _that.surfaces,
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
      String nameJa,
      String? nameZh,
      String? nameEn,
      String region,
      String categoryId,
      String ledgerHint,
      List<MerchantMatchKey> surfaces,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Merchant():
        return $default(
          _that.id,
          _that.nameJa,
          _that.nameZh,
          _that.nameEn,
          _that.region,
          _that.categoryId,
          _that.ledgerHint,
          _that.surfaces,
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
      String nameJa,
      String? nameZh,
      String? nameEn,
      String region,
      String categoryId,
      String ledgerHint,
      List<MerchantMatchKey> surfaces,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Merchant() when $default != null:
        return $default(
          _that.id,
          _that.nameJa,
          _that.nameZh,
          _that.nameEn,
          _that.region,
          _that.categoryId,
          _that.ledgerHint,
          _that.surfaces,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Merchant implements Merchant {
  const _Merchant({
    required this.id,
    required this.nameJa,
    this.nameZh,
    this.nameEn,
    required this.region,
    required this.categoryId,
    required this.ledgerHint,
    final List<MerchantMatchKey> surfaces = const <MerchantMatchKey>[],
  }) : _surfaces = surfaces;
  factory _Merchant.fromJson(Map<String, dynamic> json) =>
      _$MerchantFromJson(json);

  /// Stable string id (e.g. "mer_seven_eleven") — drives idempotent re-seed.
  @override
  final String id;

  /// Japanese display name (required — ja is the default locale).
  @override
  final String nameJa;

  /// Chinese display name (nullable — falls back to nameJa at render time).
  @override
  final String? nameZh;

  /// English display name (nullable — falls back to nameJa at render time).
  @override
  final String? nameEn;

  /// Region code (default 'JP' at the data layer).
  @override
  final String region;

  /// Real L2 category id (e.g. "cat_food_convenience_store").
  @override
  final String categoryId;

  /// Seed-derived ledger hint ('daily' | 'joy') — non-authoritative (D-09).
  @override
  final String ledgerHint;

  /// Expanded surface forms (name + aliases + per-locale) for this merchant.
  final List<MerchantMatchKey> _surfaces;

  /// Expanded surface forms (name + aliases + per-locale) for this merchant.
  @override
  @JsonKey()
  List<MerchantMatchKey> get surfaces {
    if (_surfaces is EqualUnmodifiableListView) return _surfaces;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_surfaces);
  }

  /// Create a copy of Merchant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MerchantCopyWith<_Merchant> get copyWith =>
      __$MerchantCopyWithImpl<_Merchant>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MerchantToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Merchant &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.nameJa, nameJa) || other.nameJa == nameJa) &&
            (identical(other.nameZh, nameZh) || other.nameZh == nameZh) &&
            (identical(other.nameEn, nameEn) || other.nameEn == nameEn) &&
            (identical(other.region, region) || other.region == region) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerHint, ledgerHint) ||
                other.ledgerHint == ledgerHint) &&
            const DeepCollectionEquality().equals(other._surfaces, _surfaces));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    nameJa,
    nameZh,
    nameEn,
    region,
    categoryId,
    ledgerHint,
    const DeepCollectionEquality().hash(_surfaces),
  );

  @override
  String toString() {
    return 'Merchant(id: $id, nameJa: $nameJa, nameZh: $nameZh, nameEn: $nameEn, region: $region, categoryId: $categoryId, ledgerHint: $ledgerHint, surfaces: $surfaces)';
  }
}

/// @nodoc
abstract mixin class _$MerchantCopyWith<$Res>
    implements $MerchantCopyWith<$Res> {
  factory _$MerchantCopyWith(_Merchant value, $Res Function(_Merchant) _then) =
      __$MerchantCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String nameJa,
    String? nameZh,
    String? nameEn,
    String region,
    String categoryId,
    String ledgerHint,
    List<MerchantMatchKey> surfaces,
  });
}

/// @nodoc
class __$MerchantCopyWithImpl<$Res> implements _$MerchantCopyWith<$Res> {
  __$MerchantCopyWithImpl(this._self, this._then);

  final _Merchant _self;
  final $Res Function(_Merchant) _then;

  /// Create a copy of Merchant
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? nameJa = null,
    Object? nameZh = freezed,
    Object? nameEn = freezed,
    Object? region = null,
    Object? categoryId = null,
    Object? ledgerHint = null,
    Object? surfaces = null,
  }) {
    return _then(
      _Merchant(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        nameJa: null == nameJa
            ? _self.nameJa
            : nameJa // ignore: cast_nullable_to_non_nullable
                  as String,
        nameZh: freezed == nameZh
            ? _self.nameZh
            : nameZh // ignore: cast_nullable_to_non_nullable
                  as String?,
        nameEn: freezed == nameEn
            ? _self.nameEn
            : nameEn // ignore: cast_nullable_to_non_nullable
                  as String?,
        region: null == region
            ? _self.region
            : region // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerHint: null == ledgerHint
            ? _self.ledgerHint
            : ledgerHint // ignore: cast_nullable_to_non_nullable
                  as String,
        surfaces: null == surfaces
            ? _self._surfaces
            : surfaces // ignore: cast_nullable_to_non_nullable
                  as List<MerchantMatchKey>,
      ),
    );
  }
}
