// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'budget_progress.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BudgetProgress {
  String get categoryId;
  String get categoryName;
  String get icon;
  String get color;
  int get budgetAmount;
  int get spentAmount;
  double get percentage;
  BudgetStatus get status;
  int get remainingAmount;

  /// Create a copy of BudgetProgress
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BudgetProgressCopyWith<BudgetProgress> get copyWith =>
      _$BudgetProgressCopyWithImpl<BudgetProgress>(
        this as BudgetProgress,
        _$identity,
      );

  /// Serializes this BudgetProgress to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BudgetProgress &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.budgetAmount, budgetAmount) ||
                other.budgetAmount == budgetAmount) &&
            (identical(other.spentAmount, spentAmount) ||
                other.spentAmount == spentAmount) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.remainingAmount, remainingAmount) ||
                other.remainingAmount == remainingAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryId,
    categoryName,
    icon,
    color,
    budgetAmount,
    spentAmount,
    percentage,
    status,
    remainingAmount,
  );

  @override
  String toString() {
    return 'BudgetProgress(categoryId: $categoryId, categoryName: $categoryName, icon: $icon, color: $color, budgetAmount: $budgetAmount, spentAmount: $spentAmount, percentage: $percentage, status: $status, remainingAmount: $remainingAmount)';
  }
}

/// @nodoc
abstract mixin class $BudgetProgressCopyWith<$Res> {
  factory $BudgetProgressCopyWith(
    BudgetProgress value,
    $Res Function(BudgetProgress) _then,
  ) = _$BudgetProgressCopyWithImpl;
  @useResult
  $Res call({
    String categoryId,
    String categoryName,
    String icon,
    String color,
    int budgetAmount,
    int spentAmount,
    double percentage,
    BudgetStatus status,
    int remainingAmount,
  });
}

/// @nodoc
class _$BudgetProgressCopyWithImpl<$Res>
    implements $BudgetProgressCopyWith<$Res> {
  _$BudgetProgressCopyWithImpl(this._self, this._then);

  final BudgetProgress _self;
  final $Res Function(BudgetProgress) _then;

  /// Create a copy of BudgetProgress
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? categoryName = null,
    Object? icon = null,
    Object? color = null,
    Object? budgetAmount = null,
    Object? spentAmount = null,
    Object? percentage = null,
    Object? status = null,
    Object? remainingAmount = null,
  }) {
    return _then(
      _self.copyWith(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryName: null == categoryName
            ? _self.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _self.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _self.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        budgetAmount: null == budgetAmount
            ? _self.budgetAmount
            : budgetAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        spentAmount: null == spentAmount
            ? _self.spentAmount
            : spentAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        percentage: null == percentage
            ? _self.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BudgetStatus,
        remainingAmount: null == remainingAmount
            ? _self.remainingAmount
            : remainingAmount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [BudgetProgress].
extension BudgetProgressPatterns on BudgetProgress {
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
    TResult Function(_BudgetProgress value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BudgetProgress() when $default != null:
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
    TResult Function(_BudgetProgress value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BudgetProgress():
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
    TResult? Function(_BudgetProgress value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BudgetProgress() when $default != null:
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
      String categoryId,
      String categoryName,
      String icon,
      String color,
      int budgetAmount,
      int spentAmount,
      double percentage,
      BudgetStatus status,
      int remainingAmount,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BudgetProgress() when $default != null:
        return $default(
          _that.categoryId,
          _that.categoryName,
          _that.icon,
          _that.color,
          _that.budgetAmount,
          _that.spentAmount,
          _that.percentage,
          _that.status,
          _that.remainingAmount,
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
      String categoryId,
      String categoryName,
      String icon,
      String color,
      int budgetAmount,
      int spentAmount,
      double percentage,
      BudgetStatus status,
      int remainingAmount,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BudgetProgress():
        return $default(
          _that.categoryId,
          _that.categoryName,
          _that.icon,
          _that.color,
          _that.budgetAmount,
          _that.spentAmount,
          _that.percentage,
          _that.status,
          _that.remainingAmount,
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
      String categoryId,
      String categoryName,
      String icon,
      String color,
      int budgetAmount,
      int spentAmount,
      double percentage,
      BudgetStatus status,
      int remainingAmount,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BudgetProgress() when $default != null:
        return $default(
          _that.categoryId,
          _that.categoryName,
          _that.icon,
          _that.color,
          _that.budgetAmount,
          _that.spentAmount,
          _that.percentage,
          _that.status,
          _that.remainingAmount,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BudgetProgress implements BudgetProgress {
  const _BudgetProgress({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.budgetAmount,
    required this.spentAmount,
    required this.percentage,
    required this.status,
    required this.remainingAmount,
  });
  factory _BudgetProgress.fromJson(Map<String, dynamic> json) =>
      _$BudgetProgressFromJson(json);

  @override
  final String categoryId;
  @override
  final String categoryName;
  @override
  final String icon;
  @override
  final String color;
  @override
  final int budgetAmount;
  @override
  final int spentAmount;
  @override
  final double percentage;
  @override
  final BudgetStatus status;
  @override
  final int remainingAmount;

  /// Create a copy of BudgetProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BudgetProgressCopyWith<_BudgetProgress> get copyWith =>
      __$BudgetProgressCopyWithImpl<_BudgetProgress>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BudgetProgressToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BudgetProgress &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.budgetAmount, budgetAmount) ||
                other.budgetAmount == budgetAmount) &&
            (identical(other.spentAmount, spentAmount) ||
                other.spentAmount == spentAmount) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.status, status) || other.status == status) &&
            (identical(other.remainingAmount, remainingAmount) ||
                other.remainingAmount == remainingAmount));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryId,
    categoryName,
    icon,
    color,
    budgetAmount,
    spentAmount,
    percentage,
    status,
    remainingAmount,
  );

  @override
  String toString() {
    return 'BudgetProgress(categoryId: $categoryId, categoryName: $categoryName, icon: $icon, color: $color, budgetAmount: $budgetAmount, spentAmount: $spentAmount, percentage: $percentage, status: $status, remainingAmount: $remainingAmount)';
  }
}

/// @nodoc
abstract mixin class _$BudgetProgressCopyWith<$Res>
    implements $BudgetProgressCopyWith<$Res> {
  factory _$BudgetProgressCopyWith(
    _BudgetProgress value,
    $Res Function(_BudgetProgress) _then,
  ) = __$BudgetProgressCopyWithImpl;
  @override
  @useResult
  $Res call({
    String categoryId,
    String categoryName,
    String icon,
    String color,
    int budgetAmount,
    int spentAmount,
    double percentage,
    BudgetStatus status,
    int remainingAmount,
  });
}

/// @nodoc
class __$BudgetProgressCopyWithImpl<$Res>
    implements _$BudgetProgressCopyWith<$Res> {
  __$BudgetProgressCopyWithImpl(this._self, this._then);

  final _BudgetProgress _self;
  final $Res Function(_BudgetProgress) _then;

  /// Create a copy of BudgetProgress
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? categoryName = null,
    Object? icon = null,
    Object? color = null,
    Object? budgetAmount = null,
    Object? spentAmount = null,
    Object? percentage = null,
    Object? status = null,
    Object? remainingAmount = null,
  }) {
    return _then(
      _BudgetProgress(
        categoryId: null == categoryId
            ? _self.categoryId
            : categoryId // ignore: cast_nullable_to_non_nullable
                  as String,
        categoryName: null == categoryName
            ? _self.categoryName
            : categoryName // ignore: cast_nullable_to_non_nullable
                  as String,
        icon: null == icon
            ? _self.icon
            : icon // ignore: cast_nullable_to_non_nullable
                  as String,
        color: null == color
            ? _self.color
            : color // ignore: cast_nullable_to_non_nullable
                  as String,
        budgetAmount: null == budgetAmount
            ? _self.budgetAmount
            : budgetAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        spentAmount: null == spentAmount
            ? _self.spentAmount
            : spentAmount // ignore: cast_nullable_to_non_nullable
                  as int,
        percentage: null == percentage
            ? _self.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
        status: null == status
            ? _self.status
            : status // ignore: cast_nullable_to_non_nullable
                  as BudgetStatus,
        remainingAmount: null == remainingAmount
            ? _self.remainingAmount
            : remainingAmount // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}
