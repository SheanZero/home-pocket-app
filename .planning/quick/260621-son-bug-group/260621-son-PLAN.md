---
phase: quick-260621-son
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - lib/features/analytics/presentation/providers/state_donut_dimension.dart
  - lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart
  - lib/features/analytics/presentation/widgets/donut_hero.dart
  - lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  - lib/l10n/app_ja.arb
  - lib/l10n/app_zh.arb
  - lib/l10n/app_en.arb
autonomous: false
requirements: [BUG-1-self-name, BUG-2-self-option, BUG-3-controls-position]
must_haves:
  truths:
    - "成员维度圆环图例对『自己』那条记录显示设置→编辑个人资料里的用户名（如 Shean），不是截断 deviceId"
    - "在设置里改名后，重新进入/刷新统计页，成员维度显示的名字同步更新（同一个 userProfileProvider 数据源）"
    - "未加入任何 group 时，成员 filter 下拉至少有 [所有成员] + [自己]"
    - "分类/成员 toggle + 成员 filter 这一行位于圆环下方、详细列表上方"
    - "flutter analyze 0 issues；full flutter test 全绿；golden 在 macOS 重新基线"
  artifacts:
    - path: "lib/features/analytics/presentation/widgets/cards/category_donut_card.dart"
      provides: "watch userProfileProvider + self deviceId, build memberNames with self→profile name, inject self into member option list"
    - path: "lib/features/analytics/presentation/widgets/donut_hero.dart"
      provides: "controls slot rendered between donut Stack and legend rows (both category and member mode)"
    - path: "lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart"
      provides: "member option list = [所有成员] + [自己] + group members, dedup by deviceId"
  key_links:
    - from: "category_donut_card.dart"
      to: "userProfileProvider"
      via: "ref.watch"
      pattern: "userProfileProvider"
    - from: "category_donut_card.dart / donut_dimension_member_controls.dart"
      to: "keyManager.getDeviceId() (self deviceId)"
      via: "FutureProvider"
      pattern: "getDeviceId"
    - from: "donut_hero.dart"
      to: "DonutDimensionMemberControls"
      via: "controls slot widget rendered after donut, before legend"
      pattern: "controls"
---

<objective>
修复统计页「分类支出」圆环卡在 **成员维度** 下的 3 个 bug，全部位于 analytics feature 的 presentation 层。

1. **Bug 1 — 成员名用设置里的用户名并实时同步**：成员维度圆环图例当前对「自己」这条记录显示截断 deviceId（`95fayo…`）。改为显示用户在「设置 → 编辑个人资料」中设置的名字（截图为 "Shean"），且改名后同步。
2. **Bug 2 — 无 group 时也要有「自己」选项**：成员 filter 下拉当前只有「所有成员」。即使没加入任何 group/family，也要额外列出「自己」。
3. **Bug 3 — toggle + filter 行下移**：把「分类/成员」toggle 与成员 filter 这一行，从卡片顶部移到圆环(donut)下方、详细列表上方。

Purpose: 成员维度可用且名字可读、可同步；单人场景下也能按「自己」过滤；布局符合预期顺序（标题/总额 → 圆环 → toggle+filter → 详细列表）。
Output: 改动 3 个 analytics presentation 文件 + 1 个 provider + 3 个 ARB（新增「自己」标签），golden 重基线。
</objective>

<execution_context>
@$HOME/.claude/gsd-core/workflows/execute-plan.md
</execution_context>

<context>
@.planning/STATE.md

# 单一数据源 / 设备身份（已确认）
- 设置改名写入：`lib/features/profile/presentation/screens/profile_edit_screen.dart` 的 `_save()` → `saveUserProfileUseCase.execute(displayName: ...)`，随后 `ref.invalidate(userProfileProvider)`。
- 用户名读取的单一数据源：`userProfileProvider`（`lib/features/profile/presentation/providers/state_user_profile.dart`，`Future<UserProfile?>`，字段 `displayName`/`avatarEmoji`）。watch 它即可在改名后自动同步。
- 「自己」的 deviceId：交易写入时由 `keyManager.getDeviceId()`（`DeviceIdentityRepository.getDeviceId() → Future<String?>`）赋给 `transactions.deviceId`。`keyManagerProvider` 定义在 `lib/features/family_sync/presentation/providers/repository_providers.dart`（delegate 到 `appKeyManagerProvider`）。当前**没有**现成的 `currentDeviceIdProvider`，需新增一个轻量 FutureProvider 包一层 `keyManager.getDeviceId()`。
- 成员数据源（有 group 时）：`activeGroupMembersProvider`（`lib/features/family_sync/presentation/providers/state_sync.dart`），未加入 group 时返回 `[]`（这正是 Bug 2 根因）。`GroupMember` 字段含 `deviceId`/`displayName`/`deviceName`/`avatarEmoji`。

# 当前结构（已读）
- `category_donut_card.dart` 的 `wrap(hero)`：`Column[ controls, hero, JoySpendDrawer ]`，`controls = const DonutDimensionMemberControls()`。圆环渲染在 `hero` 内部 → Bug 3 要把 controls 从这里挪进 `DonutHero`（圆环 Stack 之后、legend 行之前）。
- `donut_hero.dart`：分类模式 `build()` 与成员模式 `_buildMemberMode()` 两个分支，各自结构为 `Column[ hero-top, SizedBox(donut Stack), SizedBox(height:12), ...legend rows ]`。两个分支都要插 controls slot。
- 成员名解析：card 里 `memberNames = { for m in members: m.deviceId: m.displayName?:deviceName?:deviceId }`（无 self、无 profile），`DonutHero.nameFor()` 兜底截断 deviceId → Bug 1 根因。

@lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
@lib/features/analytics/presentation/widgets/donut_hero.dart
@lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart
@lib/features/analytics/presentation/providers/state_donut_dimension.dart
</context>

<tasks>

<task type="auto" tdd="true">
  <name>Task 1: 新增 self-deviceId provider + 修复成员名用 profile 名（Bug 1）+ 无 group 也注入「自己」选项（Bug 2）</name>
  <files>
    lib/features/analytics/presentation/providers/state_donut_dimension.dart,
    lib/features/analytics/presentation/widgets/cards/category_donut_card.dart,
    lib/features/analytics/presentation/widgets/donut_dimension_member_controls.dart,
    lib/l10n/app_ja.arb, lib/l10n/app_zh.arb, lib/l10n/app_en.arb
  </files>
  <behavior>
    - Provider 单元（state_donut_dimension_test.dart 或新 provider 测试）：新增 `currentDeviceIdProvider`（FutureProvider 包 `keyManager.getDeviceId()`）override 后返回固定 deviceId。
    - Card 测试（category_donut_card_test.dart）成员维度：当 self deviceId 出现在 member breakdown 里、且 `userProfileProvider` override 为 displayName="Shean" 时，成员 legend 行显示 "Shean"（不是截断 deviceId）。
    - Card 测试：override `activeGroupMembersProvider` 为 `[]`（无 group）+ `userProfileProvider` displayName="Shean" + `currentDeviceIdProvider` 返回 self id，打开成员 filter sheet → 选项含「所有成员」与「Shean」（self）两项，self deviceId 去重不重复。
    - 改名同步语义：watch `userProfileProvider`（不是读快照），保证 invalidate 后名字更新（已有 invalidate 在 profile_edit `_save()`）。
  </behavior>
  <action>
    1) 在 `state_donut_dimension.dart` 末尾新增一个轻量 `@riverpod Future<String?> currentDeviceId(Ref ref)`，实现为 `ref.watch(keyManagerProvider).getDeviceId()`（import `keyManagerProvider` from family_sync repository_providers；keepAlive 不需要，普通 @riverpod 即可，与本文件其它 analytics 状态一致）。改注解后 MUST 跑 build_runner（见 verify）。理由：当前无现成 self-deviceId provider，这是「自己」识别的唯一来源（per Bug 1/2 单一数据源约束）。
    2) `category_donut_card.dart` build 顶部新增 `final profile = ref.watch(userProfileProvider).value;` 与 `final selfDeviceId = ref.watch(currentDeviceIdProvider).value;`（import userProfileProvider from profile state_user_profile.dart；currentDeviceIdProvider 同文件 state_donut_dimension）。
    3) 修改 `memberNames` 构建：先用 group members 的 displayName/deviceName 兜底（保留现状），然后**对 self 这条覆盖为 profile.displayName**——`if (selfDeviceId != null && profile != null && profile.displayName.isNotEmpty) memberNames[selfDeviceId] = profile.displayName;`。这样「自己」永远用设置里的名字（per Bug 1，单一数据源=userProfileProvider，改名实时同步）。self 的 avatarEmoji 同理可用 profile.avatarEmoji 覆盖进 memberEmojis（可选，名字是硬要求）。
    4) `donut_dimension_member_controls.dart`：把 sheet 与 trigger 用的 member 列表从「仅 activeGroupMembers」改为「注入了 self 的列表」。在 `build` 里 watch `userProfileProvider` + `currentDeviceIdProvider`，构造 `effectiveMembers`：先取 activeGroupMembers；若 self deviceId 不在其中，则 prepend 一个合成 self 项（用 profile.displayName 作 displayName，profile.avatarEmoji 作 avatarEmoji，deviceId=selfDeviceId）。用一个轻量内部 record/类或直接复用 `GroupMember`（构造一个 self 的 GroupMember，role/status 给合理默认值或留空字符串）承载 self，确保 `_displayName`/sheet/trigger 全部走同一列表。去重：按 deviceId 唯一（self 已在 group 成员里就不再追加）。`_filterLabel`/`_showMemberSheet`/`_filterLabel` 引用都改为这个 effectiveMembers。理由：未加入 group 时 activeGroupMembers=[]，必须额外列出「自己」（per Bug 2 = [所有成员] + [自己] + 其它）。
    5) profile.displayName 为空时的兜底：self 项 displayName 用一个新 ARB key `analyticsDonutMemberFilterSelf`（「自己」/「自分」/「Me」）作为 label（trigger/sheet/legend 解析名字时，self 且 profile 名为空 → 用该 self 标签，绝不回退到截断 deviceId）。三个 ARB 文件同步新增该 key + `@`描述，随后 `flutter gen-l10n`。所有文案经 `S.of(context)`，不硬编码（per CLAUDE.md i18n）。
    6) 不改 .g.dart/.freezed.dart 手写内容；改 @riverpod 后跑 build_runner 生成 state_donut_dimension.g.dart。
  </action>
  <verify>
    <automated>flutter pub run build_runner build --delete-conflicting-outputs && flutter gen-l10n && flutter analyze && flutter test test/widget/features/analytics/presentation/widgets/cards/category_donut_card_test.dart test/features/analytics/presentation/providers/state_donut_dimension_test.dart</automated>
  </verify>
  <done>
    成员维度对 self 记录显示 profile.displayName（"Shean"），改名 invalidate 后同步；无 group 时成员 filter 选项含「所有成员」+「自己」；新增 3-locale `analyticsDonutMemberFilterSelf`；analyze 0；上述测试绿。
  </done>
</task>

<task type="auto">
  <name>Task 2: 把 分类/成员 toggle + filter 行移到圆环与详细列表之间（Bug 3）+ 重基线 golden</name>
  <files>
    lib/features/analytics/presentation/widgets/donut_hero.dart,
    lib/features/analytics/presentation/widgets/cards/category_donut_card.dart
  </files>
  <action>
    1) `donut_hero.dart`：给 `DonutHero` 增加一个 `Widget? controls` 构造参数（nullable，默认 null）。在**分类模式 `build()`** 与**成员模式 `_buildMemberMode()`** 两个分支里，都把 controls 插入在「圆环 Stack 的 `SizedBox(height:200)`」之后、「`const SizedBox(height:12)` + legend 行」之前：即 `if (controls != null) controls!,` 放在 donut Stack 与 legend 之间（保持现有 spacing 视觉合理，可在 controls 前后保留/微调 SizedBox）。理由：期望顺序 标题/总额 → 圆环 → [toggle+filter] → 详细列表（per Bug 3）。
    2) `category_donut_card.dart` 的 `wrap(hero)`：把 `controls` 从卡片级 Column（`Column[controls, hero, JoySpendDrawer]`）移除，改为 `Column[hero, JoySpendDrawer]`，并把 controls 作为参数传进 `DonutHero(... controls: const DonutDimensionMemberControls())`——三处构造 DonutHero（成员模式、分类+filter 模式、分类无 filter 模式）都要传 controls，保证三条路径都显示该行。不要改动 donut/legend/中心总额等其余逻辑（仅位置重排，per 约束「不破坏 golden 以外逻辑」）。
    3) 受影响 golden：`category_donut_card_*`（value/other/empty/member_multi/member_solo 各 light/dark/locale 变体）与整页 `analytics_screen_scroll_smoke_*`。**在 macOS 上**用 `--update-goldens` 仅对受影响的 golden 测试文件重新基线（项目约定：goldens 为 macOS 基线，CI 为 ubuntu，见 STATE/memory）。scoped 更新以保持 diff 归因清晰。
    4) 若 donut card 的 widget 测试断言了 controls 相对位置（如 controls 在 hero 之前的 find 顺序），按新结构更新断言。
  </action>
  <verify>
    <automated>flutter test test/golden/category_donut_card_golden_test.dart test/golden/analytics_screen_scroll_smoke_golden_test.dart --update-goldens && flutter analyze && flutter test</automated>
  </verify>
  <done>
    toggle+filter 行渲染于圆环下方、详细列表上方；分类与成员两种维度、有/无 filter 三条路径均显示该行；受影响 golden 在 macOS 重基线；analyze 0；full flutter test 全绿。
  </done>
</task>

<task type="checkpoint:human-verify" gate="blocking">
  <what-built>
    成员维度圆环 bug 修复：①「自己」显示设置里的用户名（Shean）且改名同步；②无 group 时 filter 下拉含「所有成员」+「自己」；③分类/成员 toggle + filter 行移到圆环与详细列表之间。golden 已在 macOS 重基线、analyze 0、full test 全绿。
  </what-built>
  <how-to-verify>
    1. 真机/模拟器运行，进入统计页（图表 tab）「分类支出」卡片。
    2. 确认 toggle（分类|成员）+ filter 行现在位于圆环**下方**、详细列表**上方**。
    3. 切到「成员」维度：图例「自己」那条显示设置里的名字（应为 Shean，不是 95fayo… 截断 id）。
    4. 去「设置 → 编辑个人资料」改名 → 回统计页（必要时下拉刷新/重进 tab），确认成员维度名字同步更新。
    5. 点开 filter 下拉：确认在没有加入任何 group 的单人场景下，除「所有成员」外还有「自己（Shean）」可选，选它后圆环/详细只显示自己的支出。
  </how-to-verify>
  <resume-signal>回复 "approved" 或描述问题</resume-signal>
</task>

</tasks>

<verification>
- `flutter analyze` 0 issues。
- `flutter test` 全量绿（含 architecture / anti-toxicity / golden baseline-existence off-macOS）。
- golden 仅在 macOS 重基线，受影响文件 = category_donut_card_*、analytics_screen_scroll_smoke_*。
- self 名字单一数据源 = `userProfileProvider`（watch，非快照），与设置页改名 invalidate 链路一致。
- 无 group 场景 filter 含「自己」；改名后成员维度同步。
</verification>

<success_criteria>
- Bug 1：成员维度对 self 显示 profile.displayName，改名同步。
- Bug 2：无 group 时 filter 选项 = [所有成员] + [自己]（+ 有 family 则追加其它成员）。
- Bug 3：toggle + filter 行位于圆环下方、详细列表上方（分类/成员两维度、有无 filter 三路径一致）。
- 质量门：analyze 0、full test 绿、golden macOS 重基线、3-locale ARB 同步、不手改生成文件。
</success_criteria>

<output>
完成后创建 `.planning/quick/260621-son-bug-group/260621-son-SUMMARY.md`
</output>
