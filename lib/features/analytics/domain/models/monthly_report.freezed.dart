// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'monthly_report.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CategoryBreakdown {
  String get categoryId;
  String get categoryName;
  String get icon;
  String get color;
  int get amount;
  double get percentage;
  int get transactionCount;
  int? get budgetAmount;
  double? get budgetProgress;

  /// Create a copy of CategoryBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CategoryBreakdownCopyWith<CategoryBreakdown> get copyWith =>
      _$CategoryBreakdownCopyWithImpl<CategoryBreakdown>(
        this as CategoryBreakdown,
        _$identity,
      );

  /// Serializes this CategoryBreakdown to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CategoryBreakdown &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.budgetAmount, budgetAmount) ||
                other.budgetAmount == budgetAmount) &&
            (identical(other.budgetProgress, budgetProgress) ||
                other.budgetProgress == budgetProgress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryId,
    categoryName,
    icon,
    color,
    amount,
    percentage,
    transactionCount,
    budgetAmount,
    budgetProgress,
  );

  @override
  String toString() {
    return 'CategoryBreakdown(categoryId: $categoryId, categoryName: $categoryName, icon: $icon, color: $color, amount: $amount, percentage: $percentage, transactionCount: $transactionCount, budgetAmount: $budgetAmount, budgetProgress: $budgetProgress)';
  }
}

/// @nodoc
abstract mixin class $CategoryBreakdownCopyWith<$Res> {
  factory $CategoryBreakdownCopyWith(
    CategoryBreakdown value,
    $Res Function(CategoryBreakdown) _then,
  ) = _$CategoryBreakdownCopyWithImpl;
  @useResult
  $Res call({
    String categoryId,
    String categoryName,
    String icon,
    String color,
    int amount,
    double percentage,
    int transactionCount,
    int? budgetAmount,
    double? budgetProgress,
  });
}

/// @nodoc
class _$CategoryBreakdownCopyWithImpl<$Res>
    implements $CategoryBreakdownCopyWith<$Res> {
  _$CategoryBreakdownCopyWithImpl(this._self, this._then);

  final CategoryBreakdown _self;
  final $Res Function(CategoryBreakdown) _then;

  /// Create a copy of CategoryBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? categoryId = null,
    Object? categoryName = null,
    Object? icon = null,
    Object? color = null,
    Object? amount = null,
    Object? percentage = null,
    Object? transactionCount = null,
    Object? budgetAmount = freezed,
    Object? budgetProgress = freezed,
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
        amount: null == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        percentage: null == percentage
            ? _self.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
        transactionCount: null == transactionCount
            ? _self.transactionCount
            : transactionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        budgetAmount: freezed == budgetAmount
            ? _self.budgetAmount
            : budgetAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        budgetProgress: freezed == budgetProgress
            ? _self.budgetProgress
            : budgetProgress // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// Adds pattern-matching-related methods to [CategoryBreakdown].
extension CategoryBreakdownPatterns on CategoryBreakdown {
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
    TResult Function(_CategoryBreakdown value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryBreakdown() when $default != null:
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
    TResult Function(_CategoryBreakdown value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryBreakdown():
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
    TResult? Function(_CategoryBreakdown value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryBreakdown() when $default != null:
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
      int amount,
      double percentage,
      int transactionCount,
      int? budgetAmount,
      double? budgetProgress,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _CategoryBreakdown() when $default != null:
        return $default(
          _that.categoryId,
          _that.categoryName,
          _that.icon,
          _that.color,
          _that.amount,
          _that.percentage,
          _that.transactionCount,
          _that.budgetAmount,
          _that.budgetProgress,
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
      int amount,
      double percentage,
      int transactionCount,
      int? budgetAmount,
      double? budgetProgress,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryBreakdown():
        return $default(
          _that.categoryId,
          _that.categoryName,
          _that.icon,
          _that.color,
          _that.amount,
          _that.percentage,
          _that.transactionCount,
          _that.budgetAmount,
          _that.budgetProgress,
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
      int amount,
      double percentage,
      int transactionCount,
      int? budgetAmount,
      double? budgetProgress,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _CategoryBreakdown() when $default != null:
        return $default(
          _that.categoryId,
          _that.categoryName,
          _that.icon,
          _that.color,
          _that.amount,
          _that.percentage,
          _that.transactionCount,
          _that.budgetAmount,
          _that.budgetProgress,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _CategoryBreakdown implements CategoryBreakdown {
  const _CategoryBreakdown({
    required this.categoryId,
    required this.categoryName,
    required this.icon,
    required this.color,
    required this.amount,
    required this.percentage,
    required this.transactionCount,
    this.budgetAmount,
    this.budgetProgress,
  });
  factory _CategoryBreakdown.fromJson(Map<String, dynamic> json) =>
      _$CategoryBreakdownFromJson(json);

  @override
  final String categoryId;
  @override
  final String categoryName;
  @override
  final String icon;
  @override
  final String color;
  @override
  final int amount;
  @override
  final double percentage;
  @override
  final int transactionCount;
  @override
  final int? budgetAmount;
  @override
  final double? budgetProgress;

  /// Create a copy of CategoryBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CategoryBreakdownCopyWith<_CategoryBreakdown> get copyWith =>
      __$CategoryBreakdownCopyWithImpl<_CategoryBreakdown>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$CategoryBreakdownToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CategoryBreakdown &&
            (identical(other.categoryId, categoryId) ||
                other.categoryId == categoryId) &&
            (identical(other.categoryName, categoryName) ||
                other.categoryName == categoryName) &&
            (identical(other.icon, icon) || other.icon == icon) &&
            (identical(other.color, color) || other.color == color) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.transactionCount, transactionCount) ||
                other.transactionCount == transactionCount) &&
            (identical(other.budgetAmount, budgetAmount) ||
                other.budgetAmount == budgetAmount) &&
            (identical(other.budgetProgress, budgetProgress) ||
                other.budgetProgress == budgetProgress));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    categoryId,
    categoryName,
    icon,
    color,
    amount,
    percentage,
    transactionCount,
    budgetAmount,
    budgetProgress,
  );

  @override
  String toString() {
    return 'CategoryBreakdown(categoryId: $categoryId, categoryName: $categoryName, icon: $icon, color: $color, amount: $amount, percentage: $percentage, transactionCount: $transactionCount, budgetAmount: $budgetAmount, budgetProgress: $budgetProgress)';
  }
}

/// @nodoc
abstract mixin class _$CategoryBreakdownCopyWith<$Res>
    implements $CategoryBreakdownCopyWith<$Res> {
  factory _$CategoryBreakdownCopyWith(
    _CategoryBreakdown value,
    $Res Function(_CategoryBreakdown) _then,
  ) = __$CategoryBreakdownCopyWithImpl;
  @override
  @useResult
  $Res call({
    String categoryId,
    String categoryName,
    String icon,
    String color,
    int amount,
    double percentage,
    int transactionCount,
    int? budgetAmount,
    double? budgetProgress,
  });
}

/// @nodoc
class __$CategoryBreakdownCopyWithImpl<$Res>
    implements _$CategoryBreakdownCopyWith<$Res> {
  __$CategoryBreakdownCopyWithImpl(this._self, this._then);

  final _CategoryBreakdown _self;
  final $Res Function(_CategoryBreakdown) _then;

  /// Create a copy of CategoryBreakdown
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? categoryId = null,
    Object? categoryName = null,
    Object? icon = null,
    Object? color = null,
    Object? amount = null,
    Object? percentage = null,
    Object? transactionCount = null,
    Object? budgetAmount = freezed,
    Object? budgetProgress = freezed,
  }) {
    return _then(
      _CategoryBreakdown(
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
        amount: null == amount
            ? _self.amount
            : amount // ignore: cast_nullable_to_non_nullable
                  as int,
        percentage: null == percentage
            ? _self.percentage
            : percentage // ignore: cast_nullable_to_non_nullable
                  as double,
        transactionCount: null == transactionCount
            ? _self.transactionCount
            : transactionCount // ignore: cast_nullable_to_non_nullable
                  as int,
        budgetAmount: freezed == budgetAmount
            ? _self.budgetAmount
            : budgetAmount // ignore: cast_nullable_to_non_nullable
                  as int?,
        budgetProgress: freezed == budgetProgress
            ? _self.budgetProgress
            : budgetProgress // ignore: cast_nullable_to_non_nullable
                  as double?,
      ),
    );
  }
}

/// @nodoc
mixin _$MonthlyReport {
  int get year;
  int get month;
  int get totalIncome;
  int get totalExpenses;
  int get savings;
  double get savingsRate;
  int get survivalTotal;
  int get soulTotal;
  List<CategoryBreakdown> get categoryBreakdowns;
  List<DailyExpense> get dailyExpenses;
  MonthComparison? get previousMonthComparison;

  /// Create a copy of MonthlyReport
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $MonthlyReportCopyWith<MonthlyReport> get copyWith =>
      _$MonthlyReportCopyWithImpl<MonthlyReport>(
        this as MonthlyReport,
        _$identity,
      );

  /// Serializes this MonthlyReport to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is MonthlyReport &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.savings, savings) || other.savings == savings) &&
            (identical(other.savingsRate, savingsRate) ||
                other.savingsRate == savingsRate) &&
            (identical(other.survivalTotal, survivalTotal) ||
                other.survivalTotal == survivalTotal) &&
            (identical(other.soulTotal, soulTotal) ||
                other.soulTotal == soulTotal) &&
            const DeepCollectionEquality().equals(
              other.categoryBreakdowns,
              categoryBreakdowns,
            ) &&
            const DeepCollectionEquality().equals(
              other.dailyExpenses,
              dailyExpenses,
            ) &&
            (identical(
                  other.previousMonthComparison,
                  previousMonthComparison,
                ) ||
                other.previousMonthComparison == previousMonthComparison));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    totalIncome,
    totalExpenses,
    savings,
    savingsRate,
    survivalTotal,
    soulTotal,
    const DeepCollectionEquality().hash(categoryBreakdowns),
    const DeepCollectionEquality().hash(dailyExpenses),
    previousMonthComparison,
  );

  @override
  String toString() {
    return 'MonthlyReport(year: $year, month: $month, totalIncome: $totalIncome, totalExpenses: $totalExpenses, savings: $savings, savingsRate: $savingsRate, survivalTotal: $survivalTotal, soulTotal: $soulTotal, categoryBreakdowns: $categoryBreakdowns, dailyExpenses: $dailyExpenses, previousMonthComparison: $previousMonthComparison)';
  }
}

/// @nodoc
abstract mixin class $MonthlyReportCopyWith<$Res> {
  factory $MonthlyReportCopyWith(
    MonthlyReport value,
    $Res Function(MonthlyReport) _then,
  ) = _$MonthlyReportCopyWithImpl;
  @useResult
  $Res call({
    int year,
    int month,
    int totalIncome,
    int totalExpenses,
    int savings,
    double savingsRate,
    int survivalTotal,
    int soulTotal,
    List<CategoryBreakdown> categoryBreakdowns,
    List<DailyExpense> dailyExpenses,
    MonthComparison? previousMonthComparison,
  });

  $MonthComparisonCopyWith<$Res>? get previousMonthComparison;
}

/// @nodoc
class _$MonthlyReportCopyWithImpl<$Res>
    implements $MonthlyReportCopyWith<$Res> {
  _$MonthlyReportCopyWithImpl(this._self, this._then);

  final MonthlyReport _self;
  final $Res Function(MonthlyReport) _then;

  /// Create a copy of MonthlyReport
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? savings = null,
    Object? savingsRate = null,
    Object? survivalTotal = null,
    Object? soulTotal = null,
    Object? categoryBreakdowns = null,
    Object? dailyExpenses = null,
    Object? previousMonthComparison = freezed,
  }) {
    return _then(
      _self.copyWith(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        totalIncome: null == totalIncome
            ? _self.totalIncome
            : totalIncome // ignore: cast_nullable_to_non_nullable
                  as int,
        totalExpenses: null == totalExpenses
            ? _self.totalExpenses
            : totalExpenses // ignore: cast_nullable_to_non_nullable
                  as int,
        savings: null == savings
            ? _self.savings
            : savings // ignore: cast_nullable_to_non_nullable
                  as int,
        savingsRate: null == savingsRate
            ? _self.savingsRate
            : savingsRate // ignore: cast_nullable_to_non_nullable
                  as double,
        survivalTotal: null == survivalTotal
            ? _self.survivalTotal
            : survivalTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        soulTotal: null == soulTotal
            ? _self.soulTotal
            : soulTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryBreakdowns: null == categoryBreakdowns
            ? _self.categoryBreakdowns
            : categoryBreakdowns // ignore: cast_nullable_to_non_nullable
                  as List<CategoryBreakdown>,
        dailyExpenses: null == dailyExpenses
            ? _self.dailyExpenses
            : dailyExpenses // ignore: cast_nullable_to_non_nullable
                  as List<DailyExpense>,
        previousMonthComparison: freezed == previousMonthComparison
            ? _self.previousMonthComparison
            : previousMonthComparison // ignore: cast_nullable_to_non_nullable
                  as MonthComparison?,
      ),
    );
  }

  /// Create a copy of MonthlyReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MonthComparisonCopyWith<$Res>? get previousMonthComparison {
    if (_self.previousMonthComparison == null) {
      return null;
    }

    return $MonthComparisonCopyWith<$Res>(_self.previousMonthComparison!, (
      value,
    ) {
      return _then(_self.copyWith(previousMonthComparison: value));
    });
  }
}

/// Adds pattern-matching-related methods to [MonthlyReport].
extension MonthlyReportPatterns on MonthlyReport {
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
    TResult Function(_MonthlyReport value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MonthlyReport() when $default != null:
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
    TResult Function(_MonthlyReport value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyReport():
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
    TResult? Function(_MonthlyReport value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyReport() when $default != null:
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
      int year,
      int month,
      int totalIncome,
      int totalExpenses,
      int savings,
      double savingsRate,
      int survivalTotal,
      int soulTotal,
      List<CategoryBreakdown> categoryBreakdowns,
      List<DailyExpense> dailyExpenses,
      MonthComparison? previousMonthComparison,
    )?
    $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _MonthlyReport() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.totalIncome,
          _that.totalExpenses,
          _that.savings,
          _that.savingsRate,
          _that.survivalTotal,
          _that.soulTotal,
          _that.categoryBreakdowns,
          _that.dailyExpenses,
          _that.previousMonthComparison,
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
      int year,
      int month,
      int totalIncome,
      int totalExpenses,
      int savings,
      double savingsRate,
      int survivalTotal,
      int soulTotal,
      List<CategoryBreakdown> categoryBreakdowns,
      List<DailyExpense> dailyExpenses,
      MonthComparison? previousMonthComparison,
    )
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyReport():
        return $default(
          _that.year,
          _that.month,
          _that.totalIncome,
          _that.totalExpenses,
          _that.savings,
          _that.savingsRate,
          _that.survivalTotal,
          _that.soulTotal,
          _that.categoryBreakdowns,
          _that.dailyExpenses,
          _that.previousMonthComparison,
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
      int year,
      int month,
      int totalIncome,
      int totalExpenses,
      int savings,
      double savingsRate,
      int survivalTotal,
      int soulTotal,
      List<CategoryBreakdown> categoryBreakdowns,
      List<DailyExpense> dailyExpenses,
      MonthComparison? previousMonthComparison,
    )?
    $default,
  ) {
    final _that = this;
    switch (_that) {
      case _MonthlyReport() when $default != null:
        return $default(
          _that.year,
          _that.month,
          _that.totalIncome,
          _that.totalExpenses,
          _that.savings,
          _that.savingsRate,
          _that.survivalTotal,
          _that.soulTotal,
          _that.categoryBreakdowns,
          _that.dailyExpenses,
          _that.previousMonthComparison,
        );
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _MonthlyReport implements MonthlyReport {
  const _MonthlyReport({
    required this.year,
    required this.month,
    required this.totalIncome,
    required this.totalExpenses,
    required this.savings,
    required this.savingsRate,
    required this.survivalTotal,
    required this.soulTotal,
    required final List<CategoryBreakdown> categoryBreakdowns,
    required final List<DailyExpense> dailyExpenses,
    this.previousMonthComparison,
  }) : _categoryBreakdowns = categoryBreakdowns,
       _dailyExpenses = dailyExpenses;
  factory _MonthlyReport.fromJson(Map<String, dynamic> json) =>
      _$MonthlyReportFromJson(json);

  @override
  final int year;
  @override
  final int month;
  @override
  final int totalIncome;
  @override
  final int totalExpenses;
  @override
  final int savings;
  @override
  final double savingsRate;
  @override
  final int survivalTotal;
  @override
  final int soulTotal;
  final List<CategoryBreakdown> _categoryBreakdowns;
  @override
  List<CategoryBreakdown> get categoryBreakdowns {
    if (_categoryBreakdowns is EqualUnmodifiableListView)
      return _categoryBreakdowns;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_categoryBreakdowns);
  }

  final List<DailyExpense> _dailyExpenses;
  @override
  List<DailyExpense> get dailyExpenses {
    if (_dailyExpenses is EqualUnmodifiableListView) return _dailyExpenses;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_dailyExpenses);
  }

  @override
  final MonthComparison? previousMonthComparison;

  /// Create a copy of MonthlyReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$MonthlyReportCopyWith<_MonthlyReport> get copyWith =>
      __$MonthlyReportCopyWithImpl<_MonthlyReport>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$MonthlyReportToJson(this);
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _MonthlyReport &&
            (identical(other.year, year) || other.year == year) &&
            (identical(other.month, month) || other.month == month) &&
            (identical(other.totalIncome, totalIncome) ||
                other.totalIncome == totalIncome) &&
            (identical(other.totalExpenses, totalExpenses) ||
                other.totalExpenses == totalExpenses) &&
            (identical(other.savings, savings) || other.savings == savings) &&
            (identical(other.savingsRate, savingsRate) ||
                other.savingsRate == savingsRate) &&
            (identical(other.survivalTotal, survivalTotal) ||
                other.survivalTotal == survivalTotal) &&
            (identical(other.soulTotal, soulTotal) ||
                other.soulTotal == soulTotal) &&
            const DeepCollectionEquality().equals(
              other._categoryBreakdowns,
              _categoryBreakdowns,
            ) &&
            const DeepCollectionEquality().equals(
              other._dailyExpenses,
              _dailyExpenses,
            ) &&
            (identical(
                  other.previousMonthComparison,
                  previousMonthComparison,
                ) ||
                other.previousMonthComparison == previousMonthComparison));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    year,
    month,
    totalIncome,
    totalExpenses,
    savings,
    savingsRate,
    survivalTotal,
    soulTotal,
    const DeepCollectionEquality().hash(_categoryBreakdowns),
    const DeepCollectionEquality().hash(_dailyExpenses),
    previousMonthComparison,
  );

  @override
  String toString() {
    return 'MonthlyReport(year: $year, month: $month, totalIncome: $totalIncome, totalExpenses: $totalExpenses, savings: $savings, savingsRate: $savingsRate, survivalTotal: $survivalTotal, soulTotal: $soulTotal, categoryBreakdowns: $categoryBreakdowns, dailyExpenses: $dailyExpenses, previousMonthComparison: $previousMonthComparison)';
  }
}

/// @nodoc
abstract mixin class _$MonthlyReportCopyWith<$Res>
    implements $MonthlyReportCopyWith<$Res> {
  factory _$MonthlyReportCopyWith(
    _MonthlyReport value,
    $Res Function(_MonthlyReport) _then,
  ) = __$MonthlyReportCopyWithImpl;
  @override
  @useResult
  $Res call({
    int year,
    int month,
    int totalIncome,
    int totalExpenses,
    int savings,
    double savingsRate,
    int survivalTotal,
    int soulTotal,
    List<CategoryBreakdown> categoryBreakdowns,
    List<DailyExpense> dailyExpenses,
    MonthComparison? previousMonthComparison,
  });

  @override
  $MonthComparisonCopyWith<$Res>? get previousMonthComparison;
}

/// @nodoc
class __$MonthlyReportCopyWithImpl<$Res>
    implements _$MonthlyReportCopyWith<$Res> {
  __$MonthlyReportCopyWithImpl(this._self, this._then);

  final _MonthlyReport _self;
  final $Res Function(_MonthlyReport) _then;

  /// Create a copy of MonthlyReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? year = null,
    Object? month = null,
    Object? totalIncome = null,
    Object? totalExpenses = null,
    Object? savings = null,
    Object? savingsRate = null,
    Object? survivalTotal = null,
    Object? soulTotal = null,
    Object? categoryBreakdowns = null,
    Object? dailyExpenses = null,
    Object? previousMonthComparison = freezed,
  }) {
    return _then(
      _MonthlyReport(
        year: null == year
            ? _self.year
            : year // ignore: cast_nullable_to_non_nullable
                  as int,
        month: null == month
            ? _self.month
            : month // ignore: cast_nullable_to_non_nullable
                  as int,
        totalIncome: null == totalIncome
            ? _self.totalIncome
            : totalIncome // ignore: cast_nullable_to_non_nullable
                  as int,
        totalExpenses: null == totalExpenses
            ? _self.totalExpenses
            : totalExpenses // ignore: cast_nullable_to_non_nullable
                  as int,
        savings: null == savings
            ? _self.savings
            : savings // ignore: cast_nullable_to_non_nullable
                  as int,
        savingsRate: null == savingsRate
            ? _self.savingsRate
            : savingsRate // ignore: cast_nullable_to_non_nullable
                  as double,
        survivalTotal: null == survivalTotal
            ? _self.survivalTotal
            : survivalTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        soulTotal: null == soulTotal
            ? _self.soulTotal
            : soulTotal // ignore: cast_nullable_to_non_nullable
                  as int,
        categoryBreakdowns: null == categoryBreakdowns
            ? _self._categoryBreakdowns
            : categoryBreakdowns // ignore: cast_nullable_to_non_nullable
                  as List<CategoryBreakdown>,
        dailyExpenses: null == dailyExpenses
            ? _self._dailyExpenses
            : dailyExpenses // ignore: cast_nullable_to_non_nullable
                  as List<DailyExpense>,
        previousMonthComparison: freezed == previousMonthComparison
            ? _self.previousMonthComparison
            : previousMonthComparison // ignore: cast_nullable_to_non_nullable
                  as MonthComparison?,
      ),
    );
  }

  /// Create a copy of MonthlyReport
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $MonthComparisonCopyWith<$Res>? get previousMonthComparison {
    if (_self.previousMonthComparison == null) {
      return null;
    }

    return $MonthComparisonCopyWith<$Res>(_self.previousMonthComparison!, (
      value,
    ) {
      return _then(_self.copyWith(previousMonthComparison: value));
    });
  }
}
