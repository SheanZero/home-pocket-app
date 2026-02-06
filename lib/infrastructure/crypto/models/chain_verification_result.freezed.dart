// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'chain_verification_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ChainVerificationResult {
  bool get isValid;
  int get totalTransactions;
  List<String> get tamperedTransactionIds;

  /// Create a copy of ChainVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ChainVerificationResultCopyWith<ChainVerificationResult> get copyWith =>
      _$ChainVerificationResultCopyWithImpl<ChainVerificationResult>(
        this as ChainVerificationResult,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ChainVerificationResult &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.totalTransactions, totalTransactions) ||
                other.totalTransactions == totalTransactions) &&
            const DeepCollectionEquality().equals(
              other.tamperedTransactionIds,
              tamperedTransactionIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isValid,
    totalTransactions,
    const DeepCollectionEquality().hash(tamperedTransactionIds),
  );

  @override
  String toString() {
    return 'ChainVerificationResult(isValid: $isValid, totalTransactions: $totalTransactions, tamperedTransactionIds: $tamperedTransactionIds)';
  }
}

/// @nodoc
abstract mixin class $ChainVerificationResultCopyWith<$Res> {
  factory $ChainVerificationResultCopyWith(
    ChainVerificationResult value,
    $Res Function(ChainVerificationResult) _then,
  ) = _$ChainVerificationResultCopyWithImpl;
  @useResult
  $Res call({
    bool isValid,
    int totalTransactions,
    List<String> tamperedTransactionIds,
  });
}

/// @nodoc
class _$ChainVerificationResultCopyWithImpl<$Res>
    implements $ChainVerificationResultCopyWith<$Res> {
  _$ChainVerificationResultCopyWithImpl(this._self, this._then);

  final ChainVerificationResult _self;
  final $Res Function(ChainVerificationResult) _then;

  /// Create a copy of ChainVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isValid = null,
    Object? totalTransactions = null,
    Object? tamperedTransactionIds = null,
  }) {
    return _then(
      _self.copyWith(
        isValid: null == isValid
            ? _self.isValid
            : isValid // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalTransactions: null == totalTransactions
            ? _self.totalTransactions
            : totalTransactions // ignore: cast_nullable_to_non_nullable
                  as int,
        tamperedTransactionIds: null == tamperedTransactionIds
            ? _self.tamperedTransactionIds
            : tamperedTransactionIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ChainVerificationResult].
extension ChainVerificationResultPatterns on ChainVerificationResult {
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
    TResult Function(_ChainVerificationResult value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ChainVerificationResult() when $default != null:
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
    TResult Function(_ChainVerificationResult value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChainVerificationResult():
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
    TResult? Function(_ChainVerificationResult value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChainVerificationResult() when $default != null:
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
      bool isValid,
      int totalTransactions,
      List<String> tamperedTransactionIds,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ChainVerificationResult() when $default != null:
        return $default(
          _that.isValid,
          _that.totalTransactions,
          _that.tamperedTransactionIds,
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
      bool isValid,
      int totalTransactions,
      List<String> tamperedTransactionIds,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChainVerificationResult():
        return $default(
          _that.isValid,
          _that.totalTransactions,
          _that.tamperedTransactionIds,
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
      bool isValid,
      int totalTransactions,
      List<String> tamperedTransactionIds,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ChainVerificationResult() when $default != null:
        return $default(
          _that.isValid,
          _that.totalTransactions,
          _that.tamperedTransactionIds,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ChainVerificationResult implements ChainVerificationResult {
  const _ChainVerificationResult({
    required this.isValid,
    required this.totalTransactions,
    required final List<String> tamperedTransactionIds,
  }) : _tamperedTransactionIds = tamperedTransactionIds;

  @override
  final bool isValid;
  @override
  final int totalTransactions;
  final List<String> _tamperedTransactionIds;
  @override
  List<String> get tamperedTransactionIds {
    if (_tamperedTransactionIds is EqualUnmodifiableListView)
      return _tamperedTransactionIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tamperedTransactionIds);
  }

  /// Create a copy of ChainVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ChainVerificationResultCopyWith<_ChainVerificationResult> get copyWith =>
      __$ChainVerificationResultCopyWithImpl<_ChainVerificationResult>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ChainVerificationResult &&
            (identical(other.isValid, isValid) || other.isValid == isValid) &&
            (identical(other.totalTransactions, totalTransactions) ||
                other.totalTransactions == totalTransactions) &&
            const DeepCollectionEquality().equals(
              other._tamperedTransactionIds,
              _tamperedTransactionIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isValid,
    totalTransactions,
    const DeepCollectionEquality().hash(_tamperedTransactionIds),
  );

  @override
  String toString() {
    return 'ChainVerificationResult(isValid: $isValid, totalTransactions: $totalTransactions, tamperedTransactionIds: $tamperedTransactionIds)';
  }
}

/// @nodoc
abstract mixin class _$ChainVerificationResultCopyWith<$Res>
    implements $ChainVerificationResultCopyWith<$Res> {
  factory _$ChainVerificationResultCopyWith(
    _ChainVerificationResult value,
    $Res Function(_ChainVerificationResult) _then,
  ) = __$ChainVerificationResultCopyWithImpl;
  @override
  @useResult
  $Res call({
    bool isValid,
    int totalTransactions,
    List<String> tamperedTransactionIds,
  });
}

/// @nodoc
class __$ChainVerificationResultCopyWithImpl<$Res>
    implements _$ChainVerificationResultCopyWith<$Res> {
  __$ChainVerificationResultCopyWithImpl(this._self, this._then);

  final _ChainVerificationResult _self;
  final $Res Function(_ChainVerificationResult) _then;

  /// Create a copy of ChainVerificationResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isValid = null,
    Object? totalTransactions = null,
    Object? tamperedTransactionIds = null,
  }) {
    return _then(
      _ChainVerificationResult(
        isValid: null == isValid
            ? _self.isValid
            : isValid // ignore: cast_nullable_to_non_nullable
                  as bool,
        totalTransactions: null == totalTransactions
            ? _self.totalTransactions
            : totalTransactions // ignore: cast_nullable_to_non_nullable
                  as int,
        tamperedTransactionIds: null == tamperedTransactionIds
            ? _self._tamperedTransactionIds
            : tamperedTransactionIds // ignore: cast_nullable_to_non_nullable
                  as List<String>,
      ),
    );
  }
}
