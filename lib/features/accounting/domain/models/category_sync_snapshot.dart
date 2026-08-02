import 'transaction.dart';

/// E2EE wire snapshot for the shared semantics of a custom category.
///
/// Personal preferences (`sortOrder`, `isArchived`, and
/// `category_ledger_configs`) are deliberately absent. [ledgerTypeHint] is a
/// historical hint only: the transaction's own `ledgerType`/`joyFullness`
/// remain authoritative and receivers never write the hint into personal
/// category configuration.
class CategorySyncSnapshot {
  const CategorySyncSnapshot({
    required this.id,
    required this.name,
    required this.icon,
    required this.color,
    required this.parentId,
    required this.level,
    required this.revision,
    required this.originDeviceId,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    required this.ledgerTypeHint,
  });

  final String id;
  final String name;
  final String icon;
  final String color;
  final String? parentId;
  final int level;
  final int revision;
  final String originDeviceId;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final LedgerType ledgerTypeHint;

  Map<String, dynamic> toSyncMap() => {
    'schemaVersion': 1,
    'id': id,
    'name': name,
    'icon': icon,
    'color': color,
    if (parentId != null) 'parentId': parentId,
    'level': level,
    'revision': revision,
    'originDeviceId': originDeviceId,
    'isDeleted': isDeleted,
    'createdAt': createdAt.toUtc().toIso8601String(),
    if (updatedAt != null) 'updatedAt': updatedAt!.toUtc().toIso8601String(),
    'ledgerTypeHint': ledgerTypeHint.name,
  };

  factory CategorySyncSnapshot.fromSyncMap(Map<String, dynamic> data) {
    final schemaVersion = (data['schemaVersion'] as num?)?.toInt();
    final id = data['id'];
    final name = data['name'];
    final icon = data['icon'];
    final color = data['color'];
    final parentId = data['parentId'];
    final level = (data['level'] as num?)?.toInt();
    final revision = (data['revision'] as num?)?.toInt();
    final origin = data['originDeviceId'];
    final deleted = data['isDeleted'];
    final createdRaw = data['createdAt'];
    final updatedRaw = data['updatedAt'];
    final ledgerRaw = data['ledgerTypeHint'];
    final createdAt = createdRaw is String
        ? DateTime.tryParse(createdRaw)
        : null;
    final updatedAt = updatedRaw is String
        ? DateTime.tryParse(updatedRaw)
        : null;

    if (schemaVersion != 1 ||
        id is! String ||
        id.isEmpty ||
        id.length > 128 ||
        name is! String ||
        name.isEmpty ||
        name.length > 50 ||
        icon is! String ||
        icon.isEmpty ||
        icon.length > 80 ||
        color is! String ||
        !RegExp(r'^#[0-9A-Fa-f]{6}$').hasMatch(color) ||
        (parentId != null && (parentId is! String || parentId.isEmpty)) ||
        (level != 1 && level != 2) ||
        (level == 1 && parentId != null) ||
        (level == 2 && parentId == null) ||
        revision == null ||
        revision <= 0 ||
        origin is! String ||
        origin.isEmpty ||
        origin.length > 128 ||
        deleted is! bool ||
        createdAt == null ||
        (updatedRaw != null && updatedAt == null) ||
        ledgerRaw is! String ||
        !const {'daily', 'joy'}.contains(ledgerRaw)) {
      throw const FormatException('invalid custom category snapshot');
    }

    return CategorySyncSnapshot(
      id: id,
      name: name,
      icon: icon,
      color: color.toUpperCase(),
      parentId: parentId as String?,
      level: level!,
      revision: revision,
      originDeviceId: origin,
      isDeleted: deleted,
      createdAt: createdAt.toUtc(),
      updatedAt: updatedAt?.toUtc(),
      ledgerTypeHint: LedgerType.values.byName(ledgerRaw),
    );
  }

  String get deterministicPayloadKey => [
    name,
    icon,
    color,
    parentId ?? '',
    level.toString(),
    createdAt.toUtc().toIso8601String(),
    updatedAt?.toUtc().toIso8601String() ?? '',
    ledgerTypeHint.name,
  ].join('\u0000');
}
