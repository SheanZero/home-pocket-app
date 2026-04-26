// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'ledger_row_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LedgerRowData {
  String get tagText;
  Color get tagBgColor;
  Color get tagTextColor;
  String get title;
  Color get titleColor;
  String get subtitle;
  String get formattedAmount;
  Color get amountColor;
  Color get chevronColor;
  Color? get borderColor;

  /// Create a copy of LedgerRowData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LedgerRowDataCopyWith<LedgerRowData> get copyWith =>
      _$LedgerRowDataCopyWithImpl<LedgerRowData>(
        this as LedgerRowData,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LedgerRowData &&
            (identical(other.tagText, tagText) || other.tagText == tagText) &&
            (identical(other.tagBgColor, tagBgColor) ||
                other.tagBgColor == tagBgColor) &&
            (identical(other.tagTextColor, tagTextColor) ||
                other.tagTextColor == tagTextColor) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.titleColor, titleColor) ||
                other.titleColor == titleColor) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.formattedAmount, formattedAmount) ||
                other.formattedAmount == formattedAmount) &&
            (identical(other.amountColor, amountColor) ||
                other.amountColor == amountColor) &&
            (identical(other.chevronColor, chevronColor) ||
                other.chevronColor == chevronColor) &&
            (identical(other.borderColor, borderColor) ||
                other.borderColor == borderColor));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    tagText,
    tagBgColor,
    tagTextColor,
    title,
    titleColor,
    subtitle,
    formattedAmount,
    amountColor,
    chevronColor,
    borderColor,
  );

  @override
  String toString() {
    return 'LedgerRowData(tagText: $tagText, tagBgColor: $tagBgColor, tagTextColor: $tagTextColor, title: $title, titleColor: $titleColor, subtitle: $subtitle, formattedAmount: $formattedAmount, amountColor: $amountColor, chevronColor: $chevronColor, borderColor: $borderColor)';
  }
}

/// @nodoc
abstract mixin class $LedgerRowDataCopyWith<$Res> {
  factory $LedgerRowDataCopyWith(
    LedgerRowData value,
    $Res Function(LedgerRowData) _then,
  ) = _$LedgerRowDataCopyWithImpl;
  @useResult
  $Res call({
    String tagText,
    Color tagBgColor,
    Color tagTextColor,
    String title,
    Color titleColor,
    String subtitle,
    String formattedAmount,
    Color amountColor,
    Color chevronColor,
    Color? borderColor,
  });
}

/// @nodoc
class _$LedgerRowDataCopyWithImpl<$Res>
    implements $LedgerRowDataCopyWith<$Res> {
  _$LedgerRowDataCopyWithImpl(this._self, this._then);

  final LedgerRowData _self;
  final $Res Function(LedgerRowData) _then;

  /// Create a copy of LedgerRowData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? tagText = null,
    Object? tagBgColor = null,
    Object? tagTextColor = null,
    Object? title = null,
    Object? titleColor = null,
    Object? subtitle = null,
    Object? formattedAmount = null,
    Object? amountColor = null,
    Object? chevronColor = null,
    Object? borderColor = freezed,
  }) {
    return _then(
      _self.copyWith(
        tagText: null == tagText
            ? _self.tagText
            : tagText // ignore: cast_nullable_to_non_nullable
                  as String,
        tagBgColor: null == tagBgColor
            ? _self.tagBgColor
            : tagBgColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        tagTextColor: null == tagTextColor
            ? _self.tagTextColor
            : tagTextColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        titleColor: null == titleColor
            ? _self.titleColor
            : titleColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        subtitle: null == subtitle
            ? _self.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String,
        formattedAmount: null == formattedAmount
            ? _self.formattedAmount
            : formattedAmount // ignore: cast_nullable_to_non_nullable
                  as String,
        amountColor: null == amountColor
            ? _self.amountColor
            : amountColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        chevronColor: null == chevronColor
            ? _self.chevronColor
            : chevronColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        borderColor: freezed == borderColor
            ? _self.borderColor
            : borderColor // ignore: cast_nullable_to_non_nullable
                  as Color?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LedgerRowData].
extension LedgerRowDataPatterns on LedgerRowData {
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
    TResult Function(_LedgerRowData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LedgerRowData() when $default != null:
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
    TResult Function(_LedgerRowData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LedgerRowData():
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
    TResult? Function(_LedgerRowData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LedgerRowData() when $default != null:
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
      String tagText,
      Color tagBgColor,
      Color tagTextColor,
      String title,
      Color titleColor,
      String subtitle,
      String formattedAmount,
      Color amountColor,
      Color chevronColor,
      Color? borderColor,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LedgerRowData() when $default != null:
        return $default(
          _that.tagText,
          _that.tagBgColor,
          _that.tagTextColor,
          _that.title,
          _that.titleColor,
          _that.subtitle,
          _that.formattedAmount,
          _that.amountColor,
          _that.chevronColor,
          _that.borderColor,
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
      String tagText,
      Color tagBgColor,
      Color tagTextColor,
      String title,
      Color titleColor,
      String subtitle,
      String formattedAmount,
      Color amountColor,
      Color chevronColor,
      Color? borderColor,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LedgerRowData():
        return $default(
          _that.tagText,
          _that.tagBgColor,
          _that.tagTextColor,
          _that.title,
          _that.titleColor,
          _that.subtitle,
          _that.formattedAmount,
          _that.amountColor,
          _that.chevronColor,
          _that.borderColor,
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
      String tagText,
      Color tagBgColor,
      Color tagTextColor,
      String title,
      Color titleColor,
      String subtitle,
      String formattedAmount,
      Color amountColor,
      Color chevronColor,
      Color? borderColor,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LedgerRowData() when $default != null:
        return $default(
          _that.tagText,
          _that.tagBgColor,
          _that.tagTextColor,
          _that.title,
          _that.titleColor,
          _that.subtitle,
          _that.formattedAmount,
          _that.amountColor,
          _that.chevronColor,
          _that.borderColor,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LedgerRowData implements LedgerRowData {
  const _LedgerRowData({
    required this.tagText,
    required this.tagBgColor,
    required this.tagTextColor,
    required this.title,
    required this.titleColor,
    required this.subtitle,
    required this.formattedAmount,
    required this.amountColor,
    required this.chevronColor,
    this.borderColor,
  });

  @override
  final String tagText;
  @override
  final Color tagBgColor;
  @override
  final Color tagTextColor;
  @override
  final String title;
  @override
  final Color titleColor;
  @override
  final String subtitle;
  @override
  final String formattedAmount;
  @override
  final Color amountColor;
  @override
  final Color chevronColor;
  @override
  final Color? borderColor;

  /// Create a copy of LedgerRowData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LedgerRowDataCopyWith<_LedgerRowData> get copyWith =>
      __$LedgerRowDataCopyWithImpl<_LedgerRowData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LedgerRowData &&
            (identical(other.tagText, tagText) || other.tagText == tagText) &&
            (identical(other.tagBgColor, tagBgColor) ||
                other.tagBgColor == tagBgColor) &&
            (identical(other.tagTextColor, tagTextColor) ||
                other.tagTextColor == tagTextColor) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.titleColor, titleColor) ||
                other.titleColor == titleColor) &&
            (identical(other.subtitle, subtitle) ||
                other.subtitle == subtitle) &&
            (identical(other.formattedAmount, formattedAmount) ||
                other.formattedAmount == formattedAmount) &&
            (identical(other.amountColor, amountColor) ||
                other.amountColor == amountColor) &&
            (identical(other.chevronColor, chevronColor) ||
                other.chevronColor == chevronColor) &&
            (identical(other.borderColor, borderColor) ||
                other.borderColor == borderColor));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    tagText,
    tagBgColor,
    tagTextColor,
    title,
    titleColor,
    subtitle,
    formattedAmount,
    amountColor,
    chevronColor,
    borderColor,
  );

  @override
  String toString() {
    return 'LedgerRowData(tagText: $tagText, tagBgColor: $tagBgColor, tagTextColor: $tagTextColor, title: $title, titleColor: $titleColor, subtitle: $subtitle, formattedAmount: $formattedAmount, amountColor: $amountColor, chevronColor: $chevronColor, borderColor: $borderColor)';
  }
}

/// @nodoc
abstract mixin class _$LedgerRowDataCopyWith<$Res>
    implements $LedgerRowDataCopyWith<$Res> {
  factory _$LedgerRowDataCopyWith(
    _LedgerRowData value,
    $Res Function(_LedgerRowData) _then,
  ) = __$LedgerRowDataCopyWithImpl;
  @override
  @useResult
  $Res call({
    String tagText,
    Color tagBgColor,
    Color tagTextColor,
    String title,
    Color titleColor,
    String subtitle,
    String formattedAmount,
    Color amountColor,
    Color chevronColor,
    Color? borderColor,
  });
}

/// @nodoc
class __$LedgerRowDataCopyWithImpl<$Res>
    implements _$LedgerRowDataCopyWith<$Res> {
  __$LedgerRowDataCopyWithImpl(this._self, this._then);

  final _LedgerRowData _self;
  final $Res Function(_LedgerRowData) _then;

  /// Create a copy of LedgerRowData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? tagText = null,
    Object? tagBgColor = null,
    Object? tagTextColor = null,
    Object? title = null,
    Object? titleColor = null,
    Object? subtitle = null,
    Object? formattedAmount = null,
    Object? amountColor = null,
    Object? chevronColor = null,
    Object? borderColor = freezed,
  }) {
    return _then(
      _LedgerRowData(
        tagText: null == tagText
            ? _self.tagText
            : tagText // ignore: cast_nullable_to_non_nullable
                  as String,
        tagBgColor: null == tagBgColor
            ? _self.tagBgColor
            : tagBgColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        tagTextColor: null == tagTextColor
            ? _self.tagTextColor
            : tagTextColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        title: null == title
            ? _self.title
            : title // ignore: cast_nullable_to_non_nullable
                  as String,
        titleColor: null == titleColor
            ? _self.titleColor
            : titleColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        subtitle: null == subtitle
            ? _self.subtitle
            : subtitle // ignore: cast_nullable_to_non_nullable
                  as String,
        formattedAmount: null == formattedAmount
            ? _self.formattedAmount
            : formattedAmount // ignore: cast_nullable_to_non_nullable
                  as String,
        amountColor: null == amountColor
            ? _self.amountColor
            : amountColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        chevronColor: null == chevronColor
            ? _self.chevronColor
            : chevronColor // ignore: cast_nullable_to_non_nullable
                  as Color,
        borderColor: freezed == borderColor
            ? _self.borderColor
            : borderColor // ignore: cast_nullable_to_non_nullable
                  as Color?,
      ),
    );
  }
}
