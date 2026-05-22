// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ocr_parse_draft.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$OcrParseDraft {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is OcrParseDraft);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'OcrParseDraft()';
  }
}

/// @nodoc
class $OcrParseDraftCopyWith<$Res> {
  $OcrParseDraftCopyWith(OcrParseDraft _, $Res Function(OcrParseDraft) __);
}

/// Adds pattern-matching-related methods to [OcrParseDraft].
extension OcrParseDraftPatterns on OcrParseDraft {
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
    TResult Function(_OcrParseDraft value)? $default, {
    TResult Function(_Empty value)? empty,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OcrParseDraft() when $default != null:
        return $default(_that);
      case _Empty() when empty != null:
        return empty(_that);
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
    TResult Function(_OcrParseDraft value) $default, {
    required TResult Function(_Empty value) empty,
  }) {
    final _that = this;
    switch (_that) {
      case _OcrParseDraft():
        return $default(_that);
      case _Empty():
        return empty(_that);
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
    TResult? Function(_OcrParseDraft value)? $default, {
    TResult? Function(_Empty value)? empty,
  }) {
    final _that = this;
    switch (_that) {
      case _OcrParseDraft() when $default != null:
        return $default(_that);
      case _Empty() when empty != null:
        return empty(_that);
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
      int? amount,
      String? merchant,
      DateTime? date,
      String? rawOcrText,
      String? imagePath,
    )?
    $default, {
    TResult Function()? empty,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _OcrParseDraft() when $default != null:
        return $default(
          _that.amount,
          _that.merchant,
          _that.date,
          _that.rawOcrText,
          _that.imagePath,
        );
      case _Empty() when empty != null:
        return empty();
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
      int? amount,
      String? merchant,
      DateTime? date,
      String? rawOcrText,
      String? imagePath,
    )
    $default, {
    required TResult Function() empty,
  }) {
    final _that = this;
    switch (_that) {
      case _OcrParseDraft():
        return $default(
          _that.amount,
          _that.merchant,
          _that.date,
          _that.rawOcrText,
          _that.imagePath,
        );
      case _Empty():
        return empty();
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
      int? amount,
      String? merchant,
      DateTime? date,
      String? rawOcrText,
      String? imagePath,
    )?
    $default, {
    TResult? Function()? empty,
  }) {
    final _that = this;
    switch (_that) {
      case _OcrParseDraft() when $default != null:
        return $default(
          _that.amount,
          _that.merchant,
          _that.date,
          _that.rawOcrText,
          _that.imagePath,
        );
      case _Empty() when empty != null:
        return empty();
      case _:
        return null;
    }
  }
}

/// @nodoc

class _OcrParseDraft extends OcrParseDraft {
  const _OcrParseDraft({
    this.amount,
    this.merchant,
    this.date,
    this.rawOcrText,
    this.imagePath,
  }) : super._();

  final int? amount;
  final String? merchant;
  final DateTime? date;
  final String? rawOcrText;
  final String? imagePath;

  /// Create a copy of OcrParseDraft
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$OcrParseDraftCopyWith<_OcrParseDraft> get copyWith =>
      __$OcrParseDraftCopyWithImpl<_OcrParseDraft>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _OcrParseDraft &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.rawOcrText, rawOcrText) ||
                other.rawOcrText == rawOcrText) &&
            (identical(other.imagePath, imagePath) ||
                other.imagePath == imagePath));
  }

  @override
  int get hashCode =>
      Object.hash(runtimeType, amount, merchant, date, rawOcrText, imagePath);

  @override
  String toString() {
    return 'OcrParseDraft(amount: $amount, merchant: $merchant, date: $date, rawOcrText: $rawOcrText, imagePath: $imagePath)';
  }
}

/// @nodoc
abstract mixin class _$OcrParseDraftCopyWith<$Res>
    implements $OcrParseDraftCopyWith<$Res> {
  factory _$OcrParseDraftCopyWith(
    _OcrParseDraft value,
    $Res Function(_OcrParseDraft) _then,
  ) = __$OcrParseDraftCopyWithImpl;
  @useResult
  $Res call({
    int? amount,
    String? merchant,
    DateTime? date,
    String? rawOcrText,
    String? imagePath,
  });
}

/// @nodoc
class __$OcrParseDraftCopyWithImpl<$Res>
    implements _$OcrParseDraftCopyWith<$Res> {
  __$OcrParseDraftCopyWithImpl(this._self, this._then);

  final _OcrParseDraft _self;
  final $Res Function(_OcrParseDraft) _then;

  /// Create a copy of OcrParseDraft
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? amount = freezed,
    Object? merchant = freezed,
    Object? date = freezed,
    Object? rawOcrText = freezed,
    Object? imagePath = freezed,
  }) {
    return _then(
      _OcrParseDraft(
        amount: freezed == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int?,
        merchant: freezed == merchant
            ? _self.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        date: freezed == date
            ? _self.date
            : date // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        rawOcrText: freezed == rawOcrText
            ? _self.rawOcrText
            : rawOcrText // ignore: cast_nullable_to_non_nullable
                  as String?,
        imagePath: freezed == imagePath
            ? _self.imagePath
            : imagePath // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }
}

/// @nodoc

class _Empty extends OcrParseDraft {
  const _Empty() : super._();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _Empty);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'OcrParseDraft.empty()';
  }
}
