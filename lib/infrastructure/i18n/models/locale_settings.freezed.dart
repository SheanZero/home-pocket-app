// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'locale_settings.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$LocaleSettings {
  Locale get locale;
  bool get isSystemDefault;

  /// Create a copy of LocaleSettings
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $LocaleSettingsCopyWith<LocaleSettings> get copyWith =>
      _$LocaleSettingsCopyWithImpl<LocaleSettings>(
        this as LocaleSettings,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is LocaleSettings &&
            (identical(other.locale, locale) || other.locale == locale) &&
            (identical(other.isSystemDefault, isSystemDefault) ||
                other.isSystemDefault == isSystemDefault));
  }

  @override
  int get hashCode => Object.hash(runtimeType, locale, isSystemDefault);

  @override
  String toString() {
    return 'LocaleSettings(locale: $locale, isSystemDefault: $isSystemDefault)';
  }
}

/// @nodoc
abstract mixin class $LocaleSettingsCopyWith<$Res> {
  factory $LocaleSettingsCopyWith(
    LocaleSettings value,
    $Res Function(LocaleSettings) _then,
  ) = _$LocaleSettingsCopyWithImpl;
  @useResult
  $Res call({Locale locale, bool isSystemDefault});
}

/// @nodoc
class _$LocaleSettingsCopyWithImpl<$Res>
    implements $LocaleSettingsCopyWith<$Res> {
  _$LocaleSettingsCopyWithImpl(this._self, this._then);

  final LocaleSettings _self;
  final $Res Function(LocaleSettings) _then;

  /// Create a copy of LocaleSettings
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? locale = null, Object? isSystemDefault = null}) {
    return _then(
      _self.copyWith(
        locale: null == locale
            ? _self.locale
            : locale // ignore: cast_nullable_to_non_nullable
                  as Locale,
        isSystemDefault: null == isSystemDefault
            ? _self.isSystemDefault
            : isSystemDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [LocaleSettings].
extension LocaleSettingsPatterns on LocaleSettings {
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
    TResult Function(_LocaleSettings value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LocaleSettings() when $default != null:
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
    TResult Function(_LocaleSettings value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleSettings():
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
    TResult? Function(_LocaleSettings value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleSettings() when $default != null:
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
    TResult Function(Locale locale, bool isSystemDefault)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _LocaleSettings() when $default != null:
        return $default(_that.locale, _that.isSystemDefault);
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
    TResult Function(Locale locale, bool isSystemDefault) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleSettings():
        return $default(_that.locale, _that.isSystemDefault);
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
    TResult? Function(Locale locale, bool isSystemDefault)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _LocaleSettings() when $default != null:
        return $default(_that.locale, _that.isSystemDefault);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _LocaleSettings implements LocaleSettings {
  const _LocaleSettings({required this.locale, required this.isSystemDefault});

  @override
  final Locale locale;
  @override
  final bool isSystemDefault;

  /// Create a copy of LocaleSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$LocaleSettingsCopyWith<_LocaleSettings> get copyWith =>
      __$LocaleSettingsCopyWithImpl<_LocaleSettings>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _LocaleSettings &&
            (identical(other.locale, locale) || other.locale == locale) &&
            (identical(other.isSystemDefault, isSystemDefault) ||
                other.isSystemDefault == isSystemDefault));
  }

  @override
  int get hashCode => Object.hash(runtimeType, locale, isSystemDefault);

  @override
  String toString() {
    return 'LocaleSettings(locale: $locale, isSystemDefault: $isSystemDefault)';
  }
}

/// @nodoc
abstract mixin class _$LocaleSettingsCopyWith<$Res>
    implements $LocaleSettingsCopyWith<$Res> {
  factory _$LocaleSettingsCopyWith(
    _LocaleSettings value,
    $Res Function(_LocaleSettings) _then,
  ) = __$LocaleSettingsCopyWithImpl;
  @override
  @useResult
  $Res call({Locale locale, bool isSystemDefault});
}

/// @nodoc
class __$LocaleSettingsCopyWithImpl<$Res>
    implements _$LocaleSettingsCopyWith<$Res> {
  __$LocaleSettingsCopyWithImpl(this._self, this._then);

  final _LocaleSettings _self;
  final $Res Function(_LocaleSettings) _then;

  /// Create a copy of LocaleSettings
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? locale = null, Object? isSystemDefault = null}) {
    return _then(
      _LocaleSettings(
        locale: null == locale
            ? _self.locale
            : locale // ignore: cast_nullable_to_non_nullable
                  as Locale,
        isSystemDefault: null == isSystemDefault
            ? _self.isSystemDefault
            : isSystemDefault // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
