// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'init_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$InitResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is InitResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'InitResult()';
  }
}

/// @nodoc
class $InitResultCopyWith<$Res> {
  $InitResultCopyWith(InitResult _, $Res Function(InitResult) __);
}

/// Adds pattern-matching-related methods to [InitResult].
extension InitResultPatterns on InitResult {
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
  TResult maybeMap<TResult extends Object?>({
    TResult Function(InitSuccess value)? success,
    TResult Function(InitFailure value)? failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case InitSuccess() when success != null:
        return success(_that);
      case InitFailure() when failure != null:
        return failure(_that);
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
  TResult map<TResult extends Object?>({
    required TResult Function(InitSuccess value) success,
    required TResult Function(InitFailure value) failure,
  }) {
    final _that = this;
    switch (_that) {
      case InitSuccess():
        return success(_that);
      case InitFailure():
        return failure(_that);
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
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(InitSuccess value)? success,
    TResult? Function(InitFailure value)? failure,
  }) {
    final _that = this;
    switch (_that) {
      case InitSuccess() when success != null:
        return success(_that);
      case InitFailure() when failure != null:
        return failure(_that);
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
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(ProviderContainer container)? success,
    TResult Function(
      InitFailureType type,
      Object error,
      StackTrace? stackTrace,
    )?
    failure,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case InitSuccess() when success != null:
        return success(_that.container);
      case InitFailure() when failure != null:
        return failure(_that.type, _that.error, _that.stackTrace);
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
  TResult when<TResult extends Object?>({
    required TResult Function(ProviderContainer container) success,
    required TResult Function(
      InitFailureType type,
      Object error,
      StackTrace? stackTrace,
    )
    failure,
  }) {
    final _that = this;
    switch (_that) {
      case InitSuccess():
        return success(_that.container);
      case InitFailure():
        return failure(_that.type, _that.error, _that.stackTrace);
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
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(ProviderContainer container)? success,
    TResult? Function(
      InitFailureType type,
      Object error,
      StackTrace? stackTrace,
    )?
    failure,
  }) {
    final _that = this;
    switch (_that) {
      case InitSuccess() when success != null:
        return success(_that.container);
      case InitFailure() when failure != null:
        return failure(_that.type, _that.error, _that.stackTrace);
      case _:
        return null;
    }
  }
}

/// @nodoc

class InitSuccess implements InitResult {
  const InitSuccess({required this.container});

  final ProviderContainer container;

  /// Create a copy of InitResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InitSuccessCopyWith<InitSuccess> get copyWith =>
      _$InitSuccessCopyWithImpl<InitSuccess>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InitSuccess &&
            (identical(other.container, container) ||
                other.container == container));
  }

  @override
  int get hashCode => Object.hash(runtimeType, container);

  @override
  String toString() {
    return 'InitResult.success(container: $container)';
  }
}

/// @nodoc
abstract mixin class $InitSuccessCopyWith<$Res>
    implements $InitResultCopyWith<$Res> {
  factory $InitSuccessCopyWith(
    InitSuccess value,
    $Res Function(InitSuccess) _then,
  ) = _$InitSuccessCopyWithImpl;
  @useResult
  $Res call({ProviderContainer container});
}

/// @nodoc
class _$InitSuccessCopyWithImpl<$Res> implements $InitSuccessCopyWith<$Res> {
  _$InitSuccessCopyWithImpl(this._self, this._then);

  final InitSuccess _self;
  final $Res Function(InitSuccess) _then;

  /// Create a copy of InitResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? container = null}) {
    return _then(
      InitSuccess(
        container: null == container
            ? _self.container
            : container // ignore: cast_nullable_to_non_nullable
                  as ProviderContainer,
      ),
    );
  }
}

/// @nodoc

class InitFailure implements InitResult {
  const InitFailure({required this.type, required this.error, this.stackTrace});

  final InitFailureType type;
  final Object error;
  final StackTrace? stackTrace;

  /// Create a copy of InitResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $InitFailureCopyWith<InitFailure> get copyWith =>
      _$InitFailureCopyWithImpl<InitFailure>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is InitFailure &&
            (identical(other.type, type) || other.type == type) &&
            const DeepCollectionEquality().equals(other.error, error) &&
            (identical(other.stackTrace, stackTrace) ||
                other.stackTrace == stackTrace));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    type,
    const DeepCollectionEquality().hash(error),
    stackTrace,
  );

  @override
  String toString() {
    return 'InitResult.failure(type: $type, error: $error, stackTrace: $stackTrace)';
  }
}

/// @nodoc
abstract mixin class $InitFailureCopyWith<$Res>
    implements $InitResultCopyWith<$Res> {
  factory $InitFailureCopyWith(
    InitFailure value,
    $Res Function(InitFailure) _then,
  ) = _$InitFailureCopyWithImpl;
  @useResult
  $Res call({InitFailureType type, Object error, StackTrace? stackTrace});
}

/// @nodoc
class _$InitFailureCopyWithImpl<$Res> implements $InitFailureCopyWith<$Res> {
  _$InitFailureCopyWithImpl(this._self, this._then);

  final InitFailure _self;
  final $Res Function(InitFailure) _then;

  /// Create a copy of InitResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? type = null,
    Object? error = null,
    Object? stackTrace = freezed,
  }) {
    return _then(
      InitFailure(
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as InitFailureType,
        error: null == error ? _self.error : error,
        stackTrace: freezed == stackTrace
            ? _self.stackTrace
            : stackTrace // ignore: cast_nullable_to_non_nullable
                  as StackTrace?,
      ),
    );
  }
}
