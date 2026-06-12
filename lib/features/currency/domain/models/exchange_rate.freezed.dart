// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'exchange_rate.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ExchangeRate {
  /// ISO 4217 currency code (e.g. "USD", "CNY", "EUR").
  String get currency;

  /// The date this rate applies to (UTC midnight).
  DateTime get rateDate;

  /// Exchange rate as a full-precision string (e.g. "157.3421" JPY per 1 unit).
  ///
  /// Stored and transmitted as a string literal to avoid double precision loss
  /// (ADR-020). Use [double.parse] only inside [convertToJpy].
  String get rate;

  /// UTC timestamp when this rate was fetched from the external API.
  DateTime get fetchedAt;

  /// Source identifier for the rate provider.
  ///
  /// Examples: "frankfurter", "fawazahmed0", "manual".
  String get source;

  /// The actual date the API reported for this rate.
  ///
  /// Non-null when the target date was a weekend or holiday and the API
  /// returned the nearest available rate from a different date.
  /// Null when [rateDate] is the actual date.
  DateTime? get actualRateDate;

  /// Create a copy of ExchangeRate
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ExchangeRateCopyWith<ExchangeRate> get copyWith =>
      _$ExchangeRateCopyWithImpl<ExchangeRate>(
        this as ExchangeRate,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ExchangeRate &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.rateDate, rateDate) ||
                other.rateDate == rateDate) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.actualRateDate, actualRateDate) ||
                other.actualRateDate == actualRateDate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currency,
    rateDate,
    rate,
    fetchedAt,
    source,
    actualRateDate,
  );

  @override
  String toString() {
    return 'ExchangeRate(currency: $currency, rateDate: $rateDate, rate: $rate, fetchedAt: $fetchedAt, source: $source, actualRateDate: $actualRateDate)';
  }
}

/// @nodoc
abstract mixin class $ExchangeRateCopyWith<$Res> {
  factory $ExchangeRateCopyWith(
    ExchangeRate value,
    $Res Function(ExchangeRate) _then,
  ) = _$ExchangeRateCopyWithImpl;
  @useResult
  $Res call({
    String currency,
    DateTime rateDate,
    String rate,
    DateTime fetchedAt,
    String source,
    DateTime? actualRateDate,
  });
}

/// @nodoc
class _$ExchangeRateCopyWithImpl<$Res> implements $ExchangeRateCopyWith<$Res> {
  _$ExchangeRateCopyWithImpl(this._self, this._then);

  final ExchangeRate _self;
  final $Res Function(ExchangeRate) _then;

  /// Create a copy of ExchangeRate
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? currency = null,
    Object? rateDate = null,
    Object? rate = null,
    Object? fetchedAt = null,
    Object? source = null,
    Object? actualRateDate = freezed,
  }) {
    return _then(
      _self.copyWith(
        currency: null == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        rateDate: null == rateDate
            ? _self.rateDate
            : rateDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        rate: null == rate
            ? _self.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as String,
        fetchedAt: null == fetchedAt
            ? _self.fetchedAt
            : fetchedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        actualRateDate: freezed == actualRateDate
            ? _self.actualRateDate
            : actualRateDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ExchangeRate].
extension ExchangeRatePatterns on ExchangeRate {
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
    TResult Function(_ExchangeRate value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExchangeRate() when $default != null:
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
    TResult Function(_ExchangeRate value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExchangeRate():
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
    TResult? Function(_ExchangeRate value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExchangeRate() when $default != null:
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
      String currency,
      DateTime rateDate,
      String rate,
      DateTime fetchedAt,
      String source,
      DateTime? actualRateDate,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ExchangeRate() when $default != null:
        return $default(
          _that.currency,
          _that.rateDate,
          _that.rate,
          _that.fetchedAt,
          _that.source,
          _that.actualRateDate,
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
      String currency,
      DateTime rateDate,
      String rate,
      DateTime fetchedAt,
      String source,
      DateTime? actualRateDate,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExchangeRate():
        return $default(
          _that.currency,
          _that.rateDate,
          _that.rate,
          _that.fetchedAt,
          _that.source,
          _that.actualRateDate,
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
      String currency,
      DateTime rateDate,
      String rate,
      DateTime fetchedAt,
      String source,
      DateTime? actualRateDate,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ExchangeRate() when $default != null:
        return $default(
          _that.currency,
          _that.rateDate,
          _that.rate,
          _that.fetchedAt,
          _that.source,
          _that.actualRateDate,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ExchangeRate extends ExchangeRate {
  const _ExchangeRate({
    required this.currency,
    required this.rateDate,
    required this.rate,
    required this.fetchedAt,
    required this.source,
    this.actualRateDate,
  }) : super._();

  /// ISO 4217 currency code (e.g. "USD", "CNY", "EUR").
  @override
  final String currency;

  /// The date this rate applies to (UTC midnight).
  @override
  final DateTime rateDate;

  /// Exchange rate as a full-precision string (e.g. "157.3421" JPY per 1 unit).
  ///
  /// Stored and transmitted as a string literal to avoid double precision loss
  /// (ADR-020). Use [double.parse] only inside [convertToJpy].
  @override
  final String rate;

  /// UTC timestamp when this rate was fetched from the external API.
  @override
  final DateTime fetchedAt;

  /// Source identifier for the rate provider.
  ///
  /// Examples: "frankfurter", "fawazahmed0", "manual".
  @override
  final String source;

  /// The actual date the API reported for this rate.
  ///
  /// Non-null when the target date was a weekend or holiday and the API
  /// returned the nearest available rate from a different date.
  /// Null when [rateDate] is the actual date.
  @override
  final DateTime? actualRateDate;

  /// Create a copy of ExchangeRate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ExchangeRateCopyWith<_ExchangeRate> get copyWith =>
      __$ExchangeRateCopyWithImpl<_ExchangeRate>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ExchangeRate &&
            (identical(other.currency, currency) ||
                other.currency == currency) &&
            (identical(other.rateDate, rateDate) ||
                other.rateDate == rateDate) &&
            (identical(other.rate, rate) || other.rate == rate) &&
            (identical(other.fetchedAt, fetchedAt) ||
                other.fetchedAt == fetchedAt) &&
            (identical(other.source, source) || other.source == source) &&
            (identical(other.actualRateDate, actualRateDate) ||
                other.actualRateDate == actualRateDate));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    currency,
    rateDate,
    rate,
    fetchedAt,
    source,
    actualRateDate,
  );

  @override
  String toString() {
    return 'ExchangeRate(currency: $currency, rateDate: $rateDate, rate: $rate, fetchedAt: $fetchedAt, source: $source, actualRateDate: $actualRateDate)';
  }
}

/// @nodoc
abstract mixin class _$ExchangeRateCopyWith<$Res>
    implements $ExchangeRateCopyWith<$Res> {
  factory _$ExchangeRateCopyWith(
    _ExchangeRate value,
    $Res Function(_ExchangeRate) _then,
  ) = __$ExchangeRateCopyWithImpl;
  @override
  @useResult
  $Res call({
    String currency,
    DateTime rateDate,
    String rate,
    DateTime fetchedAt,
    String source,
    DateTime? actualRateDate,
  });
}

/// @nodoc
class __$ExchangeRateCopyWithImpl<$Res>
    implements _$ExchangeRateCopyWith<$Res> {
  __$ExchangeRateCopyWithImpl(this._self, this._then);

  final _ExchangeRate _self;
  final $Res Function(_ExchangeRate) _then;

  /// Create a copy of ExchangeRate
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? currency = null,
    Object? rateDate = null,
    Object? rate = null,
    Object? fetchedAt = null,
    Object? source = null,
    Object? actualRateDate = freezed,
  }) {
    return _then(
      _ExchangeRate(
        currency: null == currency
            ? _self.currency
            : currency // ignore: cast_nullable_to_non_nullable
                  as String,
        rateDate: null == rateDate
            ? _self.rateDate
            : rateDate // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        rate: null == rate
            ? _self.rate
            : rate // ignore: cast_nullable_to_non_nullable
                  as String,
        fetchedAt: null == fetchedAt
            ? _self.fetchedAt
            : fetchedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        source: null == source
            ? _self.source
            : source // ignore: cast_nullable_to_non_nullable
                  as String,
        actualRateDate: freezed == actualRateDate
            ? _self.actualRateDate
            : actualRateDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}
