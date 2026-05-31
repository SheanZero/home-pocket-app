// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction_details_form_config.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$TransactionDetailsFormConfig {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TransactionDetailsFormConfig);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TransactionDetailsFormConfig()';
  }
}

/// @nodoc
class $TransactionDetailsFormConfigCopyWith<$Res> {
  $TransactionDetailsFormConfigCopyWith(
    TransactionDetailsFormConfig _,
    $Res Function(TransactionDetailsFormConfig) __,
  );
}

/// Adds pattern-matching-related methods to [TransactionDetailsFormConfig].
extension TransactionDetailsFormConfigPatterns on TransactionDetailsFormConfig {
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
    TResult Function(NewEntryConfig value)? $new,
    TResult Function(EditEntryConfig value)? edit,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case NewEntryConfig() when $new != null:
        return $new(_that);
      case EditEntryConfig() when edit != null:
        return edit(_that);
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
    required TResult Function(NewEntryConfig value) $new,
    required TResult Function(EditEntryConfig value) edit,
  }) {
    final _that = this;
    switch (_that) {
      case NewEntryConfig():
        return $new(_that);
      case EditEntryConfig():
        return edit(_that);
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
    TResult? Function(NewEntryConfig value)? $new,
    TResult? Function(EditEntryConfig value)? edit,
  }) {
    final _that = this;
    switch (_that) {
      case NewEntryConfig() when $new != null:
        return $new(_that);
      case EditEntryConfig() when edit != null:
        return edit(_that);
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
    TResult Function(
      String bookId,
      int? initialAmount,
      Category? initialCategory,
      Category? initialParentCategory,
      String? initialMerchant,
      int? initialSatisfaction,
      DateTime? initialDate,
      EntrySource entrySource,
      String? voiceKeyword,
    )?
    $new,
    TResult Function(Transaction seed)? edit,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case NewEntryConfig() when $new != null:
        return $new(
          _that.bookId,
          _that.initialAmount,
          _that.initialCategory,
          _that.initialParentCategory,
          _that.initialMerchant,
          _that.initialSatisfaction,
          _that.initialDate,
          _that.entrySource,
          _that.voiceKeyword,
        );
      case EditEntryConfig() when edit != null:
        return edit(_that.seed);
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
    required TResult Function(
      String bookId,
      int? initialAmount,
      Category? initialCategory,
      Category? initialParentCategory,
      String? initialMerchant,
      int? initialSatisfaction,
      DateTime? initialDate,
      EntrySource entrySource,
      String? voiceKeyword,
    )
    $new,
    required TResult Function(Transaction seed) edit,
  }) {
    final _that = this;
    switch (_that) {
      case NewEntryConfig():
        return $new(
          _that.bookId,
          _that.initialAmount,
          _that.initialCategory,
          _that.initialParentCategory,
          _that.initialMerchant,
          _that.initialSatisfaction,
          _that.initialDate,
          _that.entrySource,
          _that.voiceKeyword,
        );
      case EditEntryConfig():
        return edit(_that.seed);
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
    TResult? Function(
      String bookId,
      int? initialAmount,
      Category? initialCategory,
      Category? initialParentCategory,
      String? initialMerchant,
      int? initialSatisfaction,
      DateTime? initialDate,
      EntrySource entrySource,
      String? voiceKeyword,
    )?
    $new,
    TResult? Function(Transaction seed)? edit,
  }) {
    final _that = this;
    switch (_that) {
      case NewEntryConfig() when $new != null:
        return $new(
          _that.bookId,
          _that.initialAmount,
          _that.initialCategory,
          _that.initialParentCategory,
          _that.initialMerchant,
          _that.initialSatisfaction,
          _that.initialDate,
          _that.entrySource,
          _that.voiceKeyword,
        );
      case EditEntryConfig() when edit != null:
        return edit(_that.seed);
      case _:
        return null;
    }
  }
}

/// @nodoc

class NewEntryConfig extends TransactionDetailsFormConfig {
  const NewEntryConfig({
    required this.bookId,
    this.initialAmount,
    this.initialCategory,
    this.initialParentCategory,
    this.initialMerchant,
    this.initialSatisfaction,
    this.initialDate,
    required this.entrySource,
    this.voiceKeyword,
  }) : super._();

  final String bookId;
  final int? initialAmount;
  final Category? initialCategory;
  final Category? initialParentCategory;
  final String? initialMerchant;
  final int? initialSatisfaction;
  final DateTime? initialDate;
  final EntrySource entrySource;
  // Voice-correction keyword — present only in .new mode (D-09).
  final String? voiceKeyword;

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NewEntryConfigCopyWith<NewEntryConfig> get copyWith =>
      _$NewEntryConfigCopyWithImpl<NewEntryConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NewEntryConfig &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.initialAmount, initialAmount) ||
                other.initialAmount == initialAmount) &&
            (identical(other.initialCategory, initialCategory) ||
                other.initialCategory == initialCategory) &&
            (identical(other.initialParentCategory, initialParentCategory) ||
                other.initialParentCategory == initialParentCategory) &&
            (identical(other.initialMerchant, initialMerchant) ||
                other.initialMerchant == initialMerchant) &&
            (identical(other.initialSatisfaction, initialSatisfaction) ||
                other.initialSatisfaction == initialSatisfaction) &&
            (identical(other.initialDate, initialDate) ||
                other.initialDate == initialDate) &&
            (identical(other.entrySource, entrySource) ||
                other.entrySource == entrySource) &&
            (identical(other.voiceKeyword, voiceKeyword) ||
                other.voiceKeyword == voiceKeyword));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    bookId,
    initialAmount,
    initialCategory,
    initialParentCategory,
    initialMerchant,
    initialSatisfaction,
    initialDate,
    entrySource,
    voiceKeyword,
  );

  @override
  String toString() {
    return 'TransactionDetailsFormConfig.\$new(bookId: $bookId, initialAmount: $initialAmount, initialCategory: $initialCategory, initialParentCategory: $initialParentCategory, initialMerchant: $initialMerchant, initialSatisfaction: $initialSatisfaction, initialDate: $initialDate, entrySource: $entrySource, voiceKeyword: $voiceKeyword)';
  }
}

/// @nodoc
abstract mixin class $NewEntryConfigCopyWith<$Res>
    implements $TransactionDetailsFormConfigCopyWith<$Res> {
  factory $NewEntryConfigCopyWith(
    NewEntryConfig value,
    $Res Function(NewEntryConfig) _then,
  ) = _$NewEntryConfigCopyWithImpl;
  @useResult
  $Res call({
    String bookId,
    int? initialAmount,
    Category? initialCategory,
    Category? initialParentCategory,
    String? initialMerchant,
    int? initialSatisfaction,
    DateTime? initialDate,
    EntrySource entrySource,
    String? voiceKeyword,
  });

  $CategoryCopyWith<$Res>? get initialCategory;
  $CategoryCopyWith<$Res>? get initialParentCategory;
}

/// @nodoc
class _$NewEntryConfigCopyWithImpl<$Res>
    implements $NewEntryConfigCopyWith<$Res> {
  _$NewEntryConfigCopyWithImpl(this._self, this._then);

  final NewEntryConfig _self;
  final $Res Function(NewEntryConfig) _then;

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookId = null,
    Object? initialAmount = freezed,
    Object? initialCategory = freezed,
    Object? initialParentCategory = freezed,
    Object? initialMerchant = freezed,
    Object? initialSatisfaction = freezed,
    Object? initialDate = freezed,
    Object? entrySource = null,
    Object? voiceKeyword = freezed,
  }) {
    return _then(
      NewEntryConfig(
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        initialAmount: freezed == initialAmount
            ? _self.initialAmount
            : initialAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        initialCategory: freezed == initialCategory
            ? _self.initialCategory
            : initialCategory // ignore: cast_nullable_to_non_nullable
                  as Category?,
        initialParentCategory: freezed == initialParentCategory
            ? _self.initialParentCategory
            : initialParentCategory // ignore: cast_nullable_to_non_nullable
                  as Category?,
        initialMerchant: freezed == initialMerchant
            ? _self.initialMerchant
            : initialMerchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        initialSatisfaction: freezed == initialSatisfaction
            ? _self.initialSatisfaction
            : initialSatisfaction // ignore: cast_nullable_to_non_nullable
                  as int?,
        initialDate: freezed == initialDate
            ? _self.initialDate
            : initialDate // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        entrySource: null == entrySource
            ? _self.entrySource
            : entrySource // ignore: cast_nullable_to_non_nullable
                  as EntrySource,
        voiceKeyword: freezed == voiceKeyword
            ? _self.voiceKeyword
            : voiceKeyword // ignore: cast_nullable_to_non_nullable
                  as String?,
      ),
    );
  }

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<$Res>? get initialCategory {
    if (_self.initialCategory == null) {
      return null;
    }

    return $CategoryCopyWith<$Res>(_self.initialCategory!, (value) {
      return _then(_self.copyWith(initialCategory: value));
    });
  }

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $CategoryCopyWith<$Res>? get initialParentCategory {
    if (_self.initialParentCategory == null) {
      return null;
    }

    return $CategoryCopyWith<$Res>(_self.initialParentCategory!, (value) {
      return _then(_self.copyWith(initialParentCategory: value));
    });
  }
}

/// @nodoc

class EditEntryConfig extends TransactionDetailsFormConfig {
  const EditEntryConfig({required this.seed}) : super._();

  final Transaction seed;

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $EditEntryConfigCopyWith<EditEntryConfig> get copyWith =>
      _$EditEntryConfigCopyWithImpl<EditEntryConfig>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is EditEntryConfig &&
            (identical(other.seed, seed) || other.seed == seed));
  }

  @override
  int get hashCode => Object.hash(runtimeType, seed);

  @override
  String toString() {
    return 'TransactionDetailsFormConfig.edit(seed: $seed)';
  }
}

/// @nodoc
abstract mixin class $EditEntryConfigCopyWith<$Res>
    implements $TransactionDetailsFormConfigCopyWith<$Res> {
  factory $EditEntryConfigCopyWith(
    EditEntryConfig value,
    $Res Function(EditEntryConfig) _then,
  ) = _$EditEntryConfigCopyWithImpl;
  @useResult
  $Res call({Transaction seed});

  $TransactionCopyWith<$Res> get seed;
}

/// @nodoc
class _$EditEntryConfigCopyWithImpl<$Res>
    implements $EditEntryConfigCopyWith<$Res> {
  _$EditEntryConfigCopyWithImpl(this._self, this._then);

  final EditEntryConfig _self;
  final $Res Function(EditEntryConfig) _then;

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? seed = null}) {
    return _then(
      EditEntryConfig(
        seed: null == seed
            ? _self.seed
            : seed // ignore: cast_nullable_to_non_nullable
                  as Transaction,
      ),
    );
  }

  /// Create a copy of TransactionDetailsFormConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<$Res> get seed {
    return $TransactionCopyWith<$Res>(_self.seed, (value) {
      return _then(_self.copyWith(seed: value));
    });
  }
}

/// @nodoc
mixin _$TransactionDetailsFormResult {
  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is TransactionDetailsFormResult);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  String toString() {
    return 'TransactionDetailsFormResult()';
  }
}

/// @nodoc
class $TransactionDetailsFormResultCopyWith<$Res> {
  $TransactionDetailsFormResultCopyWith(
    TransactionDetailsFormResult _,
    $Res Function(TransactionDetailsFormResult) __,
  );
}

/// Adds pattern-matching-related methods to [TransactionDetailsFormResult].
extension TransactionDetailsFormResultPatterns on TransactionDetailsFormResult {
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
    TResult Function(_Success value)? success,
    TResult Function(_ValidationError value)? validationError,
    TResult Function(_PersistError value)? persistError,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Success() when success != null:
        return success(_that);
      case _ValidationError() when validationError != null:
        return validationError(_that);
      case _PersistError() when persistError != null:
        return persistError(_that);
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
    required TResult Function(_Success value) success,
    required TResult Function(_ValidationError value) validationError,
    required TResult Function(_PersistError value) persistError,
  }) {
    final _that = this;
    switch (_that) {
      case _Success():
        return success(_that);
      case _ValidationError():
        return validationError(_that);
      case _PersistError():
        return persistError(_that);
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
    TResult? Function(_Success value)? success,
    TResult? Function(_ValidationError value)? validationError,
    TResult? Function(_PersistError value)? persistError,
  }) {
    final _that = this;
    switch (_that) {
      case _Success() when success != null:
        return success(_that);
      case _ValidationError() when validationError != null:
        return validationError(_that);
      case _PersistError() when persistError != null:
        return persistError(_that);
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
    TResult Function(Transaction transaction)? success,
    TResult Function(String message)? validationError,
    TResult Function(String message)? persistError,
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Success() when success != null:
        return success(_that.transaction);
      case _ValidationError() when validationError != null:
        return validationError(_that.message);
      case _PersistError() when persistError != null:
        return persistError(_that.message);
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
    required TResult Function(Transaction transaction) success,
    required TResult Function(String message) validationError,
    required TResult Function(String message) persistError,
  }) {
    final _that = this;
    switch (_that) {
      case _Success():
        return success(_that.transaction);
      case _ValidationError():
        return validationError(_that.message);
      case _PersistError():
        return persistError(_that.message);
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
    TResult? Function(Transaction transaction)? success,
    TResult? Function(String message)? validationError,
    TResult? Function(String message)? persistError,
  }) {
    final _that = this;
    switch (_that) {
      case _Success() when success != null:
        return success(_that.transaction);
      case _ValidationError() when validationError != null:
        return validationError(_that.message);
      case _PersistError() when persistError != null:
        return persistError(_that.message);
      case _:
        return null;
    }
  }
}

/// @nodoc

class _Success extends TransactionDetailsFormResult {
  const _Success(this.transaction) : super._();

  final Transaction transaction;

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SuccessCopyWith<_Success> get copyWith =>
      __$SuccessCopyWithImpl<_Success>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Success &&
            (identical(other.transaction, transaction) ||
                other.transaction == transaction));
  }

  @override
  int get hashCode => Object.hash(runtimeType, transaction);

  @override
  String toString() {
    return 'TransactionDetailsFormResult.success(transaction: $transaction)';
  }
}

/// @nodoc
abstract mixin class _$SuccessCopyWith<$Res>
    implements $TransactionDetailsFormResultCopyWith<$Res> {
  factory _$SuccessCopyWith(_Success value, $Res Function(_Success) _then) =
      __$SuccessCopyWithImpl;
  @useResult
  $Res call({Transaction transaction});

  $TransactionCopyWith<$Res> get transaction;
}

/// @nodoc
class __$SuccessCopyWithImpl<$Res> implements _$SuccessCopyWith<$Res> {
  __$SuccessCopyWithImpl(this._self, this._then);

  final _Success _self;
  final $Res Function(_Success) _then;

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? transaction = null}) {
    return _then(
      _Success(
        null == transaction
            ? _self.transaction
            : transaction // ignore: cast_nullable_to_non_nullable
                  as Transaction,
      ),
    );
  }

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<$Res> get transaction {
    return $TransactionCopyWith<$Res>(_self.transaction, (value) {
      return _then(_self.copyWith(transaction: value));
    });
  }
}

/// @nodoc

class _ValidationError extends TransactionDetailsFormResult {
  const _ValidationError(this.message) : super._();

  final String message;

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ValidationErrorCopyWith<_ValidationError> get copyWith =>
      __$ValidationErrorCopyWithImpl<_ValidationError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ValidationError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'TransactionDetailsFormResult.validationError(message: $message)';
  }
}

/// @nodoc
abstract mixin class _$ValidationErrorCopyWith<$Res>
    implements $TransactionDetailsFormResultCopyWith<$Res> {
  factory _$ValidationErrorCopyWith(
    _ValidationError value,
    $Res Function(_ValidationError) _then,
  ) = __$ValidationErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$ValidationErrorCopyWithImpl<$Res>
    implements _$ValidationErrorCopyWith<$Res> {
  __$ValidationErrorCopyWithImpl(this._self, this._then);

  final _ValidationError _self;
  final $Res Function(_ValidationError) _then;

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? message = null}) {
    return _then(
      _ValidationError(
        null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _PersistError extends TransactionDetailsFormResult {
  const _PersistError(this.message) : super._();

  final String message;

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$PersistErrorCopyWith<_PersistError> get copyWith =>
      __$PersistErrorCopyWithImpl<_PersistError>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _PersistError &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  @override
  String toString() {
    return 'TransactionDetailsFormResult.persistError(message: $message)';
  }
}

/// @nodoc
abstract mixin class _$PersistErrorCopyWith<$Res>
    implements $TransactionDetailsFormResultCopyWith<$Res> {
  factory _$PersistErrorCopyWith(
    _PersistError value,
    $Res Function(_PersistError) _then,
  ) = __$PersistErrorCopyWithImpl;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$PersistErrorCopyWithImpl<$Res>
    implements _$PersistErrorCopyWith<$Res> {
  __$PersistErrorCopyWithImpl(this._self, this._then);

  final _PersistError _self;
  final $Res Function(_PersistError) _then;

  /// Create a copy of TransactionDetailsFormResult
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  $Res call({Object? message = null}) {
    return _then(
      _PersistError(
        null == message
            ? _self.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
