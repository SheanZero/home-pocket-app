/// Units supported by shopping-list quantities.
///
/// The enum name is also the stable persistence and sync identifier. Custom
/// units store their user-facing label separately.
enum ShoppingUnit {
  piece,
  gram,
  kilogram,
  milliliter,
  liter,
  bag,
  bottle,
  pack,
  custom;

  static ShoppingUnit fromId(String? id) => ShoppingUnit.values.firstWhere(
    (value) => value.name == id,
    orElse: () => ShoppingUnit.piece,
  );
}

/// A concrete unit choice, including the label for a custom unit.
class ShoppingUnitSelection {
  const ShoppingUnitSelection(this.unit, {this.customLabel});

  const ShoppingUnitSelection.piece()
    : unit = ShoppingUnit.piece,
      customLabel = null;

  final ShoppingUnit unit;
  final String? customLabel;

  /// Canonical key used by the local frequency table.
  String get usageKey {
    if (unit != ShoppingUnit.custom) return unit.name;
    return 'custom:${normalizedCustomLabel.toLowerCase()}';
  }

  String get normalizedCustomLabel => customLabel?.trim() ?? '';

  bool get isValid =>
      unit != ShoppingUnit.custom || normalizedCustomLabel.isNotEmpty;

  @override
  bool operator ==(Object other) =>
      other is ShoppingUnitSelection &&
      other.unit == unit &&
      other.normalizedCustomLabel == normalizedCustomLabel;

  @override
  int get hashCode => Object.hash(unit, normalizedCustomLabel);
}

/// Aggregated local usage used to rank unit suggestions.
class ShoppingUnitUsage {
  const ShoppingUnitUsage({
    required this.selection,
    required this.useCount,
    required this.lastUsedAt,
  });

  final ShoppingUnitSelection selection;
  final int useCount;
  final DateTime lastUsedAt;
}

/// Unit suggestion returned to the presentation layer.
class ShoppingUnitSuggestion {
  const ShoppingUnitSuggestion({
    required this.selection,
    required this.useCount,
  });

  final ShoppingUnitSelection selection;
  final int useCount;
}
