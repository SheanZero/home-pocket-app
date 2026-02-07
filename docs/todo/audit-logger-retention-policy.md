# TODO: AuditLogger 日志保留策略

**来源:** 可行性报告 4.2.2
**优先级:** 🟡 中
**预估工作量:** 0.5h
**关联文件:** `lib/infrastructure/security/audit_logger.dart`

---

## 问题描述

`AuditLogger` 缺少自动清理旧日志的机制，长期使用可能导致数据库膨胀。

## 建议实现

```dart
/// Delete logs older than [retentionDays].
/// Default: 90 days.
Future<int> pruneOldLogs({int retentionDays = 90}) async {
  final cutoff = DateTime.now().subtract(Duration(days: retentionDays));
  return await (_database.delete(_database.auditLogs)
    ..where((t) => t.timestamp.isSmallerThanValue(cutoff)))
    .go();
}
```

## 测试用例

```dart
group('pruneOldLogs', () {
  test('deletes logs older than retention period', () async {
    // Insert old log
    await logger.log(event: AuditEvent.appLaunched);
    // Manually backdate the timestamp in test
    
    final deleted = await logger.pruneOldLogs(retentionDays: 0);
    expect(deleted, greaterThan(0));
  });

  test('preserves logs within retention period', () async {
    await logger.log(event: AuditEvent.appLaunched);
    
    final deleted = await logger.pruneOldLogs(retentionDays: 90);
    expect(deleted, 0);
    
    final remaining = await logger.getLogCount();
    expect(remaining, 1);
  });
});
```

## 可选扩展

1. **自动清理调度** - 在 AppInitializer 中定期调用
2. **按日志类型保留** - 某些关键事件保留更久
3. **导出后清理** - 清理前自动导出到备份

## 验收标准

- [ ] `pruneOldLogs` 方法已实现
- [ ] 单元测试通过
- [ ] 默认保留 90 天
- [ ] 返回删除的日志数量
