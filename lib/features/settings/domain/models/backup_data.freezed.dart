// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'backup_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BackupData {
  BackupMetadata get metadata;
  List<Map<String, dynamic>> get transactions;
  List<Map<String, dynamic>> get categories;
  List<Map<String, dynamic>> get books;
  Map<String, dynamic> get settings;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupDataCopyWith<BackupData> get copyWith =>
      _$BackupDataCopyWithImpl<BackupData>(this as BackupData, _$identity);

  /// Serializes this BackupData to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupData &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality().equals(
              other.transactions,
              transactions,
            ) &&
            const DeepCollectionEquality().equals(
              other.categories,
              categories,
            ) &&
            const DeepCollectionEquality().equals(other.books, books) &&
            const DeepCollectionEquality().equals(other.settings, settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    metadata,
    const DeepCollectionEquality().hash(transactions),
    const DeepCollectionEquality().hash(categories),
    const DeepCollectionEquality().hash(books),
    const DeepCollectionEquality().hash(settings),
  );

  @override
  String toString() {
    return 'BackupData(metadata: $metadata, transactions: $transactions, categories: $categories, books: $books, settings: $settings)';
  }
}

/// @nodoc
abstract mixin class $BackupDataCopyWith<$Res> {
  factory $BackupDataCopyWith(
    BackupData value,
    $Res Function(BackupData) _then,
  ) = _$BackupDataCopyWithImpl;
  @useResult
  $Res call({
    BackupMetadata metadata,
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> books,
    Map<String, dynamic> settings,
  });

  $BackupMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class _$BackupDataCopyWithImpl<$Res> implements $BackupDataCopyWith<$Res> {
  _$BackupDataCopyWithImpl(this._self, this._then);

  final BackupData _self;
  final $Res Function(BackupData) _then;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? metadata = null,
    Object? transactions = null,
    Object? categories = null,
    Object? books = null,
    Object? settings = null,
  }) {
    return _then(
      _self.copyWith(
        metadata: null == metadata
            ? _self.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as BackupMetadata,
        transactions: null == transactions
            ? _self.transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        categories: null == categories
            ? _self.categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        books: null == books
            ? _self.books
            : books // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        settings: null == settings
            ? _self.settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// Adds pattern-matching-related methods to [BackupData].
extension BackupDataPatterns on BackupData {
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
    TResult Function(_BackupData value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
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
    TResult Function(_BackupData value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData():
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
    TResult? Function(_BackupData value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
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
      BackupMetadata metadata,
      List<Map<String, dynamic>> transactions,
      List<Map<String, dynamic>> categories,
      List<Map<String, dynamic>> books,
      Map<String, dynamic> settings,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
        return $default(
          _that.metadata,
          _that.transactions,
          _that.categories,
          _that.books,
          _that.settings,
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
      BackupMetadata metadata,
      List<Map<String, dynamic>> transactions,
      List<Map<String, dynamic>> categories,
      List<Map<String, dynamic>> books,
      Map<String, dynamic> settings,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData():
        return $default(
          _that.metadata,
          _that.transactions,
          _that.categories,
          _that.books,
          _that.settings,
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
      BackupMetadata metadata,
      List<Map<String, dynamic>> transactions,
      List<Map<String, dynamic>> categories,
      List<Map<String, dynamic>> books,
      Map<String, dynamic> settings,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupData() when $default != null:
        return $default(
          _that.metadata,
          _that.transactions,
          _that.categories,
          _that.books,
          _that.settings,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BackupData implements BackupData {
  const _BackupData({
    required this.metadata,
    required final List<Map<String, dynamic>> transactions,
    required final List<Map<String, dynamic>> categories,
    required final List<Map<String, dynamic>> books,
    required final Map<String, dynamic> settings,
  }) : _transactions = transactions,
       _categories = categories,
       _books = books,
       _settings = settings;
  factory _BackupData.fromJson(Map<String, dynamic> json) =>
      _$BackupDataFromJson(json);

  @override
  final BackupMetadata metadata;
  final List<Map<String, dynamic>> _transactions;
  @override
  List<Map<String, dynamic>> get transactions {
    if (_transactions is EqualUnmodifiableListView) return _transactions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_transactions);
  }

  final List<Map<String, dynamic>> _categories;
  @override
  List<Map<String, dynamic>> get categories {
    if (_categories is EqualUnmodifiableListView) return _categories;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categories);
  }

  final List<Map<String, dynamic>> _books;
  @override
  List<Map<String, dynamic>> get books {
    if (_books is EqualUnmodifiableListView) return _books;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_books);
  }

  final Map<String, dynamic> _settings;
  @override
  Map<String, dynamic> get settings {
    if (_settings is EqualUnmodifiableMapView) return _settings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableMapView(_settings);
  }

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupDataCopyWith<_BackupData> get copyWith =>
      __$BackupDataCopyWithImpl<_BackupData>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BackupDataToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupData &&
            (identical(other.metadata, metadata) ||
                other.metadata == metadata) &&
            const DeepCollectionEquality().equals(
              other._transactions,
              _transactions,
            ) &&
            const DeepCollectionEquality().equals(
              other._categories,
              _categories,
            ) &&
            const DeepCollectionEquality().equals(other._books, _books) &&
            const DeepCollectionEquality().equals(other._settings, _settings));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    metadata,
    const DeepCollectionEquality().hash(_transactions),
    const DeepCollectionEquality().hash(_categories),
    const DeepCollectionEquality().hash(_books),
    const DeepCollectionEquality().hash(_settings),
  );

  @override
  String toString() {
    return 'BackupData(metadata: $metadata, transactions: $transactions, categories: $categories, books: $books, settings: $settings)';
  }
}

/// @nodoc
abstract mixin class _$BackupDataCopyWith<$Res>
    implements $BackupDataCopyWith<$Res> {
  factory _$BackupDataCopyWith(
    _BackupData value,
    $Res Function(_BackupData) _then,
  ) = __$BackupDataCopyWithImpl;
  @override
  @useResult
  $Res call({
    BackupMetadata metadata,
    List<Map<String, dynamic>> transactions,
    List<Map<String, dynamic>> categories,
    List<Map<String, dynamic>> books,
    Map<String, dynamic> settings,
  });

  @override
  $BackupMetadataCopyWith<$Res> get metadata;
}

/// @nodoc
class __$BackupDataCopyWithImpl<$Res> implements _$BackupDataCopyWith<$Res> {
  __$BackupDataCopyWithImpl(this._self, this._then);

  final _BackupData _self;
  final $Res Function(_BackupData) _then;

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? metadata = null,
    Object? transactions = null,
    Object? categories = null,
    Object? books = null,
    Object? settings = null,
  }) {
    return _then(
      _BackupData(
        metadata: null == metadata
            ? _self.metadata
            : metadata // ignore: cast_nullable_to_non_nullable
                  as BackupMetadata,
        transactions: null == transactions
            ? _self._transactions
            : transactions // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        categories: null == categories
            ? _self._categories
            : categories // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        books: null == books
            ? _self._books
            : books // ignore: cast_nullable_to_non_nullable
                  as List<Map<String, dynamic>>,
        settings: null == settings
            ? _self._settings
            : settings // ignore: cast_nullable_to_non_nullable
                  as Map<String, dynamic>,
      ),
    );
  }

  /// Create a copy of BackupData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<$Res> get metadata {
    return $BackupMetadataCopyWith<$Res>(_self.metadata, (value) {
      return _then(_self.copyWith(metadata: value));
    });
  }
}

/// @nodoc
mixin _$BackupMetadata {
  String get version;
  int get createdAt;
  String get deviceId;
  String get appVersion;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BackupMetadataCopyWith<BackupMetadata> get copyWith =>
      _$BackupMetadataCopyWithImpl<BackupMetadata>(
        this as BackupMetadata,
        _$identity,
      );

  /// Serializes this BackupMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BackupMetadata &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, version, createdAt, deviceId, appVersion);

  @override
  String toString() {
    return 'BackupMetadata(version: $version, createdAt: $createdAt, deviceId: $deviceId, appVersion: $appVersion)';
  }
}

/// @nodoc
abstract mixin class $BackupMetadataCopyWith<$Res> {
  factory $BackupMetadataCopyWith(
    BackupMetadata value,
    $Res Function(BackupMetadata) _then,
  ) = _$BackupMetadataCopyWithImpl;
  @useResult
  $Res call({
    String version,
    int createdAt,
    String deviceId,
    String appVersion,
  });
}

/// @nodoc
class _$BackupMetadataCopyWithImpl<$Res>
    implements $BackupMetadataCopyWith<$Res> {
  _$BackupMetadataCopyWithImpl(this._self, this._then);

  final BackupMetadata _self;
  final $Res Function(BackupMetadata) _then;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? version = null,
    Object? createdAt = null,
    Object? deviceId = null,
    Object? appVersion = null,
  }) {
    return _then(
      _self.copyWith(
        version: null == version
            ? _self.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        appVersion: null == appVersion
            ? _self.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [BackupMetadata].
extension BackupMetadataPatterns on BackupMetadata {
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
    TResult Function(_BackupMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
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
    TResult Function(_BackupMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata():
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
    TResult? Function(_BackupMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
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
      String version,
      int createdAt,
      String deviceId,
      String appVersion,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
        return $default(
          _that.version,
          _that.createdAt,
          _that.deviceId,
          _that.appVersion,
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
      String version,
      int createdAt,
      String deviceId,
      String appVersion,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata():
        return $default(
          _that.version,
          _that.createdAt,
          _that.deviceId,
          _that.appVersion,
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
      String version,
      int createdAt,
      String deviceId,
      String appVersion,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BackupMetadata() when $default != null:
        return $default(
          _that.version,
          _that.createdAt,
          _that.deviceId,
          _that.appVersion,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BackupMetadata implements BackupMetadata {
  const _BackupMetadata({
    required this.version,
    required this.createdAt,
    required this.deviceId,
    required this.appVersion,
  });
  factory _BackupMetadata.fromJson(Map<String, dynamic> json) =>
      _$BackupMetadataFromJson(json);

  @override
  final String version;
  @override
  final int createdAt;
  @override
  final String deviceId;
  @override
  final String appVersion;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BackupMetadataCopyWith<_BackupMetadata> get copyWith =>
      __$BackupMetadataCopyWithImpl<_BackupMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BackupMetadataToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BackupMetadata &&
            (identical(other.version, version) || other.version == version) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt) &&
            (identical(other.deviceId, deviceId) ||
                other.deviceId == deviceId) &&
            (identical(other.appVersion, appVersion) ||
                other.appVersion == appVersion));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, version, createdAt, deviceId, appVersion);

  @override
  String toString() {
    return 'BackupMetadata(version: $version, createdAt: $createdAt, deviceId: $deviceId, appVersion: $appVersion)';
  }
}

/// @nodoc
abstract mixin class _$BackupMetadataCopyWith<$Res>
    implements $BackupMetadataCopyWith<$Res> {
  factory _$BackupMetadataCopyWith(
    _BackupMetadata value,
    $Res Function(_BackupMetadata) _then,
  ) = __$BackupMetadataCopyWithImpl;
  @override
  @useResult
  $Res call({
    String version,
    int createdAt,
    String deviceId,
    String appVersion,
  });
}

/// @nodoc
class __$BackupMetadataCopyWithImpl<$Res>
    implements _$BackupMetadataCopyWith<$Res> {
  __$BackupMetadataCopyWithImpl(this._self, this._then);

  final _BackupMetadata _self;
  final $Res Function(_BackupMetadata) _then;

  /// Create a copy of BackupMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? version = null,
    Object? createdAt = null,
    Object? deviceId = null,
    Object? appVersion = null,
  }) {
    return _then(
      _BackupMetadata(
        version: null == version
            ? _self.version
            : version // ignore: cast_nullable_to_non_nullable
                  as String,
        createdAt: null == createdAt
            ? _self.createdAt
            : createdAt // ignore: cast_nullable_to_non_nullable
                  as int,
        deviceId: null == deviceId
            ? _self.deviceId
            : deviceId // ignore: cast_nullable_to_non_nullable
                  as String,
        appVersion: null == appVersion
            ? _self.appVersion
            : appVersion // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}
