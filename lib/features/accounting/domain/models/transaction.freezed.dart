// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'transaction.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$Transaction {
  String get id;
  String get bookId;
  String get deviceId;
  int get amount;
  TransactionType get type;
  String get categoryId;
  LedgerType get ledgerType;
  DateTime get timestamp; // Optional fields
  String? get note;
  String? get photoHash;
  String? get merchant; // Hash chain
  String? get prevHash;
  String get currentHash; // Timestamps
  DateTime get createdAt;
  DateTime? get updatedAt; // Flags
  bool get isPrivate;
  bool get isSynced;
  bool get isDeleted;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $TransactionCopyWith<Transaction> get copyWith =>
      _$TransactionCopyWithImpl<Transaction>(this as Transaction, _$identity);

  /// Serializes this Transaction to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is Transaction &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.photoHash, photoHash) ||
                other.photoHash == photoHash) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.prevHash, prevHash) ||
                other.prevHash == prevHash) &&
            (identical(other.currentHash, currentHash) ||
                other.currentHash == currentHash) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookId,
    deviceId,
    amount,
    type,
    categoryId,
    ledgerType,
    timestamp,
    note,
    photoHash,
    merchant,
    prevHash,
    currentHash,
    createdAt,
    updatedAt,
    isPrivate,
    isSynced,
    isDeleted,
  );

  @override
  String toString() {
    return 'Transaction(id: $id, bookId: $bookId, deviceId: $deviceId, amount: $amount, type: $type, categoryId: $categoryId, ledgerType: $ledgerType, timestamp: $timestamp, note: $note, photoHash: $photoHash, merchant: $merchant, prevHash: $prevHash, currentHash: $currentHash, createdAt: $createdAt, updatedAt: $updatedAt, isPrivate: $isPrivate, isSynced: $isSynced, isDeleted: $isDeleted)';
  }
}

/// @nodoc
abstract mixin class $TransactionCopyWith<$Res> {
  factory $TransactionCopyWith(
    Transaction value,
    $Res Function(Transaction) _then,
  ) = _$TransactionCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String bookId,
    String deviceId,
    int amount,
    TransactionType type,
    String categoryId,
    LedgerType ledgerType,
    DateTime timestamp,
    String? note,
    String? photoHash,
    String? merchant,
    String? prevHash,
    String currentHash,
    DateTime createdAt,
    DateTime? updatedAt,
    bool isPrivate,
    bool isSynced,
    bool isDeleted,
  });
}

/// @nodoc
class _$TransactionCopyWithImpl<$Res> implements $TransactionCopyWith<$Res> {
  _$TransactionCopyWithImpl(this._self, this._then);

  final Transaction _self;
  final $Res Function(Transaction) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? bookId = null,
    Object? deviceId = null,
    Object? amount = null,
    Object? type = null,
    Object? categoryId = null,
    Object? ledgerType = null,
    Object? timestamp = null,
    Object? note = freezed,
    Object? photoHash = freezed,
    Object? merchant = freezed,
    Object? prevHash = freezed,
    Object? currentHash = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? isPrivate = null,
    Object? isSynced = null,
    Object? isDeleted = null,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: null == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        note: freezed == note
            ? _self.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoHash: freezed == photoHash
            ? _self.photoHash
            : photoHash // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchant: freezed == merchant
            ? _self.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        prevHash: freezed == prevHash
            ? _self.prevHash
            : prevHash // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentHash: null == currentHash
            ? _self.currentHash
            : currentHash // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isPrivate: null == isPrivate
            ? _self.isPrivate
            : isPrivate // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSynced: null == isSynced
            ? _self.isSynced
            : isSynced // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _self.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [Transaction].
extension TransactionPatterns on Transaction {
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
    TResult Function(_Transaction value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Transaction() when $default != null:
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
    TResult Function(_Transaction value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Transaction():
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
    TResult? Function(_Transaction value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Transaction() when $default != null:
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
      String id,
      String bookId,
      String deviceId,
      int amount,
      TransactionType type,
      String categoryId,
      LedgerType ledgerType,
      DateTime timestamp,
      String? note,
      String? photoHash,
      String? merchant,
      String? prevHash,
      String currentHash,
      DateTime createdAt,
      DateTime? updatedAt,
      bool isPrivate,
      bool isSynced,
      bool isDeleted,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _Transaction() when $default != null:
        return $default(
          _that.id,
          _that.bookId,
          _that.deviceId,
          _that.amount,
          _that.type,
          _that.categoryId,
          _that.ledgerType,
          _that.timestamp,
          _that.note,
          _that.photoHash,
          _that.merchant,
          _that.prevHash,
          _that.currentHash,
          _that.createdAt,
          _that.updatedAt,
          _that.isPrivate,
          _that.isSynced,
          _that.isDeleted,
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
      String id,
      String bookId,
      String deviceId,
      int amount,
      TransactionType type,
      String categoryId,
      LedgerType ledgerType,
      DateTime timestamp,
      String? note,
      String? photoHash,
      String? merchant,
      String? prevHash,
      String currentHash,
      DateTime createdAt,
      DateTime? updatedAt,
      bool isPrivate,
      bool isSynced,
      bool isDeleted,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Transaction():
        return $default(
          _that.id,
          _that.bookId,
          _that.deviceId,
          _that.amount,
          _that.type,
          _that.categoryId,
          _that.ledgerType,
          _that.timestamp,
          _that.note,
          _that.photoHash,
          _that.merchant,
          _that.prevHash,
          _that.currentHash,
          _that.createdAt,
          _that.updatedAt,
          _that.isPrivate,
          _that.isSynced,
          _that.isDeleted,
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
      String id,
      String bookId,
      String deviceId,
      int amount,
      TransactionType type,
      String categoryId,
      LedgerType ledgerType,
      DateTime timestamp,
      String? note,
      String? photoHash,
      String? merchant,
      String? prevHash,
      String currentHash,
      DateTime createdAt,
      DateTime? updatedAt,
      bool isPrivate,
      bool isSynced,
      bool isDeleted,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _Transaction() when $default != null:
        return $default(
          _that.id,
          _that.bookId,
          _that.deviceId,
          _that.amount,
          _that.type,
          _that.categoryId,
          _that.ledgerType,
          _that.timestamp,
          _that.note,
          _that.photoHash,
          _that.merchant,
          _that.prevHash,
          _that.currentHash,
          _that.createdAt,
          _that.updatedAt,
          _that.isPrivate,
          _that.isSynced,
          _that.isDeleted,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _Transaction implements Transaction {
  const _Transaction({
    required this.id,
    required this.bookId,
    required this.deviceId,
    required this.amount,
    required this.type,
    required this.categoryId,
    required this.ledgerType,
    required this.timestamp,
    this.note,
    this.photoHash,
    this.merchant,
    this.prevHash,
    required this.currentHash,
    required this.createdAt,
    this.updatedAt,
    this.isPrivate = false,
    this.isSynced = false,
    this.isDeleted = false,
  });
  factory _Transaction.fromJson(Map<String, dynamic> json) =>
      _$TransactionFromJson(json);

  @override
  final String id;
  @override
  final String bookId;
  @override
  final String deviceId;
  @override
  final int amount;
  @override
  final TransactionType type;
  @override
  final String categoryId;
  @override
  final LedgerType ledgerType;
  @override
  final DateTime timestamp;
  // Optional fields
  @override
  final String? note;
  @override
  final String? photoHash;
  @override
  final String? merchant;
  // Hash chain
  @override
  final String? prevHash;
  @override
  final String currentHash;
  // Timestamps
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;
  // Flags
  @override
  @JsonKey()
  final bool isPrivate;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  @JsonKey()
  final bool isDeleted;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$TransactionCopyWith<_Transaction> get copyWith =>
      __$TransactionCopyWithImpl<_Transaction>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$TransactionToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _Transaction &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.type, type) || other.type == type) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.photoHash, photoHash) ||
                other.photoHash == photoHash) &&
            (identical(other.merchant, merchant) ||
                other.merchant == merchant) &&
            (identical(other.prevHash, prevHash) ||
                other.prevHash == prevHash) &&
            (identical(other.currentHash, currentHash) ||
                other.currentHash == currentHash) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt) &&
            (identical(other.isPrivate, isPrivate) ||
                other.isPrivate == isPrivate) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    bookId,
    deviceId,
    amount,
    type,
    categoryId,
    ledgerType,
    timestamp,
    note,
    photoHash,
    merchant,
    prevHash,
    currentHash,
    createdAt,
    updatedAt,
    isPrivate,
    isSynced,
    isDeleted,
  );

  @override
  String toString() {
    return 'Transaction(id: $id, bookId: $bookId, deviceId: $deviceId, amount: $amount, type: $type, categoryId: $categoryId, ledgerType: $ledgerType, timestamp: $timestamp, note: $note, photoHash: $photoHash, merchant: $merchant, prevHash: $prevHash, currentHash: $currentHash, createdAt: $createdAt, updatedAt: $updatedAt, isPrivate: $isPrivate, isSynced: $isSynced, isDeleted: $isDeleted)';
  }
}

/// @nodoc
abstract mixin class _$TransactionCopyWith<$Res>
    implements $TransactionCopyWith<$Res> {
  factory _$TransactionCopyWith(
    _Transaction value,
    $Res Function(_Transaction) _then,
  ) = __$TransactionCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String bookId,
    String deviceId,
    int amount,
    TransactionType type,
    String categoryId,
    LedgerType ledgerType,
    DateTime timestamp,
    String? note,
    String? photoHash,
    String? merchant,
    String? prevHash,
    String currentHash,
    DateTime createdAt,
    DateTime? updatedAt,
    bool isPrivate,
    bool isSynced,
    bool isDeleted,
  });
}

/// @nodoc
class __$TransactionCopyWithImpl<$Res> implements _$TransactionCopyWith<$Res> {
  __$TransactionCopyWithImpl(this._self, this._then);

  final _Transaction _self;
  final $Res Function(_Transaction) _then;

  /// Create a copy of Transaction
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? bookId = null,
    Object? deviceId = null,
    Object? amount = null,
    Object? type = null,
    Object? categoryId = null,
    Object? ledgerType = null,
    Object? timestamp = null,
    Object? note = freezed,
    Object? photoHash = freezed,
    Object? merchant = freezed,
    Object? prevHash = freezed,
    Object? currentHash = null,
    Object? createdAt = null,
    Object? updatedAt = freezed,
    Object? isPrivate = null,
    Object? isSynced = null,
    Object? isDeleted = null,
  }) {
    return _then(
      _Transaction(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        bookId: null == bookId
            ? _self.bookId
            : bookId // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        amount: null == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        type: null == type
            ? _self.type
            : type // ignore: cast_nullable_to_non_nullable
                  as TransactionType,
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: null == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType,
        timestamp: null == timestamp
            ? _self.timestamp
            : timestamp // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        note: freezed == note
            ? _self.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        photoHash: freezed == photoHash
            ? _self.photoHash
            : photoHash // ignore: cast_nullable_to_non_nullable
                  as String?,
        merchant: freezed == merchant
            ? _self.merchant
            : merchant // ignore: cast_nullable_to_non_nullable
                  as String?,
        prevHash: freezed == prevHash
            ? _self.prevHash
            : prevHash // ignore: cast_nullable_to_non_nullable
                  as String?,
        currentHash: null == currentHash
            ? _self.currentHash
            : currentHash // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isPrivate: null == isPrivate
            ? _self.isPrivate
            : isPrivate // ignore: cast_nullable_to_non_nullable
                  as bool,
        isSynced: null == isSynced
            ? _self.isSynced
            : isSynced // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _self.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
      ),
    );
  }
}
