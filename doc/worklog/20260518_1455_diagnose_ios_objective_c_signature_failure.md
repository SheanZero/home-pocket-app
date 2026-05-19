# Diagnose: iOS install failed — `objective_c.framework : 0xe8008014`

**日期:** 2026-05-18
**时间:** 14:55
**任务类型:** Bug 修复 / 诊断
**状态:** 已完成（已确认 clean build 通过签名校验；待用户在真机 install 验证）
**相关模块:** iOS Build / Flutter native-assets / Code Signing

---

## 任务概述

继 `20260518_1421_fix_ios_sqlcipher_load_conflict.md` 之后，用户在 iPhone 真机执行 `flutter run`，install 阶段被 iOS 拒绝：

> 无法安装 "Home Pocket"
> Failed to verify code signature of /var/installd/Library/Caches/com.apple.mobile.installd.staging/temp.o0FBbl/extracted/Runner.app/Frameworks/objective_c.framework : 0xe8008014 (The executable contains an invalid signature.)

附带的 terminal 还显示 "Flutter could not access the local network" + `SocketException: No route to host, port = 5353` — 这是 macOS Local Network 权限提示，独立的 dev-tooling 问题，不阻塞 install。

---

## 根因分析

### 失败现场（修复前）

`codesign -dvvv build/ios/iphoneos/Runner.app/Frameworks/objective_c.framework`：

```
Identifier=io.flutter.flutter.native-assets.objective-c
Format=bundle with Mach-O universal (x86_64 arm64)
Signature=adhoc
TeamIdentifier=not set
```

并且 `file objective_c` 显示是 fat binary，同时包含 `x86_64`（simulator slice）和 `arm64`（device slice）。

对比同一 .app 里其它 framework：

| Framework | Signature | TeamID | Archs |
|---|---|---|---|
| `App.framework` (Flutter Dart) | ✅ Apple Development cert | `6Y64KR8RLP` | arm64 |
| `Flutter.framework` (Flutter 引擎) | ✅ Apple Development cert | `6Y64KR8RLP` | arm64 |
| `local_auth_darwin.framework` (CocoaPods) | ✅ Apple Development cert | `6Y64KR8RLP` | arm64 |
| **`objective_c.framework`** (native-asset) | ❌ **adhoc** | **not set** | **fat: x86_64 + arm64** |

iOS 在 install 阶段拒绝 ad-hoc 签名的 framework（ad-hoc 仅对 simulator/本地有效），同时 iphoneos build 中残留 x86_64 slice 也违反规则。错误码 `0xe8008014` = `MIInstallerErrorDomain` 的 invalid signature。

`objective_c` 是新引入的 transitive dep：`local_auth 3.x → local_auth_darwin → objective_c 9.3.0`（用于 Objective-C interop）。该包不通过 CocoaPods 发布，而是用 Dart 的 `hook/build.dart` + `code_assets` 系统在构建时本地编译 dylib，再由 Flutter 工具链包装为 `.framework` 嵌入 app bundle。

### 误判 → 推倒重来

**最初假设：** Flutter 的 native-assets 管线在 Xcode 签名阶段被遗漏，需要在 `Runner.xcodeproj` 加一个 Run Script Phase 显式 re-sign。

**实施：** 在 `ios/Runner/` 新增 `ReSignNativeAssetFrameworks.sh`，并在 `Runner` target 的 `buildPhases` 末尾追加一个 `PBXShellScriptBuildPhase` 指向该脚本。脚本逻辑：扫描 `$CODESIGNING_FOLDER_PATH/Frameworks/*.framework`，对仍为 adhoc 的目标做 `lipo -remove x86_64` + `codesign --force --sign $EXPANDED_CODE_SIGN_IDENTITY`。

**Ablation 测试推翻假设：**
1. 加上 build phase 做 `flutter clean && flutter pub get && pod install && flutter build ios --debug` → framework 正常签名。
2. **撤掉 build phase** 重做同样的 clean rebuild → framework **仍然**正常签名（Apple Development cert，arm64 only）。
3. 脚本运行时打印的诊断显示 `$CODESIGNING_FOLDER_PATH/Frameworks` 在脚本扫描时是**空目录**——Xcode 现代 build system 中，"Embed Frameworks" 的 PBXCopyFilesBuildPhase 实际执行时机晚于所有 PBXShellScriptBuildPhase，因此脚本即便存在也碰不到 frameworks。

结论：**Xcode 默认的自动 codesign 阶段已经能正确签 `objective_c.framework`**，自定义 build phase 是无效的 no-op。

### 真正的根因

那么用户最初看到的 adhoc 签名是怎么来的？最可能的链条：

1. 前一个 worklog 中的 SQLCipher 验证步骤用了 `flutter build ios --debug --no-codesign --simulator` —— 这会在 `build/ios/Debug-iphonesimulator/` 产生 adhoc 签名的 `objective_c.framework`。
2. 用户随后 `flutter run` 切换到 iphoneos device target。Xcode 的增量 build + Flutter 的 `xcode_backend.sh embed_and_thin`（基于 rsync）在某些状态下会复用旧产物。
3. 该过程留下了一个 adhoc 签名的 framework 在 `build/ios/iphoneos/...`，Xcode 最终 codesign 阶段没有覆写 framework 内部的 adhoc 签名（codesign 默认不递归 re-sign 子 bundle）。
4. iOS install 阶段做完整签名校验时拒绝。

`flutter clean` 把 `build/ios/` 彻底清掉后，下一次 device build 走完整流程，Xcode 自动 codesign 正确签了 framework。

---

## 完成的工作

### 1. 推翻并撤销错误修复

- 撤掉 `ios/Runner.xcodeproj/project.pbxproj` 里新增的 `PBXShellScriptBuildPhase` 和 `buildPhases` 中的引用（两处编辑都回到原始状态）。
- 删除 `ios/Runner/ReSignNativeAssetFrameworks.sh`。
- 验证 `git diff --stat ios/Runner.xcodeproj/project.pbxproj` 为空，`plutil -lint project.pbxproj` OK。

### 2. 确认真正的修复路径

clean rebuild 之后：

- `codesign -dvv build/ios/iphoneos/Runner.app/Frameworks/objective_c.framework`：
  ```
  Authority=Apple Development: XIN ZHANG (C234QTVQH9)
  TeamIdentifier=6Y64KR8RLP
  ```
- `file objective_c`：`Mach-O universal binary with 1 architecture: [arm64:...]`
- `codesign --verify --deep --strict --verbose=2 build/ios/iphoneos/Runner.app`：
  ```
  build/ios/iphoneos/Runner.app: valid on disk
  build/ios/iphoneos/Runner.app: satisfies its Designated Requirement
  ```

### 3. 用户操作

实际修复就一行：

```bash
flutter clean && flutter run
```

> 之前 `flutter run` 失败留下的污染 build/ 目录需要 clean 一次才能从干净状态重建。

---

## 遇到的问题与解决方案

### 问题 1：第一次的修复"看起来"起作用，但其实没动

**症状：** 加 build phase 后 framework 签名正确，撤掉后依然正确。
**根因：** Xcode build system 中 `PBXShellScriptBuildPhase` 的 listing 顺序 ≠ 实际执行顺序；PBXCopyFilesBuildPhase ("Embed Frameworks") 的执行时机晚于所有 shell script phase，所以放在 buildPhases 末尾的脚本无法看到 Frameworks 内容。
**结论：** 必须用 ablation test 验证修复是否真的在做事。脚本里加诊断 echo 比"假定一切正常"靠谱得多。

### 问题 2：`flutter build ios --debug` 输出中大量 `EXPANDED_CODE_SIGN_IDENTITY = -`

**症状：** verbose 日志显示一堆 `CODE_SIGNING_REQUIRED = NO` 和 `EXPANDED_CODE_SIGN_IDENTITY = -`。
**调查：** 这些是 Pods / 其它非 Runner target 的 build config 输出，Runner 自己的 EXPANDED_CODE_SIGN_IDENTITY 是真实的 cert hash（`FA439D318EC9292BF36BE5E513FC00CF430D501F`）。
**结论：** `flutter build ios --debug`（不带 `--no-codesign`）确实做完整签名，不要被 Pods 的 adhoc placeholder 误导。

### 问题 3：Local Network / Bonjour 错误是次要问题

**症状：** terminal 里 `Flutter could not access the local network` + `SocketException: No route to host, port = 5353`。
**性质：** macOS Local Network 权限拒绝了 Flutter 的 mDNS 广播。这只影响 hot reload 的 Dart VM 连接，不影响 install 本身。
**解决：** System Settings → Privacy & Security → Local Network → 把 Terminal/iTerm/Warp（或当前在跑 `flutter run` 的程序）打开权限。安装成功后 hot reload 就能用了。

---

## 测试验证

- [x] 撤销 build phase 后 `plutil -lint project.pbxproj` OK
- [x] `git diff --stat` 确认 pbxproj 已回到原状（只剩前一个 worklog 的 Podfile 改动）
- [x] `flutter clean && flutter pub get && pod install && flutter build ios --debug` 成功
- [x] `codesign -dvv` 确认 `objective_c.framework` Apple Development 签名 + arm64-only
- [x] `codesign --verify --deep --strict` 整个 Runner.app 通过
- [ ] **待用户：** 在 iPhone 上执行 `flutter clean && flutter run`，确认 install 通过 + app 启动
- [ ] **待用户：** 给当前 terminal 授予 macOS Local Network 权限，让 hot reload 工作

---

## Git 提交记录

本次诊断**无代码变更**——只是确认了 `20260518_1421_fix_ios_sqlcipher_load_conflict.md` 之后用户需要的额外步骤是 `flutter clean`，而非额外的 build phase。

仅新增本 worklog。

---

## 后续工作

- [ ] 用户做 `flutter clean && flutter run` 验证 install 成功
- [ ] 可选：在 CLAUDE.md 的 "iOS Build" 段落添加一行"切换 simulator/device 或者切换 `--no-codesign` / 带签名 build 之间时，先 `flutter clean`，避免 adhoc framework 污染 device build"
- [ ] 可选：上游 Flutter issue（Flutter 工具链在 `xcode_backend.sh embed_and_thin` 阶段对 native-assets framework 不做 force-overwrite，可能在切换 build 模式时遗留旧产物）— 这超出本次 scope

---

## 参考资源

- 前置 worklog：`doc/worklog/20260518_1421_fix_ios_sqlcipher_load_conflict.md`
- `objective_c` 包：https://pub.dev/packages/objective_c
- `local_auth` 3.x changelog：https://pub.dev/packages/local_auth/changelog
- Apple MIInstallerError 0xe8008014：`The executable contains an invalid signature.`

---

**创建时间:** 2026-05-18 14:55
**作者:** Claude Opus 4.7
