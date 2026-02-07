# AppDatabase 初始化时序检查清单

**来源:** 可行性报告 风险评估
**优先级:** 🔴 高（影响应用启动）
**关联文件:** 
- `lib/infrastructure/security/providers.dart`
- `lib/infrastructure/crypto/database/encrypted_database.dart`
- `lib/main.dart`

---

## 初始化顺序（必须严格按序）

```
┌─────────────────────────────────────────────────────────────┐
│  1. WidgetsFlutterBinding.ensureInitialized()               │
├─────────────────────────────────────────────────────────────┤
│  2. SecureStorage 初始化                                     │
├─────────────────────────────────────────────────────────────┤
│  3. MasterKeyRepository 初始化                               │
│     └── 检查 hasMasterKey()                                  │
│     └── 如需要: initializeMasterKey()                        │
├─────────────────────────────────────────────────────────────┤
│  4. createEncryptedExecutor(masterKeyRepo)                  │
├─────────────────────────────────────────────────────────────┤
│  5. AppDatabase(executor)                                   │
├─────────────────────────────────────────────────────────────┤
│  6. ProviderScope + overrides                               │
│     └── appDatabaseProvider.overrideWithValue(database)     │
├─────────────────────────────────────────────────────────────┤
│  7. runApp()                                                │
└─────────────────────────────────────────────────────────────┘
```

---

## 检查项

### ✅ 启动前检查

- [ ] `appDatabaseProvider` 在 `providers.dart` 中定义为占位符
- [ ] 占位符抛出 `UnimplementedError`，提示必须 override
- [ ] `MasterKeyRepository` 接口已定义 `hasMasterKey()` 方法
- [ ] `createEncryptedExecutor` 接受 `MasterKeyRepository` 参数

### ✅ main.dart 实现检查

- [ ] `WidgetsFlutterBinding.ensureInitialized()` 在最开始调用
- [ ] MasterKey 初始化在 Database 创建之前
- [ ] Database 创建使用 `await`（异步）
- [ ] `ProviderScope.overrides` 包含 `appDatabaseProvider`
- [ ] 无其他 Provider 在 override 之前使用 `appDatabaseProvider`

### ✅ 异常处理检查

- [ ] MasterKey 初始化失败有错误处理
- [ ] Database 创建失败有 fallback 策略（或明确错误提示）
- [ ] `MasterKeyNotInitializedException` 被正确捕获
- [ ] `SecureStorageException` 被正确捕获

### ✅ 测试检查

- [ ] 集成测试使用 `AppDatabase.forTesting()` 或内存数据库
- [ ] 测试不依赖真实 SecureStorage
- [ ] Provider override 在测试中正确配置

---

## 示例代码

```dart
// lib/main.dart
Future<void> main() async {
  // 1. Flutter 绑定
  WidgetsFlutterBinding.ensureInitialized();

  // 2. 安全存储
  const secureStorage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.unlocked_this_device,
    ),
  );

  // 3. Master Key
  final masterKeyRepo = MasterKeyRepositoryImpl(secureStorage: secureStorage);
  if (!await masterKeyRepo.hasMasterKey()) {
    await masterKeyRepo.initializeMasterKey();
  }

  // 4. 加密数据库
  final executor = await createEncryptedExecutor(masterKeyRepo);
  final database = AppDatabase(executor);

  // 5. 启动应用
  runApp(
    ProviderScope(
      overrides: [
        appDatabaseProvider.overrideWithValue(database),
      ],
      child: const MyApp(),
    ),
  );
}
```

---

## 常见错误

| 错误 | 原因 | 解决方案 |
|------|------|---------|
| `UnimplementedError: appDatabaseProvider must be overridden` | 未在 main.dart 中 override | 添加 ProviderScope.overrides |
| `MasterKeyNotInitializedException` | 首次启动未初始化 | 调用 initializeMasterKey() |
| `StateError: SQLCipher not loaded` | 数据库密钥派生失败 | 检查 MasterKeyRepository 状态 |
| Provider 循环依赖 | 初始化顺序错误 | 按上述顺序严格执行 |
