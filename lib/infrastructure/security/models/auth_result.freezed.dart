// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'auth_result.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$AuthResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthResult()';
  }
}

/// @nodoc
class $AuthResultCopyWith<$Res> {
  $AuthResultCopyWith(AuthResult _, $Res Function(AuthResult) __);
}

/// Adds pattern-matching-related methods to [AuthResult].
extension AuthResultPatterns on AuthResult {
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
    TResult Function(AuthResultSuccess value)? success,
    TResult Function(AuthResultFailed value)? failed,
    TResult Function(AuthResultFallbackToPIN value)? fallbackToPIN,
    TResult Function(AuthResultTooManyAttempts value)? tooManyAttempts,
    TResult Function(AuthResultLockedOut value)? lockedOut,
    TResult Function(AuthResultError value)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthResultSuccess() when success != null:
        return success(_that);
      case AuthResultFailed() when failed != null:
        return failed(_that);
      case AuthResultFallbackToPIN() when fallbackToPIN != null:
        return fallbackToPIN(_that);
      case AuthResultTooManyAttempts() when tooManyAttempts != null:
        return tooManyAttempts(_that);
      case AuthResultLockedOut() when lockedOut != null:
        return lockedOut(_that);
      case AuthResultError() when error != null:
        return error(_that);
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
    required TResult Function(AuthResultSuccess value) success,
    required TResult Function(AuthResultFailed value) failed,
    required TResult Function(AuthResultFallbackToPIN value) fallbackToPIN,
    required TResult Function(AuthResultTooManyAttempts value) tooManyAttempts,
    required TResult Function(AuthResultLockedOut value) lockedOut,
    required TResult Function(AuthResultError value) error,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResultSuccess():
        return success(_that);
      case AuthResultFailed():
        return failed(_that);
      case AuthResultFallbackToPIN():
        return fallbackToPIN(_that);
      case AuthResultTooManyAttempts():
        return tooManyAttempts(_that);
      case AuthResultLockedOut():
        return lockedOut(_that);
      case AuthResultError():
        return error(_that);
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
    TResult? Function(AuthResultSuccess value)? success,
    TResult? Function(AuthResultFailed value)? failed,
    TResult? Function(AuthResultFallbackToPIN value)? fallbackToPIN,
    TResult? Function(AuthResultTooManyAttempts value)? tooManyAttempts,
    TResult? Function(AuthResultLockedOut value)? lockedOut,
    TResult? Function(AuthResultError value)? error,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResultSuccess() when success != null:
        return success(_that);
      case AuthResultFailed() when failed != null:
        return failed(_that);
      case AuthResultFallbackToPIN() when fallbackToPIN != null:
        return fallbackToPIN(_that);
      case AuthResultTooManyAttempts() when tooManyAttempts != null:
        return tooManyAttempts(_that);
      case AuthResultLockedOut() when lockedOut != null:
        return lockedOut(_that);
      case AuthResultError() when error != null:
        return error(_that);
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
    TResult Function()? success,
    TResult Function(int failedAttempts)? failed,
    TResult Function()? fallbackToPIN,
    TResult Function()? tooManyAttempts,
    TResult Function()? lockedOut,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case AuthResultSuccess() when success != null:
        return success();
      case AuthResultFailed() when failed != null:
        return failed(_that.failedAttempts);
      case AuthResultFallbackToPIN() when fallbackToPIN != null:
        return fallbackToPIN();
      case AuthResultTooManyAttempts() when tooManyAttempts != null:
        return tooManyAttempts();
      case AuthResultLockedOut() when lockedOut != null:
        return lockedOut();
      case AuthResultError() when error != null:
        return error(_that.message);
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
    required TResult Function() success,
    required TResult Function(int failedAttempts) failed,
    required TResult Function() fallbackToPIN,
    required TResult Function() tooManyAttempts,
    required TResult Function() lockedOut,
    required TResult Function(String message) error,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResultSuccess():
        return success();
      case AuthResultFailed():
        return failed(_that.failedAttempts);
      case AuthResultFallbackToPIN():
        return fallbackToPIN();
      case AuthResultTooManyAttempts():
        return tooManyAttempts();
      case AuthResultLockedOut():
        return lockedOut();
      case AuthResultError():
        return error(_that.message);
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
    TResult? Function()? success,
    TResult? Function(int failedAttempts)? failed,
    TResult? Function()? fallbackToPIN,
    TResult? Function()? tooManyAttempts,
    TResult? Function()? lockedOut,
    TResult? Function(String message)? error,
  }) {
    final _that = this;
    switch (_that) {
      case AuthResultSuccess() when success != null:
        return success();
      case AuthResultFailed() when failed != null:
        return failed(_that.failedAttempts);
      case AuthResultFallbackToPIN() when fallbackToPIN != null:
        return fallbackToPIN();
      case AuthResultTooManyAttempts() when tooManyAttempts != null:
        return tooManyAttempts();
      case AuthResultLockedOut() when lockedOut != null:
        return lockedOut();
      case AuthResultError() when error != null:
        return error(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class AuthResultSuccess implements AuthResult {
  const AuthResultSuccess();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthResultSuccess);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthResult.success()';
  }
}

/// @nodoc

class AuthResultFailed implements AuthResult {
  const AuthResultFailed({required this.failedAttempts});

  final int failedAttempts;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthResultFailedCopyWith<AuthResultFailed> get copyWith =>
      _$AuthResultFailedCopyWithImpl<AuthResultFailed>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthResultFailed &&
            (identical(other.failedAttempts, failedAttempts) ||
                other.failedAttempts == failedAttempts));
  }

  @override
  int get hashCode => Object.hash(runtimeType, failedAttempts);

  @override
  String toString() {
    return 'AuthResult.failed(failedAttempts: $failedAttempts)';
  }
}

/// @nodoc
abstract mixin class $AuthResultFailedCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory $AuthResultFailedCopyWith(
    AuthResultFailed value,
    $Res Function(AuthResultFailed) _then,
  ) = _$AuthResultFailedCopyWithImpl;
  @useResult
  $Res call({int failedAttempts});
}

/// @nodoc
class _$AuthResultFailedCopyWithImpl<$Res>
    implements $AuthResultFailedCopyWith<$Res> {
  _$AuthResultFailedCopyWithImpl(this._self, this._then);

  final AuthResultFailed _self;
  final $Res Function(AuthResultFailed) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? failedAttempts = null}) {
    return _then(
      AuthResultFailed(
        failedAttempts: null == failedAttempts
            ? _self.failedAttempts
            : failedAttempts // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc

class AuthResultFallbackToPIN implements AuthResult {
  const AuthResultFallbackToPIN();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthResultFallbackToPIN);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthResult.fallbackToPIN()';
  }
}

/// @nodoc

class AuthResultTooManyAttempts implements AuthResult {
  const AuthResultTooManyAttempts();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthResultTooManyAttempts);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthResult.tooManyAttempts()';
  }
}

/// @nodoc

class AuthResultLockedOut implements AuthResult {
  const AuthResultLockedOut();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is AuthResultLockedOut);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'AuthResult.lockedOut()';
  }
}

/// @nodoc

class AuthResultError implements AuthResult {
  const AuthResultError({required this.message});

  final String message;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $AuthResultErrorCopyWith<AuthResultError> get copyWith =>
      _$AuthResultErrorCopyWithImpl<AuthResultError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is AuthResultError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'AuthResult.error(message: $message)';
  }
}

/// @nodoc
abstract mixin class $AuthResultErrorCopyWith<$Res>
    implements $AuthResultCopyWith<$Res> {
  factory $AuthResultErrorCopyWith(
    AuthResultError value,
    $Res Function(AuthResultError) _then,
  ) = _$AuthResultErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class _$AuthResultErrorCopyWithImpl<$Res>
    implements $AuthResultErrorCopyWith<$Res> {
  _$AuthResultErrorCopyWithImpl(this._self, this._then);

  final AuthResultError _self;
  final $Res Function(AuthResultError) _then;

  /// Create a copy of AuthResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? message = null}) {
    return _then(
      AuthResultError(
        message: null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
