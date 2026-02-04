# AuthResult Freezed Union Type Fix Plan

**日期:** 2026-02-04
**问题:** AuthResult 类缺少 `when` 和 `maybeWhen` 方法
**根本原因:** AuthResult 被定义为单构造函数 Freezed 类，但代码中将其作为 union 类型使用
**状态:** 待执行

---

## 问题分析

### 当前定义 (❌ 错误)
```dart
@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult({
    required AuthStatus status,
    String? message,
    int? failedAttempts,
  }) = _AuthResult;  // 单一构造函数

  // 这些工厂方法返回的都是同一个构造函数的实例
  factory AuthResult.success() => const AuthResult(status: AuthStatus.success);
  factory AuthResult.failed(int attempts) => AuthResult(...);
  // ...
}
```

### 问题
- `.when()` 和 `.maybeWhen()` 方法**只在 Freezed union 类型中可用**
- 当前 AuthResult 只有一个构造函数 `AuthResult()`
- 代码在 line 223 和 234 尝试使用 union 类型的方法，导致编译错误

### 预期定义 (✅ 正确)
```dart
@freezed
class AuthResult with _$AuthResult {
  const factory AuthResult.success() = AuthSuccess;
  const factory AuthResult.failed(int failedAttempts) = AuthFailed;
  const factory AuthResult.fallbackToPIN() = AuthFallbackToPIN;
  const factory AuthResult.tooManyAttempts() = AuthTooManyAttempts;
  const factory AuthResult.lockedOut() = AuthLockedOut;
  const factory AuthResult.error(String message) = AuthError;
}
```

---

## 修复计划

### Phase 1: 备份和准备 (1 分钟)

**Task 1.1: 备份当前文件**
```bash
# 创建备份
cp lib/features/security/domain/models/auth_result.dart \
   lib/features/security/domain/models/auth_result.dart.backup

# 验证备份成功
ls -la lib/features/security/domain/models/auth_result.dart.backup
```

---

### Phase 2: 重构 AuthResult 为 Union 类型 (3 分钟)

**Task 2.1: 修改 AuthResult 定义**

**文件:** `lib/features/security/domain/models/auth_result.dart`

**完整的新实现:**
```dart
import 'package:freezed_annotation/freezed_annotation.dart';

part 'auth_result.freezed.dart';

/// Authentication result with multiple variants using Freezed union type
@freezed
class AuthResult with _$AuthResult {
  /// Authentication succeeded
  const factory AuthResult.success() = AuthSuccess;

  /// Authentication failed with number of attempts
  const factory AuthResult.failed({
    required int failedAttempts,
  }) = AuthFailed;

  /// Device does not support biometric authentication, fallback to PIN required
  const factory AuthResult.fallbackToPIN() = AuthFallbackToPIN;

  /// Too many failed attempts, temporarily locked
  const factory AuthResult.tooManyAttempts() = AuthTooManyAttempts;

  /// Account locked out due to security policy
  const factory AuthResult.lockedOut() = AuthLockedOut;

  /// Authentication error occurred
  const factory AuthResult.error({
    required String message,
  }) = AuthError;
}
```

**关键变更说明:**
1. ❌ 删除 `AuthStatus` enum（不再需要）
2. ❌ 删除单一构造函数 `factory AuthResult({...})`
3. ✅ 添加 6 个命名构造函数（union variants）
4. ✅ 每个构造函数都有一个对应的具体类型（如 `AuthSuccess`, `AuthFailed` 等）
5. ✅ `failedAttempts` 和 `message` 参数移到相应的 variant 中

---

### Phase 3: 代码生成 (1 分钟)

**Task 3.1: 删除旧的生成文件**
```bash
# 删除旧的 .freezed.dart 文件
rm -f lib/features/security/domain/models/auth_result.freezed.dart

# 验证删除成功
ls lib/features/security/domain/models/auth_result.freezed.dart 2>/dev/null || echo "✅ 已删除"
```

**Task 3.2: 运行 build_runner**
```bash
# 生成新的 Freezed 代码
flutter pub run build_runner build --delete-conflicting-outputs

# 预期输出:
# [INFO] Generating build script...
# [INFO] Generating build script completed, took 500ms
# [INFO] Creating build script snapshot...
# [INFO] Building new asset graph...
# [INFO] Running build...
# [INFO] 1.5s elapsed, 1/3 actions completed.
# [INFO] 3.2s elapsed, 3/3 actions completed.
# [INFO] Succeeded after 3.3s with 2 outputs
```

**Task 3.3: 验证生成文件**
```bash
# 检查生成的文件是否存在
ls -la lib/features/security/domain/models/auth_result.freezed.dart

# 验证 .freezed.dart 文件包含 when 方法
grep -n "when(" lib/features/security/domain/models/auth_result.freezed.dart | head -5
```

**预期输出:**
```
lib/features/security/domain/models/auth_result.freezed.dart
# 应该包含类似以下内容:
# - AuthSuccess class
# - AuthFailed class
# - when() method definition
# - maybeWhen() method definition
```

---

### Phase 4: 更新使用 AuthResult 的代码 (5 分钟)

**Task 4.1: 扫描所有使用 AuthResult 的文件**
```bash
# 查找所有使用 AuthResult 的文件
grep -r "AuthResult" lib/ --include="*.dart" | grep -v ".freezed.dart" | grep -v ".g.dart"
```

**Task 4.2: 更新 BiometricLock 服务实现**

**文件:** `lib/features/security/application/services/biometric_lock.dart` (假设路径)

**需要更新的代码模式:**

**之前 (可能的错误用法):**
```dart
// 如果代码中有这样的用法:
return AuthResult(status: AuthStatus.success);
return AuthResult(status: AuthStatus.failed, failedAttempts: attempts);
```

**修改为:**
```dart
// 使用新的 union constructors:
return const AuthResult.success();
return AuthResult.failed(failedAttempts: attempts);
return const AuthResult.fallbackToPIN();
return const AuthResult.tooManyAttempts();
return const AuthResult.lockedOut();
return AuthResult.error(message: errorMessage);
```

**Task 4.3: 验证 security_test_screen.dart 不需要修改**

**文件:** `lib/features/security/presentation/screens/security_test_screen.dart:223-234`

**当前代码 (✅ 已经正确):**
```dart
final resultText = result.when(
  success: () => '✅ 认证成功',
  failed: (attempts) => '❌ 认证失败 (尝试次数: $attempts)',
  fallbackToPIN: () => '⚠️ 需要使用PIN码',
  tooManyAttempts: () => '❌ 尝试次数过多',
  lockedOut: () => '❌ 已锁定',
  error: (message) => '❌ 错误: $message',
);

// ...

isError: !result.maybeWhen(
  success: () => true,
  orElse: () => false,
),
```

**说明:** 这段代码已经按照 union 类型的用法编写，修改 AuthResult 定义后应该可以直接工作。

**注意参数名称变更:**
- `failed: (attempts)` 应该匹配新定义中的参数名 `failedAttempts`

**可能需要的小调整:**
```dart
// 检查参数名是否需要调整
final resultText = result.when(
  success: () => '✅ 认证成功',
  failed: (failedAttempts) => '❌ 认证失败 (尝试次数: $failedAttempts)',  // 参数名可能需要调整
  fallbackToPIN: () => '⚠️ 需要使用PIN码',
  tooManyAttempts: () => '❌ 尝试次数过多',
  lockedOut: () => '❌ 已锁定',
  error: (message) => '❌ 错误: $message',
);
```

---

### Phase 5: 编译和测试 (3 分钟)

**Task 5.1: 清理构建缓存**
```bash
# 清理 Flutter 缓存
flutter clean

# 重新获取依赖
flutter pub get
```

**Task 5.2: 运行静态分析**
```bash
# 运行 Dart 分析器
flutter analyze

# 预期输出:
# Analyzing home_pocket...
# No issues found!
```

**Task 5.3: 尝试编译**
```bash
# 尝试构建 iOS 模拟器版本
flutter run -d "iPhone 15 Pro"

# 或者只做检查编译
flutter build ios --debug --no-codesign
```

**预期结果:**
- ✅ 没有 "method 'when' isn't defined" 错误
- ✅ 没有 "method 'maybeWhen' isn't defined" 错误
- ✅ 编译成功

**Task 5.4: 运行安全模块测试**
```bash
# 运行安全模块的单元测试
flutter test test/features/security/

# 预期输出:
# 00:xx +XX: All tests passed!
```

---

### Phase 6: 验证和文档 (2 分钟)

**Task 6.1: 手动测试生物识别功能**

启动应用后，在 Security Test Screen 中:
1. 点击 "Face ID/Touch ID 认证" 按钮
2. 验证 `.when()` 方法正常工作，显示正确的结果文本
3. 验证 `.maybeWhen()` 方法正常工作，错误状态正确显示

**Task 6.2: 提交更改**
```bash
# 查看更改
git status
git diff lib/features/security/domain/models/auth_result.dart

# 添加文件
git add lib/features/security/domain/models/auth_result.dart
git add lib/features/security/application/services/biometric_lock.dart  # 如果有修改

# 提交
git commit -m "fix(security): convert AuthResult to Freezed union type

- Convert AuthResult from single constructor to union type with 6 variants
- Remove AuthStatus enum (replaced by union variants)
- Add named constructors: success, failed, fallbackToPIN, tooManyAttempts, lockedOut, error
- Fix compilation errors in security_test_screen.dart (lines 223, 234)
- Enable .when() and .maybeWhen() pattern matching

Fixes: AuthResult missing 'when' and 'maybeWhen' methods
Module: MOD-006 Security & Privacy"
```

---

## 技术决策说明

### 为什么使用 Union 类型？

**Union 类型的优势:**
1. **类型安全:** 编译时保证所有情况都被处理（`.when()` 强制处理所有 variants）
2. **模式匹配:** 清晰的模式匹配语法，比 switch-case 更安全
3. **不可变性:** Freezed 自动生成 immutable 类
4. **代码生成:** 自动生成 `copyWith`, `==`, `hashCode`, `toString` 等方法

**替代方案（为什么不选）:**
- ❌ **Enum + 数据类:** 需要手动管理数据和状态，容易出错
- ❌ **继承层次:** 需要手动实现 `==` 和 `hashCode`，代码冗长
- ❌ **Sealed classes (Dart 3.0+):** Freezed union 已经足够成熟且功能丰富

---

## 风险评估

### 高风险
- ❌ 无（这是纯重构，不改变业务逻辑）

### 中风险
- ⚠️ **其他文件可能使用旧的 AuthResult API**
  - **缓解措施:** Task 4.1 会扫描所有使用 AuthResult 的文件
  - **验证:** 编译器会报错所有不兼容的用法

### 低风险
- ⚠️ **测试可能需要更新**
  - **缓解措施:** Task 5.4 运行测试验证

---

## 回滚计划

如果修复失败，可以快速回滚：

```bash
# 恢复备份
cp lib/features/security/domain/models/auth_result.dart.backup \
   lib/features/security/domain/models/auth_result.dart

# 重新生成代码
flutter pub run build_runner build --delete-conflicting-outputs

# 验证
flutter analyze
```

---

## 执行时间估算

- Phase 1: 备份和准备 - **1 分钟**
- Phase 2: 重构 AuthResult - **3 分钟**
- Phase 3: 代码生成 - **1 分钟**
- Phase 4: 更新相关代码 - **5 分钟**
- Phase 5: 编译和测试 - **3 分钟**
- Phase 6: 验证和文档 - **2 分钟**

**总计: 约 15 分钟**

---

## 执行检查清单

执行前确认:
- [ ] 已阅读完整计划
- [ ] 理解 union 类型的概念
- [ ] 准备好回滚方案
- [ ] 确保当前代码已提交（无未保存的更改）

执行后验证:
- [ ] `flutter analyze` 无错误
- [ ] 编译成功（无 "method 'when' isn't defined" 错误）
- [ ] 单元测试通过
- [ ] 手动测试生物识别功能正常
- [ ] Git 提交已完成

---

## 参考资源

- [Freezed Documentation - Union types](https://pub.dev/packages/freezed#union-types-and-sealed-classes)
- [Effective Dart - Pattern Matching](https://dart.dev/guides/language/effective-dart)
- `doc/arch/01-core-architecture/ARCH-004_State_Management.md` - Freezed 使用规范

---

**计划版本:** 1.0
**创建时间:** 2026-02-04
**作者:** Claude Sonnet 4.5
**状态:** ✅ 待用户审批
