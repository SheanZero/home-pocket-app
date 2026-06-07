// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shopping_item.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ShoppingItem {
  String get id;
  String get deviceId;
  String get listType; // 'public' | 'private'
  String get name;
  LedgerType? get ledgerType;
  String? get categoryId;
  List<String> get tags; // D-01: JSON-encoded at repo boundary
  String? get note; // decrypted plaintext
  int get quantity; // D-02
  int? get estimatedPrice; // ITEM-05
  DateTime? get completedAt; // D-03
  bool get isCompleted;
  int get sortOrder;
  bool get isSynced;
  bool get isDeleted;
  String? get addedByBookId;
  DateTime get createdAt;
  DateTime? get updatedAt;

  /// Create a copy of ShoppingItem
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ShoppingItemCopyWith<ShoppingItem> get copyWith =>
      _$ShoppingItemCopyWithImpl<ShoppingItem>(
        this as ShoppingItem,
        _$identity,
      );

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ShoppingItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality().equals(other.tags, tags) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.estimatedPrice, estimatedPrice) ||
                other.estimatedPrice == estimatedPrice) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.addedByBookId, addedByBookId) ||
                other.addedByBookId == addedByBookId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    deviceId,
    listType,
    name,
    ledgerType,
    categoryId,
    const DeepCollectionEquality().hash(tags),
    note,
    quantity,
    estimatedPrice,
    completedAt,
    isCompleted,
    sortOrder,
    isSynced,
    isDeleted,
    addedByBookId,
    createdAt,
    updatedAt,
  );

  @override
  String toString() {
    return 'ShoppingItem(id: $id, deviceId: $deviceId, listType: $listType, name: $name, ledgerType: $ledgerType, categoryId: $categoryId, tags: $tags, note: $note, quantity: $quantity, estimatedPrice: $estimatedPrice, completedAt: $completedAt, isCompleted: $isCompleted, sortOrder: $sortOrder, isSynced: $isSynced, isDeleted: $isDeleted, addedByBookId: $addedByBookId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class $ShoppingItemCopyWith<$Res> {
  factory $ShoppingItemCopyWith(
    ShoppingItem value,
    $Res Function(ShoppingItem) _then,
  ) = _$ShoppingItemCopyWithImpl;
  @useResult
  $Res call({
    String id,
    String deviceId,
    String listType,
    String name,
    LedgerType? ledgerType,
    String? categoryId,
    List<String> tags,
    String? note,
    int quantity,
    int? estimatedPrice,
    DateTime? completedAt,
    bool isCompleted,
    int sortOrder,
    bool isSynced,
    bool isDeleted,
    String? addedByBookId,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class _$ShoppingItemCopyWithImpl<$Res> implements $ShoppingItemCopyWith<$Res> {
  _$ShoppingItemCopyWithImpl(this._self, this._then);

  final ShoppingItem _self;
  final $Res Function(ShoppingItem) _then;

  /// Create a copy of ShoppingItem
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? listType = null,
    Object? name = null,
    Object? ledgerType = freezed,
    Object? categoryId = freezed,
    Object? tags = null,
    Object? note = freezed,
    Object? quantity = null,
    Object? estimatedPrice = freezed,
    Object? completedAt = freezed,
    Object? isCompleted = null,
    Object? sortOrder = null,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? addedByBookId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _self.copyWith(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        listType: null == listType
            ? _self.listType
            : listType // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryId: freezed == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _self.tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        note: freezed == note
            ? _self.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _self.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedPrice: freezed == estimatedPrice
            ? _self.estimatedPrice
            : estimatedPrice // ignore: cast_nullable_to_non_nullable
                  as int?,
        completedAt: freezed == completedAt
            ? _self.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isCompleted: null == isCompleted
            ? _self.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _self.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        isSynced: null == isSynced
            ? _self.isSynced
            : isSynced // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _self.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        addedByBookId: freezed == addedByBookId
            ? _self.addedByBookId
            : addedByBookId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [ShoppingItem].
extension ShoppingItemPatterns on ShoppingItem {
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
    TResult Function(_ShoppingItem value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingItem() when $default != null:
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
    TResult Function(_ShoppingItem value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItem():
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
    TResult? Function(_ShoppingItem value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItem() when $default != null:
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
      String deviceId,
      String listType,
      String name,
      LedgerType? ledgerType,
      String? categoryId,
      List<String> tags,
      String? note,
      int quantity,
      int? estimatedPrice,
      DateTime? completedAt,
      bool isCompleted,
      int sortOrder,
      bool isSynced,
      bool isDeleted,
      String? addedByBookId,
      DateTime createdAt,
      DateTime? updatedAt,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ShoppingItem() when $default != null:
        return $default(
          _that.id,
          _that.deviceId,
          _that.listType,
          _that.name,
          _that.ledgerType,
          _that.categoryId,
          _that.tags,
          _that.note,
          _that.quantity,
          _that.estimatedPrice,
          _that.completedAt,
          _that.isCompleted,
          _that.sortOrder,
          _that.isSynced,
          _that.isDeleted,
          _that.addedByBookId,
          _that.createdAt,
          _that.updatedAt,
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
      String deviceId,
      String listType,
      String name,
      LedgerType? ledgerType,
      String? categoryId,
      List<String> tags,
      String? note,
      int quantity,
      int? estimatedPrice,
      DateTime? completedAt,
      bool isCompleted,
      int sortOrder,
      bool isSynced,
      bool isDeleted,
      String? addedByBookId,
      DateTime createdAt,
      DateTime? updatedAt,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItem():
        return $default(
          _that.id,
          _that.deviceId,
          _that.listType,
          _that.name,
          _that.ledgerType,
          _that.categoryId,
          _that.tags,
          _that.note,
          _that.quantity,
          _that.estimatedPrice,
          _that.completedAt,
          _that.isCompleted,
          _that.sortOrder,
          _that.isSynced,
          _that.isDeleted,
          _that.addedByBookId,
          _that.createdAt,
          _that.updatedAt,
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
      String deviceId,
      String listType,
      String name,
      LedgerType? ledgerType,
      String? categoryId,
      List<String> tags,
      String? note,
      int quantity,
      int? estimatedPrice,
      DateTime? completedAt,
      bool isCompleted,
      int sortOrder,
      bool isSynced,
      bool isDeleted,
      String? addedByBookId,
      DateTime createdAt,
      DateTime? updatedAt,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ShoppingItem() when $default != null:
        return $default(
          _that.id,
          _that.deviceId,
          _that.listType,
          _that.name,
          _that.ledgerType,
          _that.categoryId,
          _that.tags,
          _that.note,
          _that.quantity,
          _that.estimatedPrice,
          _that.completedAt,
          _that.isCompleted,
          _that.sortOrder,
          _that.isSynced,
          _that.isDeleted,
          _that.addedByBookId,
          _that.createdAt,
          _that.updatedAt,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc

class _ShoppingItem extends ShoppingItem {
  const _ShoppingItem({
    required this.id,
    required this.deviceId,
    required this.listType,
    required this.name,
    this.ledgerType,
    this.categoryId,
    final List<String> tags = const <String>[],
    this.note,
    this.quantity = 1,
    this.estimatedPrice,
    this.completedAt,
    this.isCompleted = false,
    this.sortOrder = 0,
    this.isSynced = false,
    this.isDeleted = false,
    this.addedByBookId,
    required this.createdAt,
    this.updatedAt,
  }) : _tags = tags,
       super._();

  @override
  final String id;
  @override
  final String deviceId;
  @override
  final String listType;
  // 'public' | 'private'
  @override
  final String name;
  @override
  final LedgerType? ledgerType;
  @override
  final String? categoryId;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  // D-01: JSON-encoded at repo boundary
  @override
  final String? note;
  // decrypted plaintext
  @override
  @JsonKey()
  final int quantity;
  // D-02
  @override
  final int? estimatedPrice;
  // ITEM-05
  @override
  final DateTime? completedAt;
  // D-03
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  @JsonKey()
  final int sortOrder;
  @override
  @JsonKey()
  final bool isSynced;
  @override
  @JsonKey()
  final bool isDeleted;
  @override
  final String? addedByBookId;
  @override
  final DateTime createdAt;
  @override
  final DateTime? updatedAt;

  /// Create a copy of ShoppingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ShoppingItemCopyWith<_ShoppingItem> get copyWith =>
      __$ShoppingItemCopyWithImpl<_ShoppingItem>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ShoppingItem &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.listType, listType) ||
                other.listType == listType) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.ledgerType, ledgerType) ||
                other.ledgerType == ledgerType) &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.note, note) || other.note == note) &&
            (identical(other.quantity, quantity) ||
                other.quantity == quantity) &&
            (identical(other.estimatedPrice, estimatedPrice) ||
                other.estimatedPrice == estimatedPrice) &&
            (identical(other.completedAt, completedAt) ||
                other.completedAt == completedAt) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.sortOrder, sortOrder) ||
                other.sortOrder == sortOrder) &&
            (identical(other.isSynced, isSynced) ||
                other.isSynced == isSynced) &&
            (identical(other.isDeleted, isDeleted) ||
                other.isDeleted == isDeleted) &&
            (identical(other.addedByBookId, addedByBookId) ||
                other.addedByBookId == addedByBookId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.updatedAt, updatedAt) ||
                other.updatedAt == updatedAt));
  }

  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    deviceId,
    listType,
    name,
    ledgerType,
    categoryId,
    const DeepCollectionEquality().hash(_tags),
    note,
    quantity,
    estimatedPrice,
    completedAt,
    isCompleted,
    sortOrder,
    isSynced,
    isDeleted,
    addedByBookId,
    createdAt,
    updatedAt,
  );

  @override
  String toString() {
    return 'ShoppingItem(id: $id, deviceId: $deviceId, listType: $listType, name: $name, ledgerType: $ledgerType, categoryId: $categoryId, tags: $tags, note: $note, quantity: $quantity, estimatedPrice: $estimatedPrice, completedAt: $completedAt, isCompleted: $isCompleted, sortOrder: $sortOrder, isSynced: $isSynced, isDeleted: $isDeleted, addedByBookId: $addedByBookId, createdAt: $createdAt, updatedAt: $updatedAt)';
  }
}

/// @nodoc
abstract mixin class _$ShoppingItemCopyWith<$Res>
    implements $ShoppingItemCopyWith<$Res> {
  factory _$ShoppingItemCopyWith(
    _ShoppingItem value,
    $Res Function(_ShoppingItem) _then,
  ) = __$ShoppingItemCopyWithImpl;
  @override
  @useResult
  $Res call({
    String id,
    String deviceId,
    String listType,
    String name,
    LedgerType? ledgerType,
    String? categoryId,
    List<String> tags,
    String? note,
    int quantity,
    int? estimatedPrice,
    DateTime? completedAt,
    bool isCompleted,
    int sortOrder,
    bool isSynced,
    bool isDeleted,
    String? addedByBookId,
    DateTime createdAt,
    DateTime? updatedAt,
  });
}

/// @nodoc
class __$ShoppingItemCopyWithImpl<$Res>
    implements _$ShoppingItemCopyWith<$Res> {
  __$ShoppingItemCopyWithImpl(this._self, this._then);

  final _ShoppingItem _self;
  final $Res Function(_ShoppingItem) _then;

  /// Create a copy of ShoppingItem
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? deviceId = null,
    Object? listType = null,
    Object? name = null,
    Object? ledgerType = freezed,
    Object? categoryId = freezed,
    Object? tags = null,
    Object? note = freezed,
    Object? quantity = null,
    Object? estimatedPrice = freezed,
    Object? completedAt = freezed,
    Object? isCompleted = null,
    Object? sortOrder = null,
    Object? isSynced = null,
    Object? isDeleted = null,
    Object? addedByBookId = freezed,
    Object? createdAt = null,
    Object? updatedAt = freezed,
  }) {
    return _then(
      _ShoppingItem(
        id: null == id
            ? _self.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        listType: null == listType
            ? _self.listType
            : listType // ignore: cast_nullable_to_non_nullable
                  as String,
        name: null == name
            ? _self.name
            : name // ignore: cast_nullable_to_non_nullable
                  as String,
        ledgerType: freezed == ledgerType
            ? _self.ledgerType
            : ledgerType // ignore: cast_nullable_to_non_nullable
                  as LedgerType?,
        categoryId: freezed == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String?,
        tags: null == tags
            ? _self._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        note: freezed == note
            ? _self.note
            : note // ignore: cast_nullable_to_non_nullable
                  as String?,
        quantity: null == quantity
            ? _self.quantity
            : quantity // ignore: cast_nullable_to_non_nullable
                  as int,
        estimatedPrice: freezed == estimatedPrice
            ? _self.estimatedPrice
            : estimatedPrice // ignore: cast_nullable_to_non_nullable
                  as int?,
        completedAt: freezed == completedAt
            ? _self.completedAt
            : completedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
        isCompleted: null == isCompleted
            ? _self.isCompleted
            : isCompleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        sortOrder: null == sortOrder
            ? _self.sortOrder
            : sortOrder // ignore: cast_nullable_to_non_nullable
                  as int,
        isSynced: null == isSynced
            ? _self.isSynced
            : isSynced // ignore: cast_nullable_to_non_nullable
                  as bool,
        isDeleted: null == isDeleted
            ? _self.isDeleted
            : isDeleted // ignore: cast_nullable_to_non_nullable
                  as bool,
        addedByBookId: freezed == addedByBookId
            ? _self.addedByBookId
            : addedByBookId // ignore: cast_nullable_to_non_nullable
                  as String?,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as DateTime,
        updatedAt: freezed == updatedAt
            ? _self.updatedAt
            : updatedAt // ignore: cast_nullable_to_non_nullable
                  as DateTime?,
      ),
    );
  }
}
