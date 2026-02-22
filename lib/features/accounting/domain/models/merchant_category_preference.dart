class MerchantCategoryPreference {
  const MerchantCategoryPreference({
    required this.merchantKey,
    required this.preferredCategoryId,
    this.lastOverrideCategoryId,
    required this.overrideStreak,
    required this.updatedAt,
  });

  final String merchantKey;
  final String preferredCategoryId;
  final String? lastOverrideCategoryId;
  final int overrideStreak;
  final DateTime updatedAt;

  MerchantCategoryPreference copyWith({
    String? merchantKey,
    String? preferredCategoryId,
    String? lastOverrideCategoryId,
    bool clearLastOverrideCategoryId = false,
    int? overrideStreak,
    DateTime? updatedAt,
  }) {
    return MerchantCategoryPreference(
      merchantKey: merchantKey ?? this.merchantKey,
      preferredCategoryId: preferredCategoryId ?? this.preferredCategoryId,
      lastOverrideCategoryId: clearLastOverrideCategoryId
          ? null
          : (lastOverrideCategoryId ?? this.lastOverrideCategoryId),
      overrideStreak: overrideStreak ?? this.overrideStreak,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
