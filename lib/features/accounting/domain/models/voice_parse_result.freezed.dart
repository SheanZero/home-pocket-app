// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'voice_parse_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$VoiceParseResult {
  String get rawText;
  int?
  get amount; // Merchant fields stored as primitives (no MerchantMatch reference)
  String? get merchantName;
  String? get merchantCategoryId;
  LedgerType? get merchantLedgerType; // Category keyword match
  CategoryMatchResult?
  get categoryMatch; // Resolved ledger type (from merchant or category)
  LedgerType? get ledgerType;
  int get estimatedSatisfaction;

  /// Create a copy of VoiceParseResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VoiceParseResultCopyWith<VoiceParseResult> get copyWith =>
      _$VoiceParseResultCopyWithImpl<VoiceParseResult>(
        this as VoiceParseResult,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VoiceParseResult &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.merchantCategoryId, merchantCategoryId) ||
                other.merchantCategoryId == merchantCategoryId) &&
            (identical(other.merchantLedgerType, merchantLedgerType) ||
                other.merchantLedgerType == merchantLedgerType) &&
            (identical(other.categoryMatch, categoryMatch) ||
                other.categoryMatch == categoryMatch) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.estimatedSatisfaction, estimatedSatisfaction) ||
                other.estimatedSatisfaction == estimatedSatisfaction));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    rawText,
    amount,
    merchantName,
    merchantCategoryId,
    merchantLedgerType,
    categoryMatch,
    ledgerType,
    estimatedSatisfaction,
  );

  @override
  String toString() {
    return 'VoiceParseResult(rawText: $rawText, amount: $amount, merchantName: $merchantName, merchantCategoryId: $merchantCategoryId, merchantLedgerType: $merchantLedgerType, categoryMatch: $categoryMatch, ledgerType: $ledgerType, estimatedSatisfaction: $estimatedSatisfaction)';
  }
}

/// @nodoc
abstract mixin class $VoiceParseResultCopyWith<$Res> {
  factory $VoiceParseResultCopyWith(
    VoiceParseResult value,
    $Res Function(VoiceParseResult) _then,
  ) = _$VoiceParseResultCopyWithImpl;
  @useResult
  $Res call({
    String rawText,
    int? amount,
    String? merchantName,
    String? merchantCategoryId,
    LedgerType? merchantLedgerType,
    CategoryMatchResult? categoryMatch,
    LedgerType? ledgerType,
    int estimatedSatisfaction,
  });

  $CategoryMatchResultCopyWith<$Res>? get categoryMatch;
}

/// @nodoc
class _$VoiceParseResultCopyWithImpl<$Res>
    implements $VoiceParseResultCopyWith<$Res> {
  _$VoiceParseResultCopyWithImpl(this._self, this._then);

  final VoiceParseResult _self;
  final $Res Function(VoiceParseResult) _then;

  /// Create a copy of VoiceParseResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? rawText = null,
    Object? amount = freezed,
    Object? merchantName = freezed,
    Object? merchantCategoryId = freezed,
    Object? merchantLedgerType = freezed,
    Object? categoryMatch = freezed,
    Object? ledgerType = freezed,
    Object? estimatedSatisfaction = null,
  }) {
    return _then(
      _self.copyWith(
        rawText: null == rawText
            ? _self.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: freezed == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int?,
        merchantName: freezed == merchantName
            ? _self.merchantName
            : merchantName // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchantCategoryId: freezed == merchantCategoryId
            ? _self.merchantCategoryId
            : merchantCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchantLedgerType: freezed == merchantLedgerType
            ? _self.merchantLedgerType
            : merchantLedgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryMatch: freezed == categoryMatch
            ? _self.categoryMatch
            : categoryMatch // ignore: cast_nullable_to_non_nullable
                  as CategoryMatchResult?,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        estimatedSatisfaction: null == estimatedSatisfaction
            ? _self.estimatedSatisfaction
            : estimatedSatisfaction // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }

  /// Create a copy of VoiceParseResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryMatchResultCopyWith<$Res>? get categoryMatch {
    if (_self.categoryMatch == null) {
      return null;
    }

    return $CategoryMatchResultCopyWith<$Res>(_self.categoryMatch!, (value) {
      return _then(_self.copyWith(categoryMatch: value));
    });
  }
}

/// Adds pattern-matching-related methods to [VoiceParseResult].
extension VoiceParseResultPatterns on VoiceParseResult {
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
    TResult Function(_VoiceParseResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VoiceParseResult() when $default != null:
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
    TResult Function(_VoiceParseResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceParseResult():
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
    TResult? Function(_VoiceParseResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceParseResult() when $default != null:
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
      String rawText,
      int? amount,
      String? merchantName,
      String? merchantCategoryId,
      LedgerType? merchantLedgerType,
      CategoryMatchResult? categoryMatch,
      LedgerType? ledgerType,
      int estimatedSatisfaction,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VoiceParseResult() when $default != null:
        return $default(
          _that.rawText,
          _that.amount,
          _that.merchantName,
          _that.merchantCategoryId,
          _that.merchantLedgerType,
          _that.categoryMatch,
          _that.ledgerType,
          _that.estimatedSatisfaction,
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
      String rawText,
      int? amount,
      String? merchantName,
      String? merchantCategoryId,
      LedgerType? merchantLedgerType,
      CategoryMatchResult? categoryMatch,
      LedgerType? ledgerType,
      int estimatedSatisfaction,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceParseResult():
        return $default(
          _that.rawText,
          _that.amount,
          _that.merchantName,
          _that.merchantCategoryId,
          _that.merchantLedgerType,
          _that.categoryMatch,
          _that.ledgerType,
          _that.estimatedSatisfaction,
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
      String rawText,
      int? amount,
      String? merchantName,
      String? merchantCategoryId,
      LedgerType? merchantLedgerType,
      CategoryMatchResult? categoryMatch,
      LedgerType? ledgerType,
      int estimatedSatisfaction,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceParseResult() when $default != null:
        return $default(
          _that.rawText,
          _that.amount,
          _that.merchantName,
          _that.merchantCategoryId,
          _that.merchantLedgerType,
          _that.categoryMatch,
          _that.ledgerType,
          _that.estimatedSatisfaction,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _VoiceParseResult implements VoiceParseResult {
  const _VoiceParseResult({
    required this.rawText,
    this.amount,
    this.merchantName,
    this.merchantCategoryId,
    this.merchantLedgerType,
    this.categoryMatch,
    this.ledgerType,
    this.estimatedSatisfaction = 5,
  });

  @override
  final String rawText;
  @override
  final int? amount;
  // Merchant fields stored as primitives (no MerchantMatch reference)
  @override
  final String? merchantName;
  @override
  final String? merchantCategoryId;
  @override
  final LedgerType? merchantLedgerType;
  // Category keyword match
  @override
  final CategoryMatchResult? categoryMatch;
  // Resolved ledger type (from merchant or category)
  @override
  final LedgerType? ledgerType;
  @override
  @JsonKey()
  final int estimatedSatisfaction;

  /// Create a copy of VoiceParseResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VoiceParseResultCopyWith<_VoiceParseResult> get copyWith =>
      __$VoiceParseResultCopyWithImpl<_VoiceParseResult>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VoiceParseResult &&
            (identical(other.rawText, rawText) || other.rawText == rawText) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.merchantName, merchantName) ||
                other.merchantName == merchantName) &&
            (identical(other.merchantCategoryId, merchantCategoryId) ||
                other.merchantCategoryId == merchantCategoryId) &&
            (identical(other.merchantLedgerType, merchantLedgerType) ||
                other.merchantLedgerType == merchantLedgerType) &&
            (identical(other.categoryMatch, categoryMatch) ||
                other.categoryMatch == categoryMatch) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.estimatedSatisfaction, estimatedSatisfaction) ||
                other.estimatedSatisfaction == estimatedSatisfaction));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    rawText,
    amount,
    merchantName,
    merchantCategoryId,
    merchantLedgerType,
    categoryMatch,
    ledgerType,
    estimatedSatisfaction,
  );

  @override
  String toString() {
    return 'VoiceParseResult(rawText: $rawText, amount: $amount, merchantName: $merchantName, merchantCategoryId: $merchantCategoryId, merchantLedgerType: $merchantLedgerType, categoryMatch: $categoryMatch, ledgerType: $ledgerType, estimatedSatisfaction: $estimatedSatisfaction)';
  }
}

/// @nodoc
abstract mixin class _$VoiceParseResultCopyWith<$Res>
    implements $VoiceParseResultCopyWith<$Res> {
  factory _$VoiceParseResultCopyWith(
    _VoiceParseResult value,
    $Res Function(_VoiceParseResult) _then,
  ) = __$VoiceParseResultCopyWithImpl;
  @override
  @useResult
  $Res call({
    String rawText,
    int? amount,
    String? merchantName,
    String? merchantCategoryId,
    LedgerType? merchantLedgerType,
    CategoryMatchResult? categoryMatch,
    LedgerType? ledgerType,
    int estimatedSatisfaction,
  });

  @override
  $CategoryMatchResultCopyWith<$Res>? get categoryMatch;
}

/// @nodoc
class __$VoiceParseResultCopyWithImpl<$Res>
    implements _$VoiceParseResultCopyWith<$Res> {
  __$VoiceParseResultCopyWithImpl(this._self, this._then);

  final _VoiceParseResult _self;
  final $Res Function(_VoiceParseResult) _then;

  /// Create a copy of VoiceParseResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? rawText = null,
    Object? amount = freezed,
    Object? merchantName = freezed,
    Object? merchantCategoryId = freezed,
    Object? merchantLedgerType = freezed,
    Object? categoryMatch = freezed,
    Object? ledgerType = freezed,
    Object? estimatedSatisfaction = null,
  }) {
    return _then(
      _VoiceParseResult(
        rawText: null == rawText
            ? _self.rawText
            : rawText // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: freezed == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int?,
        merchantName: freezed == merchantName
            ? _self.merchantName
            : merchantName // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchantCategoryId: freezed == merchantCategoryId
            ? _self.merchantCategoryId
            : merchantCategoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchantLedgerType: freezed == merchantLedgerType
            ? _self.merchantLedgerType
            : merchantLedgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryMatch: freezed == categoryMatch
            ? _self.categoryMatch
            : categoryMatch // ignore: cast_nullable_to_non_nullable
                  as CategoryMatchResult?,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        estimatedSatisfaction: null == estimatedSatisfaction
            ? _self.estimatedSatisfaction
            : estimatedSatisfaction // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }

  /// Create a copy of VoiceParseResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryMatchResultCopyWith<$Res>? get categoryMatch {
    if (_self.categoryMatch == null) {
      return null;
    }

    return $CategoryMatchResultCopyWith<$Res>(_self.categoryMatch!, (value) {
      return _then(_self.copyWith(categoryMatch: value));
    });
  }
}

/// @nodoc
mixin _$CategoryMatchResult {
  String get categoryId;
  double get confidence;
  MatchSource get source;

  /// Create a copy of CategoryMatchResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CategoryMatchResultCopyWith<CategoryMatchResult> get copyWith =>
      _$CategoryMatchResultCopyWithImpl<CategoryMatchResult>(
        this as CategoryMatchResult,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CategoryMatchResult &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.source, source) || other.source == source));
  }

  @override
  int get hashCode => Object.hash(runtimeType, categoryId, confidence, source);

  @override
  String toString() {
    return 'CategoryMatchResult(categoryId: $categoryId, confidence: $confidence, source: $source)';
  }
}

/// @nodoc
abstract mixin class $CategoryMatchResultCopyWith<$Res> {
  factory $CategoryMatchResultCopyWith(
    CategoryMatchResult value,
    $Res Function(CategoryMatchResult) _then,
  ) = _$CategoryMatchResultCopyWithImpl;
  @useResult
  $Res call({String categoryId, double confidence, MatchSource source});
}

/// @nodoc
class _$CategoryMatchResultCopyWithImpl<$Res>
    implements $CategoryMatchResultCopyWith<$Res> {
  _$CategoryMatchResultCopyWithImpl(this._self, this._then);

  final CategoryMatchResult _self;
  final $Res Function(CategoryMatchResult) _then;

  /// Create a copy of CategoryMatchResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? confidence = null,
    Object? source = null,
  }) {
    return _then(
      _self.copyWith(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _self.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as MatchSource,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CategoryMatchResult].
extension CategoryMatchResultPatterns on CategoryMatchResult {
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
    TResult Function(_CategoryMatchResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryMatchResult() when $default != null:
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
    TResult Function(_CategoryMatchResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryMatchResult():
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
    TResult? Function(_CategoryMatchResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryMatchResult() when $default != null:
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
    TResult Function(String categoryId, double confidence, MatchSource source)?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryMatchResult() when $default != null:
        return $default(_that.categoryId, _that.confidence, _that.source);
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
    TResult Function(String categoryId, double confidence, MatchSource source)
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryMatchResult():
        return $default(_that.categoryId, _that.confidence, _that.source);
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
    TResult? Function(String categoryId, double confidence, MatchSource source)?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryMatchResult() when $default != null:
        return $default(_that.categoryId, _that.confidence, _that.source);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _CategoryMatchResult implements CategoryMatchResult {
  const _CategoryMatchResult({
    required this.categoryId,
    required this.confidence,
    required this.source,
  });

  @override
  final String categoryId;
  @override
  final double confidence;
  @override
  final MatchSource source;

  /// Create a copy of CategoryMatchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CategoryMatchResultCopyWith<_CategoryMatchResult> get copyWith =>
      __$CategoryMatchResultCopyWithImpl<_CategoryMatchResult>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CategoryMatchResult &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.confidence, confidence) ||
                other.confidence == confidence) &&
            (identical(other.source, source) || other.source == source));
  }

  @override
  int get hashCode => Object.hash(runtimeType, categoryId, confidence, source);

  @override
  String toString() {
    return 'CategoryMatchResult(categoryId: $categoryId, confidence: $confidence, source: $source)';
  }
}

/// @nodoc
abstract mixin class _$CategoryMatchResultCopyWith<$Res>
    implements $CategoryMatchResultCopyWith<$Res> {
  factory _$CategoryMatchResultCopyWith(
    _CategoryMatchResult value,
    $Res Function(_CategoryMatchResult) _then,
  ) = __$CategoryMatchResultCopyWithImpl;
  @override
  @useResult
  $Res call({String categoryId, double confidence, MatchSource source});
}

/// @nodoc
class __$CategoryMatchResultCopyWithImpl<$Res>
    implements _$CategoryMatchResultCopyWith<$Res> {
  __$CategoryMatchResultCopyWithImpl(this._self, this._then);

  final _CategoryMatchResult _self;
  final $Res Function(_CategoryMatchResult) _then;

  /// Create a copy of CategoryMatchResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? confidence = null,
    Object? source = null,
  }) {
    return _then(
      _CategoryMatchResult(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        confidence: null == confidence
            ? _self.confidence
            : confidence // ignore: cast_nullable_to_non_nullable
                  as double,
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as MatchSource,
      ),
    );
  }
}

/// @nodoc
mixin _$VoiceAudioFeatures {
  List<double> get soundLevels;
  List<DateTime> get timestamps;
  DateTime get startTime;
  DateTime get endTime;
  int get partialResultCount;
  int get wordCount;

  /// Create a copy of VoiceAudioFeatures
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $VoiceAudioFeaturesCopyWith<VoiceAudioFeatures> get copyWith =>
      _$VoiceAudioFeaturesCopyWithImpl<VoiceAudioFeatures>(
        this as VoiceAudioFeatures,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is VoiceAudioFeatures &&
            const DeepCollectionEquality().equals(
              other.soundLevels,
              soundLevels,
            ) &&
            const DeepCollectionEquality().equals(
              other.timestamps,
              timestamps,
            ) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.partialResultCount, partialResultCount) ||
                other.partialResultCount == partialResultCount) &&
            (identical(other.wordCount, wordCount) ||
                other.wordCount == wordCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(soundLevels),
    const DeepCollectionEquality().hash(timestamps),
    startTime,
    endTime,
    partialResultCount,
    wordCount,
  );

  @override
  String toString() {
    return 'VoiceAudioFeatures(soundLevels: $soundLevels, timestamps: $timestamps, startTime: $startTime, endTime: $endTime, partialResultCount: $partialResultCount, wordCount: $wordCount)';
  }
}

/// @nodoc
abstract mixin class $VoiceAudioFeaturesCopyWith<$Res> {
  factory $VoiceAudioFeaturesCopyWith(
    VoiceAudioFeatures value,
    $Res Function(VoiceAudioFeatures) _then,
  ) = _$VoiceAudioFeaturesCopyWithImpl;
  @useResult
  $Res call({
    List<double> soundLevels,
    List<DateTime> timestamps,
    DateTime startTime,
    DateTime endTime,
    int partialResultCount,
    int wordCount,
  });
}

/// @nodoc
class _$VoiceAudioFeaturesCopyWithImpl<$Res>
    implements $VoiceAudioFeaturesCopyWith<$Res> {
  _$VoiceAudioFeaturesCopyWithImpl(this._self, this._then);

  final VoiceAudioFeatures _self;
  final $Res Function(VoiceAudioFeatures) _then;

  /// Create a copy of VoiceAudioFeatures
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? soundLevels = null,
    Object? timestamps = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? partialResultCount = null,
    Object? wordCount = null,
  }) {
    return _then(
      _self.copyWith(
        soundLevels: null == soundLevels
            ? _self.soundLevels
            : soundLevels // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        timestamps: null == timestamps
            ? _self.timestamps
            : timestamps // ignore: cast_nullable_to_non_nullable
                  as List<DateTime>,
        startTime: null == startTime
            ? _self.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endTime: null == endTime
            ? _self.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        partialResultCount: null == partialResultCount
            ? _self.partialResultCount
            : partialResultCount // ignore: cast_nullable_to_non_nullable
                  as int,
        wordCount: null == wordCount
            ? _self.wordCount
            : wordCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [VoiceAudioFeatures].
extension VoiceAudioFeaturesPatterns on VoiceAudioFeatures {
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
    TResult Function(_VoiceAudioFeatures value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VoiceAudioFeatures() when $default != null:
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
    TResult Function(_VoiceAudioFeatures value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceAudioFeatures():
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
    TResult? Function(_VoiceAudioFeatures value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceAudioFeatures() when $default != null:
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
      List<double> soundLevels,
      List<DateTime> timestamps,
      DateTime startTime,
      DateTime endTime,
      int partialResultCount,
      int wordCount,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _VoiceAudioFeatures() when $default != null:
        return $default(
          _that.soundLevels,
          _that.timestamps,
          _that.startTime,
          _that.endTime,
          _that.partialResultCount,
          _that.wordCount,
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
      List<double> soundLevels,
      List<DateTime> timestamps,
      DateTime startTime,
      DateTime endTime,
      int partialResultCount,
      int wordCount,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceAudioFeatures():
        return $default(
          _that.soundLevels,
          _that.timestamps,
          _that.startTime,
          _that.endTime,
          _that.partialResultCount,
          _that.wordCount,
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
      List<double> soundLevels,
      List<DateTime> timestamps,
      DateTime startTime,
      DateTime endTime,
      int partialResultCount,
      int wordCount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _VoiceAudioFeatures() when $default != null:
        return $default(
          _that.soundLevels,
          _that.timestamps,
          _that.startTime,
          _that.endTime,
          _that.partialResultCount,
          _that.wordCount,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _VoiceAudioFeatures implements VoiceAudioFeatures {
  const _VoiceAudioFeatures({
    required final List<double> soundLevels,
    required final List<DateTime> timestamps,
    required this.startTime,
    required this.endTime,
    required this.partialResultCount,
    required this.wordCount,
  }) : _soundLevels = soundLevels,
       _timestamps = timestamps;

  final List<double> _soundLevels;
  @override
  List<double> get soundLevels {
    if (_soundLevels is EqualUnmodifiableListView) return _soundLevels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_soundLevels);
  }

  final List<DateTime> _timestamps;
  @override
  List<DateTime> get timestamps {
    if (_timestamps is EqualUnmodifiableListView) return _timestamps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_timestamps);
  }

  @override
  final DateTime startTime;
  @override
  final DateTime endTime;
  @override
  final int partialResultCount;
  @override
  final int wordCount;

  /// Create a copy of VoiceAudioFeatures
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$VoiceAudioFeaturesCopyWith<_VoiceAudioFeatures> get copyWith =>
      __$VoiceAudioFeaturesCopyWithImpl<_VoiceAudioFeatures>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _VoiceAudioFeatures &&
            const DeepCollectionEquality().equals(
              other._soundLevels,
              _soundLevels,
            ) &&
            const DeepCollectionEquality().equals(
              other._timestamps,
              _timestamps,
            ) &&
            (identical(other.startTime, startTime) ||
                other.startTime == startTime) &&
            (identical(other.endTime, endTime) || other.endTime == endTime) &&
            (identical(other.partialResultCount, partialResultCount) ||
                other.partialResultCount == partialResultCount) &&
            (identical(other.wordCount, wordCount) ||
                other.wordCount == wordCount));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    const DeepCollectionEquality().hash(_soundLevels),
    const DeepCollectionEquality().hash(_timestamps),
    startTime,
    endTime,
    partialResultCount,
    wordCount,
  );

  @override
  String toString() {
    return 'VoiceAudioFeatures(soundLevels: $soundLevels, timestamps: $timestamps, startTime: $startTime, endTime: $endTime, partialResultCount: $partialResultCount, wordCount: $wordCount)';
  }
}

/// @nodoc
abstract mixin class _$VoiceAudioFeaturesCopyWith<$Res>
    implements $VoiceAudioFeaturesCopyWith<$Res> {
  factory _$VoiceAudioFeaturesCopyWith(
    _VoiceAudioFeatures value,
    $Res Function(_VoiceAudioFeatures) _then,
  ) = __$VoiceAudioFeaturesCopyWithImpl;
  @override
  @useResult
  $Res call({
    List<double> soundLevels,
    List<DateTime> timestamps,
    DateTime startTime,
    DateTime endTime,
    int partialResultCount,
    int wordCount,
  });
}

/// @nodoc
class __$VoiceAudioFeaturesCopyWithImpl<$Res>
    implements _$VoiceAudioFeaturesCopyWith<$Res> {
  __$VoiceAudioFeaturesCopyWithImpl(this._self, this._then);

  final _VoiceAudioFeatures _self;
  final $Res Function(_VoiceAudioFeatures) _then;

  /// Create a copy of VoiceAudioFeatures
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? soundLevels = null,
    Object? timestamps = null,
    Object? startTime = null,
    Object? endTime = null,
    Object? partialResultCount = null,
    Object? wordCount = null,
  }) {
    return _then(
      _VoiceAudioFeatures(
        soundLevels: null == soundLevels
            ? _self._soundLevels
            : soundLevels // ignore: cast_nullable_to_non_nullable
                  as List<double>,
        timestamps: null == timestamps
            ? _self._timestamps
            : timestamps // ignore: cast_nullable_to_non_nullable
                  as List<DateTime>,
        startTime: null == startTime
            ? _self.startTime
            : startTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        endTime: null == endTime
            ? _self.endTime
            : endTime // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        partialResultCount: null == partialResultCount
            ? _self.partialResultCount
            : partialResultCount // ignore: cast_nullable_to_non_nullable
                  as int,
        wordCount: null == wordCount
            ? _self.wordCount
            : wordCount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
