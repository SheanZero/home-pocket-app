// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'merchant_candidate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MerchantCandidate {
  String get merchantId;
  String get displayName;

  /// Raw match score — no banding this phase (D-01 / RESEARCH Open Q #2).
  double get score;
  String get categoryId;

  /// Non-authoritative ledger hint (Phase 49 D-09) — never stamped as ledger.
  String get ledgerHint;

  /// Create a copy of MerchantCandidate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MerchantCandidateCopyWith<MerchantCandidate> get copyWith =>
      _$MerchantCandidateCopyWithImpl<MerchantCandidate>(
        this as MerchantCandidate,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MerchantCandidate &&
            (identical(other.merchantId, merchantId) ||
                other.merchantId == merchantId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerHint, ledgerHint) ||
                other.ledgerHint == ledgerHint));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    merchantId,
    displayName,
    score,
    categoryId,
    ledgerHint,
  );

  @override
  String toString() {
    return 'MerchantCandidate(merchantId: $merchantId, displayName: $displayName, score: $score, categoryId: $categoryId, ledgerHint: $ledgerHint)';
  }
}

/// @nodoc
abstract mixin class $MerchantCandidateCopyWith<$Res> {
  factory $MerchantCandidateCopyWith(
    MerchantCandidate value,
    $Res Function(MerchantCandidate) _then,
  ) = _$MerchantCandidateCopyWithImpl;
  @useResult
  $Res call({
    String merchantId,
    String displayName,
    double score,
    String categoryId,
    String ledgerHint,
  });
}

/// @nodoc
class _$MerchantCandidateCopyWithImpl<$Res>
    implements $MerchantCandidateCopyWith<$Res> {
  _$MerchantCandidateCopyWithImpl(this._self, this._then);

  final MerchantCandidate _self;
  final $Res Function(MerchantCandidate) _then;

  /// Create a copy of MerchantCandidate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? merchantId = null,
    Object? displayName = null,
    Object? score = null,
    Object? categoryId = null,
    Object? ledgerHint = null,
  }) {
    return _then(
      _self.copyWith(
        merchantId: null == merchantId
            ? _self.merchantId
            : merchantId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _self.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _self.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
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

/// Adds pattern-matching-related methods to [MerchantCandidate].
extension MerchantCandidatePatterns on MerchantCandidate {
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
    TResult Function(_MerchantCandidate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MerchantCandidate() when $default != null:
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
    TResult Function(_MerchantCandidate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantCandidate():
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
    TResult? Function(_MerchantCandidate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantCandidate() when $default != null:
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
      String merchantId,
      String displayName,
      double score,
      String categoryId,
      String ledgerHint,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MerchantCandidate() when $default != null:
        return $default(
          _that.merchantId,
          _that.displayName,
          _that.score,
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
      String merchantId,
      String displayName,
      double score,
      String categoryId,
      String ledgerHint,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantCandidate():
        return $default(
          _that.merchantId,
          _that.displayName,
          _that.score,
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
      String merchantId,
      String displayName,
      double score,
      String categoryId,
      String ledgerHint,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MerchantCandidate() when $default != null:
        return $default(
          _that.merchantId,
          _that.displayName,
          _that.score,
          _that.categoryId,
          _that.ledgerHint,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MerchantCandidate implements MerchantCandidate {
  const _MerchantCandidate({
    required this.merchantId,
    required this.displayName,
    required this.score,
    required this.categoryId,
    required this.ledgerHint,
  });

  @override
  final String merchantId;
  @override
  final String displayName;

  /// Raw match score — no banding this phase (D-01 / RESEARCH Open Q #2).
  @override
  final double score;
  @override
  final String categoryId;

  /// Non-authoritative ledger hint (Phase 49 D-09) — never stamped as ledger.
  @override
  final String ledgerHint;

  /// Create a copy of MerchantCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MerchantCandidateCopyWith<_MerchantCandidate> get copyWith =>
      __$MerchantCandidateCopyWithImpl<_MerchantCandidate>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MerchantCandidate &&
            (identical(other.merchantId, merchantId) ||
                other.merchantId == merchantId) &&
            (identical(other.displayName, displayName) ||
                other.displayName == displayName) &&
            (identical(other.score, score) || other.score == score) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerHint, ledgerHint) ||
                other.ledgerHint == ledgerHint));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    merchantId,
    displayName,
    score,
    categoryId,
    ledgerHint,
  );

  @override
  String toString() {
    return 'MerchantCandidate(merchantId: $merchantId, displayName: $displayName, score: $score, categoryId: $categoryId, ledgerHint: $ledgerHint)';
  }
}

/// @nodoc
abstract mixin class _$MerchantCandidateCopyWith<$Res>
    implements $MerchantCandidateCopyWith<$Res> {
  factory _$MerchantCandidateCopyWith(
    _MerchantCandidate value,
    $Res Function(_MerchantCandidate) _then,
  ) = __$MerchantCandidateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String merchantId,
    String displayName,
    double score,
    String categoryId,
    String ledgerHint,
  });
}

/// @nodoc
class __$MerchantCandidateCopyWithImpl<$Res>
    implements _$MerchantCandidateCopyWith<$Res> {
  __$MerchantCandidateCopyWithImpl(this._self, this._then);

  final _MerchantCandidate _self;
  final $Res Function(_MerchantCandidate) _then;

  /// Create a copy of MerchantCandidate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? merchantId = null,
    Object? displayName = null,
    Object? score = null,
    Object? categoryId = null,
    Object? ledgerHint = null,
  }) {
    return _then(
      _MerchantCandidate(
        merchantId: null == merchantId
            ? _self.merchantId
            : merchantId // ignore: cast_nullable_to_non_nullable
                  as String,
        displayName: null == displayName
            ? _self.displayName
            : displayName // ignore: cast_nullable_to_non_nullable
                  as String,
        score: null == score
            ? _self.score
            : score // ignore: cast_nullable_to_non_nullable
                  as double,
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
