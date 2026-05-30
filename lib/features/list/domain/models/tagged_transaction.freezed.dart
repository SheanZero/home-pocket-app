// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'tagged_transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$MemberTag {
  String get emoji;
  String get name;

  /// Create a copy of MemberTag
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MemberTagCopyWith<MemberTag> get copyWith =>
      _$MemberTagCopyWithImpl<MemberTag>(this as MemberTag, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MemberTag &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, emoji, name);

  @override
  String toString() {
    return 'MemberTag(emoji: $emoji, name: $name)';
  }
}

/// @nodoc
abstract mixin class $MemberTagCopyWith<$Res> {
  factory $MemberTagCopyWith(MemberTag value, $Res Function(MemberTag) _then) =
      _$MemberTagCopyWithImpl;
  @useResult
  $Res call({String emoji, String name});
}

/// @nodoc
class _$MemberTagCopyWithImpl<$Res> implements $MemberTagCopyWith<$Res> {
  _$MemberTagCopyWithImpl(this._self, this._then);

  final MemberTag _self;
  final $Res Function(MemberTag) _then;

  /// Create a copy of MemberTag
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? emoji = null, Object? name = null}) {
    return _then(
      _self.copyWith(
        emoji: null == emoji
            ? _self.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [MemberTag].
extension MemberTagPatterns on MemberTag {
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
    TResult Function(_MemberTag value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MemberTag() when $default != null:
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
    TResult Function(_MemberTag value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemberTag():
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
    TResult? Function(_MemberTag value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemberTag() when $default != null:
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
    TResult Function(String emoji, String name)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MemberTag() when $default != null:
        return $default(_that.emoji, _that.name);
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
    TResult Function(String emoji, String name) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemberTag():
        return $default(_that.emoji, _that.name);
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
    TResult? Function(String emoji, String name)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MemberTag() when $default != null:
        return $default(_that.emoji, _that.name);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _MemberTag implements MemberTag {
  const _MemberTag({required this.emoji, required this.name});

  @override
  final String emoji;
  @override
  final String name;

  /// Create a copy of MemberTag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MemberTagCopyWith<_MemberTag> get copyWith =>
      __$MemberTagCopyWithImpl<_MemberTag>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MemberTag &&
            (identical(other.emoji, emoji) || other.emoji == emoji) &&
            (identical(other.name, name) || other.name == name));
  }

  @override
  int get hashCode => Object.hash(runtimeType, emoji, name);

  @override
  String toString() {
    return 'MemberTag(emoji: $emoji, name: $name)';
  }
}

/// @nodoc
abstract mixin class _$MemberTagCopyWith<$Res>
    implements $MemberTagCopyWith<$Res> {
  factory _$MemberTagCopyWith(
    _MemberTag value,
    $Res Function(_MemberTag) _then,
  ) = __$MemberTagCopyWithImpl;
  @override
  @useResult
  $Res call({String emoji, String name});
}

/// @nodoc
class __$MemberTagCopyWithImpl<$Res> implements _$MemberTagCopyWith<$Res> {
  __$MemberTagCopyWithImpl(this._self, this._then);

  final _MemberTag _self;
  final $Res Function(_MemberTag) _then;

  /// Create a copy of MemberTag
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? emoji = null, Object? name = null}) {
    return _then(
      _MemberTag(
        emoji: null == emoji
            ? _self.emoji
            : emoji // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc
mixin _$TaggedTransaction {
  Transaction get transaction;
  MemberTag? get memberTag;

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TaggedTransactionCopyWith<TaggedTransaction> get copyWith =>
      _$TaggedTransactionCopyWithImpl<TaggedTransaction>(
        this as TaggedTransaction,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TaggedTransaction &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.memberTag, memberTag) ||
                other.memberTag == memberTag));
  }

  @override
  int get hashCode => Object.hash(runtimeType, transaction, memberTag);

  @override
  String toString() {
    return 'TaggedTransaction(transaction: $transaction, memberTag: $memberTag)';
  }
}

/// @nodoc
abstract mixin class $TaggedTransactionCopyWith<$Res> {
  factory $TaggedTransactionCopyWith(
    TaggedTransaction value,
    $Res Function(TaggedTransaction) _then,
  ) = _$TaggedTransactionCopyWithImpl;
  @useResult
  $Res call({Transaction transaction, MemberTag? memberTag});

  $TransactionCopyWith<$Res> get transaction;
  $MemberTagCopyWith<$Res>? get memberTag;
}

/// @nodoc
class _$TaggedTransactionCopyWithImpl<$Res>
    implements $TaggedTransactionCopyWith<$Res> {
  _$TaggedTransactionCopyWithImpl(this._self, this._then);

  final TaggedTransaction _self;
  final $Res Function(TaggedTransaction) _then;

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? transaction = null, Object? memberTag = freezed}) {
    return _then(
      _self.copyWith(
        transaction: null == transaction
            ? _self.transaction
            : transaction // ignore: cast_nullable_to_non_nullable
                  as Transaction,
        memberTag: freezed == memberTag
            ? _self.memberTag
            : memberTag // ignore: cast_nullable_to_non_nullable
                  as MemberTag?,
      ),
    );
  }

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<$Res> get transaction {
    return $TransactionCopyWith<$Res>(_self.transaction, (value) {
      return _then(_self.copyWith(transaction: value));
    });
  }

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemberTagCopyWith<$Res>? get memberTag {
    if (_self.memberTag == null) {
      return null;
    }

    return $MemberTagCopyWith<$Res>(_self.memberTag!, (value) {
      return _then(_self.copyWith(memberTag: value));
    });
  }
}

/// Adds pattern-matching-related methods to [TaggedTransaction].
extension TaggedTransactionPatterns on TaggedTransaction {
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
    TResult Function(_TaggedTransaction value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaggedTransaction() when $default != null:
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
    TResult Function(_TaggedTransaction value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaggedTransaction():
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
    TResult? Function(_TaggedTransaction value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaggedTransaction() when $default != null:
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
    TResult Function(Transaction transaction, MemberTag? memberTag)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _TaggedTransaction() when $default != null:
        return $default(_that.transaction, _that.memberTag);
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
    TResult Function(Transaction transaction, MemberTag? memberTag) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaggedTransaction():
        return $default(_that.transaction, _that.memberTag);
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
    TResult? Function(Transaction transaction, MemberTag? memberTag)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _TaggedTransaction() when $default != null:
        return $default(_that.transaction, _that.memberTag);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _TaggedTransaction implements TaggedTransaction {
  const _TaggedTransaction({required this.transaction, this.memberTag});

  @override
  final Transaction transaction;
  @override
  final MemberTag? memberTag;

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TaggedTransactionCopyWith<_TaggedTransaction> get copyWith =>
      __$TaggedTransactionCopyWithImpl<_TaggedTransaction>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _TaggedTransaction &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction) &&
            (identical(other.memberTag, memberTag) ||
                other.memberTag == memberTag));
  }

  @override
  int get hashCode => Object.hash(runtimeType, transaction, memberTag);

  @override
  String toString() {
    return 'TaggedTransaction(transaction: $transaction, memberTag: $memberTag)';
  }
}

/// @nodoc
abstract mixin class _$TaggedTransactionCopyWith<$Res>
    implements $TaggedTransactionCopyWith<$Res> {
  factory _$TaggedTransactionCopyWith(
    _TaggedTransaction value,
    $Res Function(_TaggedTransaction) _then,
  ) = __$TaggedTransactionCopyWithImpl;
  @override
  @useResult
  $Res call({Transaction transaction, MemberTag? memberTag});

  @override
  $TransactionCopyWith<$Res> get transaction;
  @override
  $MemberTagCopyWith<$Res>? get memberTag;
}

/// @nodoc
class __$TaggedTransactionCopyWithImpl<$Res>
    implements _$TaggedTransactionCopyWith<$Res> {
  __$TaggedTransactionCopyWithImpl(this._self, this._then);

  final _TaggedTransaction _self;
  final $Res Function(_TaggedTransaction) _then;

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({Object? transaction = null, Object? memberTag = freezed}) {
    return _then(
      _TaggedTransaction(
        transaction: null == transaction
            ? _self.transaction
            : transaction // ignore: cast_nullable_to_non_nullable
                  as Transaction,
        memberTag: freezed == memberTag
            ? _self.memberTag
            : memberTag // ignore: cast_nullable_to_non_nullable
                  as MemberTag?,
      ),
    );
  }

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<$Res> get transaction {
    return $TransactionCopyWith<$Res>(_self.transaction, (value) {
      return _then(_self.copyWith(transaction: value));
    });
  }

  /// Create a copy of TaggedTransaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MemberTagCopyWith<$Res>? get memberTag {
    if (_self.memberTag == null) {
      return null;
    }

    return $MemberTagCopyWith<$Res>(_self.memberTag!, (value) {
      return _then(_self.copyWith(memberTag: value));
    });
  }
}
