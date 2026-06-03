# Quick Task 260603-nr1: 首页/记账 UI 优化 + 反应式 bug 修复 - Context

**Gathered:** 2026-06-03
**Status:** Ready for planning — design gates confirmed via HTML mockups

<domain>
## Task Boundary

六项修改（用户确认顺序）：
1. 重设记账反馈（错误/成功提示）→ 不阻碍连续记账
2. 替换首页「悦己充盈」「本月最爱」标题图标
3. 首页 悦己vs日常 bar 取消悦己渐变 → 纯色
4. 月度列表项加 padding + 右侧「›」可点击标识
5. 修复：删除/编辑子项后首页 + 分析页不刷新
6. 账目编辑页增加删除功能

设计稿确认 mockup：`mockups/01-feedback.html`、`mockups/02-icons.html`
</domain>

<decisions>
## Implementation Decisions (LOCKED — do not revisit)

### #1 记账反馈重设计 — 方案 A「顶部轻吐司」
- 错误与成功**统一**用顶部下滑胶囊条（沿用现有 SoftToast 顶部风格）。成功=绿 `success #2FA37A`，错误=红 `error #E5484D`。
- **新增金额校验**：当前 `manual_one_step_screen._trySave()` 只校验类目缺失（line ~272-278），未校验金额。新增「金额为 0/未输入」时弹错误吐司且**不**保存。错误文案走 i10n（新增 key，如 `pleaseEnterAmount`，三语 ja/zh/en + `flutter gen-l10n`）。
- **成功后不关页（连续记账）**：当前 `_save()` 成功分支（line ~295-300）调用 `ScaffoldMessenger...SnackBar` + `Navigator.popUntil((r)=>r.isFirst)`。改为：① 顶部成功吐司；② 复位表单（金额归零、类目清空、焦点回金额）保持页面打开；③ 由 AppBar 关闭(X)按钮或返回主动退出。删除 popUntil。
- **统一反馈 helper**：抽出共享反馈入口（成功/错误两态），复用现有 `soft_toast.dart`（`lib/features/accounting/presentation/widgets/soft_toast.dart`，含 error 配色）扩展出 success 配色变体；或新增一个 overlay helper（参考 `voice_error_toast.dart` 的 Overlay 模式）。替换散落的 `ScaffoldMessenger.showSnackBar` 成功调用。
- **额外（用户追加）**：把「确认删除」弹窗也改成相同柔和风格——当前是默认 Material `AlertDialog`（见 `list_transaction_tile.dart:97-131` confirmDismiss）。改成圆角、暖色卡片、palette 配色的自定义确认对话框（保留 取消/删除 两个动作；删除按钮 `palette.error`）。抽成共享确认对话框 helper，列表滑删 + 编辑页删除 都复用。

### #2 标题图标
- 「悦己充盈」→ `Icons.eco`（叶片，选项 F）。位置：`home_hero_card.dart` ring section header（~line 299-320），当前 `Icons.auto_awesome`。
- 「本月最爱」→ `Icons.workspace_premium`（勋章，选项 I）。位置：`home_hero_card.dart` best-joy strip header（~line 658-688），当前 `Icons.auto_awesome`。
- 仅替换 IconData，保持 16px / `palette.joy` / 布局不变。

### #3 悦己vs日常 bar 取消渐变
- `home_hero_card.dart` `_splitBar()`（~line 196-252）悦己段当前 `LinearGradient(colors:[palette.joy.withValues(alpha:0.6), palette.joy])`。
- 改为纯色 `palette.joy`（与日常段 `palette.daily` 纯色一致）。去掉 LinearGradient，用 `Container(color: palette.joy)` 或 `BoxDecoration(color: palette.joy)`。

### #4 月度列表项 padding + 「›」chevron（共存）
- `list_transaction_tile.dart`：tile 内层 padding `EdgeInsets.symmetric(horizontal: 10, vertical: 14)`（~line 148）→ horizontal **16**（vertical 保持 14）。
- 在金额（trailing，~line 250-257）**之后**新增 `SizedBox(width: 6)` + `Icon(Icons.chevron_right, size: 18, color: palette.textSecondary)`（浅色细箭头）。
- 与现有 `Dismissible(direction: endToStart)`（~line 88-96，右滑删除）**共存**——iOS 邮件/提醒事项同款模式，静态尾部箭头不拦截滑动手势，无需改 Dismissible。
- 注意 golden master 会变（tile 布局），执行后需 `--update-goldens` 重新基线（参考 STATE 既往做法）。

### #5 反应式刷新 bug 修复（删除 + 编辑 → 首页 + 分析页）
**根因**：首页/分析的 4 个 provider 是一次性 `FutureProvider`，删除/编辑只 invalidate 了 list + calendar，未 invalidate 它们；solo 模式无 sync 兜底故首页常驻陈旧。
- 受影响 provider（家族 invalidate 全部实例即可）：
  - `todayTransactionsProvider` — `lib/features/home/presentation/providers/state_today_transactions.dart`
  - `monthlyReportProvider` — `lib/features/analytics/presentation/providers/state_analytics.dart`
  - `happinessReportProvider` / `bestJoyMomentProvider` — `lib/features/analytics/presentation/providers/state_happiness.dart`
- **方案（locked）= 共享 invalidation helper（不引入新 @riverpod，无需 codegen）**：新增一个普通顶层函数（如 `lib/features/.../invalidate_transaction_dependents.dart` 或放 list_screen 邻近 shared util），签名接收 `WidgetRef ref`（+ 必要的 bookId/year/month keyed 参数），内部 `ref.invalidate(...)`：listTransactions、calendarDailyTotals、today、monthly、happiness、bestJoy。
- 调用点：① 列表滑删 `onDeleted()`（list_screen 当前只 invalidate list+calendar，~line 291-297）扩展为调用该 helper；② 编辑保存返回 `result==true` 后 `invalidateAfterMutation()`（list_screen ~line 302-319）扩展为调用该 helper；③ 新增的编辑页删除（#6）成功后同样调用。
- 既有 `MainShellScreen` 的 sync 兜底 invalidation（~line 38-102）保留不动。
- 备注：不采用「全面改 Drift watch 流」的大重构（风险/范围超出 quick）。targeted invalidation 与 MainShellScreen 现有模式一致。

### #6 编辑页删除功能
- `TransactionEditScreen` — `lib/features/accounting/presentation/screens/transaction_edit_screen.dart`，当前 AppBar（~line 94-112）无 actions。
- 在 AppBar `actions:` 加红色删除 IconButton（`Icons.delete_outline`，`palette.error`）→ 弹 #1 的统一柔和确认对话框 → 确认后 `ref.read(deleteTransactionUseCaseProvider).execute(widget.transaction.id)` → 调用 #5 共享 invalidation helper → `Navigator.pop(context, true)`（复用既有 caller 失效逻辑）。
- 删除/取消文案复用现有 i10n key（`listDeleteConfirmTitle/Body/Button/Cancel`，已存在）。

### Claude's Discretion
- 反馈 helper 的具体落点（扩展 soft_toast vs 新 overlay helper）由执行者按最小改动选择，但成功/错误必须同一入口。
- 共享确认对话框与共享 invalidation helper 的确切文件路径/命名由执行者按项目 thin-feature 结构就近放置。
- 新增 i10n key 命名。
</decisions>

<specifics>
## Specific Ideas

- 调色板（fidelity）：success `#2FA37A`、error `#E5484D`、joy `#D98CA0`、daily `#5FAE72`、textSecondary `#71877A`、border `#E6DDD8`。dark 变体见 `app_palette.dart`。
- 反馈成功吐司文案示例：「已记录 ¥1,280 · 继续记账」。错误：「请先输入金额」「请先选择类目」。
- 连续记账复位：参考 manual_one_step_screen.dart line ~189-194 既有的金额/焦点复位模式。
</specifics>

<canonical_refs>
## Canonical References

- 配色权威：`docs/arch/03-adr/ADR-019_Palette_Selection_v1_6.md`（樱粉×若叶）
- i18n 规则：CLAUDE.md「i18n Rules」——三语同步 + `flutter gen-l10n`
- Riverpod 3 约定：CLAUDE.md「Riverpod 3 conventions」（provider 名去 Notifier 后缀、ref.listen 副作用等）
- 金额样式：`AppTextStyles.amountLarge/Medium/Small`（tabularFigures）
</canonical_refs>

<verification>
## Done-when
- `flutter analyze` 0 issues
- `flutter test`（含 golden masters，#4 需 --update-goldens 后全绿）
- 三语 ARB 同步 + `flutter gen-l10n` 通过（若新增 key）
- 手验：连续记账不关页；删除/编辑后首页+分析页即时刷新；编辑页可删除
</verification>
