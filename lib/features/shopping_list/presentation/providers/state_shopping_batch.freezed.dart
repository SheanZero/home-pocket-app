// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'state_shopping_batch.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BatchSelectModeState {
  bool get isActive;
  Set<String> get selectedIds;

  /// Create a copy of BatchSelectModeState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BatchSelectModeStateCopyWith<BatchSelectModeState> get copyWith =>
      _$BatchSelectModeStateCopyWithImpl<BatchSelectModeState>(
        this as BatchSelectModeState,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BatchSelectModeState &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(
              other.selectedIds,
              selectedIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isActive,
    const DeepCollectionEquality().hash(selectedIds),
  );

  @override
  String toString() {
    return 'BatchSelectModeState(isActive: $isActive, selectedIds: $selectedIds)';
  }
}

/// @nodoc
abstract mixin class $BatchSelectModeStateCopyWith<$Res> {
  factory $BatchSelectModeStateCopyWith(
    BatchSelectModeState value,
    $Res Function(BatchSelectModeState) _then,
  ) = _$BatchSelectModeStateCopyWithImpl;
  @useResult
  $Res call({bool isActive, Set<String> selectedIds});
}

/// @nodoc
class _$BatchSelectModeStateCopyWithImpl<$Res>
    implements $BatchSelectModeStateCopyWith<$Res> {
  _$BatchSelectModeStateCopyWithImpl(this._self, this._then);

  final BatchSelectModeState _self;
  final $Res Function(BatchSelectModeState) _then;

  /// Create a copy of BatchSelectModeState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? isActive = null, Object? selectedIds = null}) {
    return _then(
      _self.copyWith(
        isActive: null == isActive
            ? _self.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedIds: null == selectedIds
            ? _self.selectedIds
            : selectedIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [BatchSelectModeState].
extension BatchSelectModeStatePatterns on BatchSelectModeState {
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
    TResult Function(_BatchSelectModeState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BatchSelectModeState() when $default != null:
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
    TResult Function(_BatchSelectModeState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatchSelectModeState():
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
    TResult? Function(_BatchSelectModeState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatchSelectModeState() when $default != null:
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
    TResult Function(bool isActive, Set<String> selectedIds)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BatchSelectModeState() when $default != null:
        return $default(_that.isActive, _that.selectedIds);
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
    TResult Function(bool isActive, Set<String> selectedIds) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatchSelectModeState():
        return $default(_that.isActive, _that.selectedIds);
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
    TResult? Function(bool isActive, Set<String> selectedIds)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BatchSelectModeState() when $default != null:
        return $default(_that.isActive, _that.selectedIds);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _BatchSelectModeState implements BatchSelectModeState {
  const _BatchSelectModeState({
    this.isActive = false,
    final Set<String> selectedIds = const <String>{},
  }) : _selectedIds = selectedIds;

  @override
  @JsonKey()
  final bool isActive;
  final Set<String> _selectedIds;
  @override
  @JsonKey()
  Set<String> get selectedIds {
    if (_selectedIds is EqualUnmodifiableSetView) return _selectedIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableSetView(_selectedIds);
  }

  /// Create a copy of BatchSelectModeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BatchSelectModeStateCopyWith<_BatchSelectModeState> get copyWith =>
      __$BatchSelectModeStateCopyWithImpl<_BatchSelectModeState>(
        this,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BatchSelectModeState &&
            (identical(other.isActive, isActive) ||
                other.isActive == isActive) &&
            const DeepCollectionEquality().equals(
              other._selectedIds,
              _selectedIds,
            ));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    isActive,
    const DeepCollectionEquality().hash(_selectedIds),
  );

  @override
  String toString() {
    return 'BatchSelectModeState(isActive: $isActive, selectedIds: $selectedIds)';
  }
}

/// @nodoc
abstract mixin class _$BatchSelectModeStateCopyWith<$Res>
    implements $BatchSelectModeStateCopyWith<$Res> {
  factory _$BatchSelectModeStateCopyWith(
    _BatchSelectModeState value,
    $Res Function(_BatchSelectModeState) _then,
  ) = __$BatchSelectModeStateCopyWithImpl;
  @override
  @useResult
  $Res call({bool isActive, Set<String> selectedIds});
}

/// @nodoc
class __$BatchSelectModeStateCopyWithImpl<$Res>
    implements _$BatchSelectModeStateCopyWith<$Res> {
  __$BatchSelectModeStateCopyWithImpl(this._self, this._then);

  final _BatchSelectModeState _self;
  final $Res Function(_BatchSelectModeState) _then;

  /// Create a copy of BatchSelectModeState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? isActive = null, Object? selectedIds = null}) {
    return _then(
      _BatchSelectModeState(
        isActive: null == isActive
            ? _self.isActive
            : isActive // ignore: cast_nullable_to_non_nullable
                  as bool,
        selectedIds: null == selectedIds
            ? _self._selectedIds
            : selectedIds // ignore: cast_nullable_to_non_nullable
                  as Set<String>,
      ),
    );
  }
}
