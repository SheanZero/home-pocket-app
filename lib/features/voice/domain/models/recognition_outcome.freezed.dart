// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'recognition_outcome.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$RecognitionOutcome {
  /// The reconciled L2 category id. Null ONLY in the both-none cell
  /// (keyword missed and no merchant surfaced) — the form then collects
  /// amount/date only and the user picks the category manually.
  String? get selectedCategoryId;

  /// The confidence band for [selectedCategoryId] (D-10).
  ConfidenceBand get band;

  /// Ranked alternate categories for Phase-52 chips: the keyword's category
  /// first (if any), then merchant-derived categories in recognizer rank
  /// order, de-duplicated by L2 id.
  List<CategoryMatchResult> get alternates;

  /// D-13: the canonical keyword string threaded verbatim from the keyword
  /// verdict (260526-pg6 learning-key identity contract — write-key ==
  /// read-key). Null when no keyword was extracted.
  String? get resolvedKeyword;

  /// True when the keyword verdict won over a strong (>=0.85) merchant whose
  /// L2 differs — i.e. XVAL-02 「在星巴克买杯子」→购物 (the merchant cafe is
  /// demoted to an alternate). False otherwise.
  bool get keywordMerchantConflict;

  /// Create a copy of RecognitionOutcome
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $RecognitionOutcomeCopyWith<RecognitionOutcome> get copyWith =>
      _$RecognitionOutcomeCopyWithImpl<RecognitionOutcome>(
        this as RecognitionOutcome,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is RecognitionOutcome &&
            (identical(other.selectedCategoryId, selectedCategoryId) ||
                other.selectedCategoryId == selectedCategoryId) &&
            (identical(other.band, band) || other.band == band) &&
            const DeepCollectionEquality().equals(
              other.alternates,
              alternates,
            ) &&
            (identical(other.resolvedKeyword, resolvedKeyword) ||
                other.resolvedKeyword == resolvedKeyword) &&
            (identical(
                  other.keywordMerchantConflict,
                  keywordMerchantConflict,
                ) ||
                other.keywordMerchantConflict == keywordMerchantConflict));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    selectedCategoryId,
    band,
    const DeepCollectionEquality().hash(alternates),
    resolvedKeyword,
    keywordMerchantConflict,
  );

  @override
  String toString() {
    return 'RecognitionOutcome(selectedCategoryId: $selectedCategoryId, band: $band, alternates: $alternates, resolvedKeyword: $resolvedKeyword, keywordMerchantConflict: $keywordMerchantConflict)';
  }
}

/// @nodoc
abstract mixin class $RecognitionOutcomeCopyWith<$Res> {
  factory $RecognitionOutcomeCopyWith(
    RecognitionOutcome value,
    $Res Function(RecognitionOutcome) _then,
  ) = _$RecognitionOutcomeCopyWithImpl;
  @useResult
  $Res call({
    String? selectedCategoryId,
    ConfidenceBand band,
    List<CategoryMatchResult> alternates,
    String? resolvedKeyword,
    bool keywordMerchantConflict,
  });
}

/// @nodoc
class _$RecognitionOutcomeCopyWithImpl<$Res>
    implements $RecognitionOutcomeCopyWith<$Res> {
  _$RecognitionOutcomeCopyWithImpl(this._self, this._then);

  final RecognitionOutcome _self;
  final $Res Function(RecognitionOutcome) _then;

  /// Create a copy of RecognitionOutcome
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? selectedCategoryId = freezed,
    Object? band = null,
    Object? alternates = null,
    Object? resolvedKeyword = freezed,
    Object? keywordMerchantConflict = null,
  }) {
    return _then(
      _self.copyWith(
        selectedCategoryId: freezed == selectedCategoryId
            ? _self.selectedCategoryId
            : selectedCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        band: null == band
            ? _self.band
            : band // ignore: cast_nullable_to_non_nullable
                  as ConfidenceBand,
        alternates: null == alternates
            ? _self.alternates
            : alternates // ignore: cast_nullable_to_non_nullable
                  as List<CategoryMatchResult>,
        resolvedKeyword: freezed == resolvedKeyword
            ? _self.resolvedKeyword
            : resolvedKeyword // ignore: cast_nullable_to_non_nullable
                  as String?,
        keywordMerchantConflict: null == keywordMerchantConflict
            ? _self.keywordMerchantConflict
            : keywordMerchantConflict // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [RecognitionOutcome].
extension RecognitionOutcomePatterns on RecognitionOutcome {
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
    TResult Function(_RecognitionOutcome value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecognitionOutcome() when $default != null:
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
    TResult Function(_RecognitionOutcome value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecognitionOutcome():
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
    TResult? Function(_RecognitionOutcome value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecognitionOutcome() when $default != null:
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
      String? selectedCategoryId,
      ConfidenceBand band,
      List<CategoryMatchResult> alternates,
      String? resolvedKeyword,
      bool keywordMerchantConflict,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _RecognitionOutcome() when $default != null:
        return $default(
          _that.selectedCategoryId,
          _that.band,
          _that.alternates,
          _that.resolvedKeyword,
          _that.keywordMerchantConflict,
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
      String? selectedCategoryId,
      ConfidenceBand band,
      List<CategoryMatchResult> alternates,
      String? resolvedKeyword,
      bool keywordMerchantConflict,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecognitionOutcome():
        return $default(
          _that.selectedCategoryId,
          _that.band,
          _that.alternates,
          _that.resolvedKeyword,
          _that.keywordMerchantConflict,
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
      String? selectedCategoryId,
      ConfidenceBand band,
      List<CategoryMatchResult> alternates,
      String? resolvedKeyword,
      bool keywordMerchantConflict,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _RecognitionOutcome() when $default != null:
        return $default(
          _that.selectedCategoryId,
          _that.band,
          _that.alternates,
          _that.resolvedKeyword,
          _that.keywordMerchantConflict,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _RecognitionOutcome implements RecognitionOutcome {
  const _RecognitionOutcome({
    this.selectedCategoryId,
    required this.band,
    final List<CategoryMatchResult> alternates = const <CategoryMatchResult>[],
    this.resolvedKeyword,
    this.keywordMerchantConflict = false,
  }) : _alternates = alternates;

  /// The reconciled L2 category id. Null ONLY in the both-none cell
  /// (keyword missed and no merchant surfaced) — the form then collects
  /// amount/date only and the user picks the category manually.
  @override
  final String? selectedCategoryId;

  /// The confidence band for [selectedCategoryId] (D-10).
  @override
  final ConfidenceBand band;

  /// Ranked alternate categories for Phase-52 chips: the keyword's category
  /// first (if any), then merchant-derived categories in recognizer rank
  /// order, de-duplicated by L2 id.
  final List<CategoryMatchResult> _alternates;

  /// Ranked alternate categories for Phase-52 chips: the keyword's category
  /// first (if any), then merchant-derived categories in recognizer rank
  /// order, de-duplicated by L2 id.
  @override
  @JsonKey()
  List<CategoryMatchResult> get alternates {
    if (_alternates is EqualUnmodifiableListView) return _alternates;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_alternates);
  }

  /// D-13: the canonical keyword string threaded verbatim from the keyword
  /// verdict (260526-pg6 learning-key identity contract — write-key ==
  /// read-key). Null when no keyword was extracted.
  @override
  final String? resolvedKeyword;

  /// True when the keyword verdict won over a strong (>=0.85) merchant whose
  /// L2 differs — i.e. XVAL-02 「在星巴克买杯子」→购物 (the merchant cafe is
  /// demoted to an alternate). False otherwise.
  @override
  @JsonKey()
  final bool keywordMerchantConflict;

  /// Create a copy of RecognitionOutcome
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$RecognitionOutcomeCopyWith<_RecognitionOutcome> get copyWith =>
      __$RecognitionOutcomeCopyWithImpl<_RecognitionOutcome>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _RecognitionOutcome &&
            (identical(other.selectedCategoryId, selectedCategoryId) ||
                other.selectedCategoryId == selectedCategoryId) &&
            (identical(other.band, band) || other.band == band) &&
            const DeepCollectionEquality().equals(
              other._alternates,
              _alternates,
            ) &&
            (identical(other.resolvedKeyword, resolvedKeyword) ||
                other.resolvedKeyword == resolvedKeyword) &&
            (identical(
                  other.keywordMerchantConflict,
                  keywordMerchantConflict,
                ) ||
                other.keywordMerchantConflict == keywordMerchantConflict));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    selectedCategoryId,
    band,
    const DeepCollectionEquality().hash(_alternates),
    resolvedKeyword,
    keywordMerchantConflict,
  );

  @override
  String toString() {
    return 'RecognitionOutcome(selectedCategoryId: $selectedCategoryId, band: $band, alternates: $alternates, resolvedKeyword: $resolvedKeyword, keywordMerchantConflict: $keywordMerchantConflict)';
  }
}

/// @nodoc
abstract mixin class _$RecognitionOutcomeCopyWith<$Res>
    implements $RecognitionOutcomeCopyWith<$Res> {
  factory _$RecognitionOutcomeCopyWith(
    _RecognitionOutcome value,
    $Res Function(_RecognitionOutcome) _then,
  ) = __$RecognitionOutcomeCopyWithImpl;
  @override
  @useResult
  $Res call({
    String? selectedCategoryId,
    ConfidenceBand band,
    List<CategoryMatchResult> alternates,
    String? resolvedKeyword,
    bool keywordMerchantConflict,
  });
}

/// @nodoc
class __$RecognitionOutcomeCopyWithImpl<$Res>
    implements _$RecognitionOutcomeCopyWith<$Res> {
  __$RecognitionOutcomeCopyWithImpl(this._self, this._then);

  final _RecognitionOutcome _self;
  final $Res Function(_RecognitionOutcome) _then;

  /// Create a copy of RecognitionOutcome
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? selectedCategoryId = freezed,
    Object? band = null,
    Object? alternates = null,
    Object? resolvedKeyword = freezed,
    Object? keywordMerchantConflict = null,
  }) {
    return _then(
      _RecognitionOutcome(
        selectedCategoryId: freezed == selectedCategoryId
            ? _self.selectedCategoryId
            : selectedCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        band: null == band
            ? _self.band
            : band // ignore: cast_nullable_to_non_nullable
                  as ConfidenceBand,
        alternates: null == alternates
            ? _self._alternates
            : alternates // ignore: cast_nullable_to_non_nullable
                  as List<CategoryMatchResult>,
        resolvedKeyword: freezed == resolvedKeyword
            ? _self.resolvedKeyword
            : resolvedKeyword // ignore: cast_nullable_to_non_nullable
                  as String?,
        keywordMerchantConflict: null == keywordMerchantConflict
            ? _self.keywordMerchantConflict
            : keywordMerchantConflict // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
