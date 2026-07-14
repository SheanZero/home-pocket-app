import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../family_sync/domain/models/group_member.dart';
import '../../../family_sync/presentation/providers/state_sync.dart';
import '../../../profile/presentation/providers/state_user_profile.dart';
import '../providers/state_donut_dimension.dart';
import 'analytics_segmented_control.dart';

/// §D2 (260620-v2m): the 分类 / 成员 dimension toggle + member-filter dropdown
/// shown at the top of the donut hero.
///
/// Single-device / not-in-group degrades gracefully: the dimension toggle still
/// renders; the member filter lists only 所有成员 (+ any resolved members), never
/// erroring or blanking (D2). All labels via `S.of(context)`; ADR-019 palette.
class DonutDimensionMemberControls extends ConsumerWidget {
  const DonutDimensionMemberControls({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = S.of(context);
    final view = ref.watch(donutDimensionStateProvider);
    final members =
        ref.watch(activeGroupMembersProvider).value ?? const <GroupMember>[];
    // 260621-son Bug 2: even with no group joined, the filter must list 「自己」.
    final profile = ref.watch(userProfileProvider).value;
    final selfDeviceId = ref.watch(currentDeviceIdProvider).value;
    final effectiveMembers = _withSelf(
      members,
      selfDeviceId,
      profile?.displayName ?? '',
      profile?.avatarEmoji ?? '',
      l10n,
    );

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          // 分类 / 成员 segmented toggle (v15 mock `.analytics-dimension-segments`:
          // カテゴリ別 → daily tone, メンバー別 → shared tone).
          Expanded(
            child: AnalyticsSegmentedControl<DonutDimension>(
              selected: view.dimension,
              onChanged: (dimension) => ref
                  .read(donutDimensionStateProvider.notifier)
                  .setDimension(dimension),
              segments: [
                AnalyticsSegment(
                  value: DonutDimension.category,
                  label: l10n.analyticsDonutDimensionCategory,
                  tone: SegmentTone.daily,
                  optionKey: const ValueKey('donut_dim_category'),
                ),
                AnalyticsSegment(
                  value: DonutDimension.member,
                  label: l10n.analyticsDonutDimensionMember,
                  tone: SegmentTone.shared,
                  optionKey: const ValueKey('donut_dim_member'),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          // Member filter trigger — constrained so a long localized member name
          // never overflows the controls row (ellipsized).
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 120),
            child: _MemberFilterTrigger(
              key: const ValueKey('donut_member_filter_trigger'),
              label: _filterLabel(
                l10n,
                effectiveMembers,
                view.memberFilterDeviceId,
              ),
              onTap: () =>
                  _showMemberSheet(context, ref, l10n, effectiveMembers),
            ),
          ),
        ],
      ),
    );
  }

  /// 260621-son Bug 2: returns [members] with a synthesized self entry
  /// prepended when the self deviceId is not already among the group members.
  /// The self entry carries the profile name (or the localized「自己」label when
  /// the profile name is empty), deduped by deviceId. Single-device / no-group
  /// degrades to exactly `[self]` here.
  static List<GroupMember> _withSelf(
    List<GroupMember> members,
    String? selfDeviceId,
    String selfDisplayName,
    String selfAvatarEmoji,
    S l10n,
  ) {
    if (selfDeviceId == null) return members;
    if (members.any((m) => m.deviceId == selfDeviceId)) return members;
    final selfMember = GroupMember(
      deviceId: selfDeviceId,
      publicKey: '',
      deviceName: '',
      role: '',
      status: '',
      displayName: selfDisplayName.isNotEmpty
          ? selfDisplayName
          : l10n.analyticsDonutMemberFilterSelf,
      avatarEmoji: selfAvatarEmoji,
    );
    return [selfMember, ...members];
  }

  static String _filterLabel(
    S l10n,
    List<GroupMember> members,
    String? selectedDeviceId,
  ) {
    if (selectedDeviceId == null) return l10n.analyticsDonutMemberFilterAll;
    final m = members.where((m) => m.deviceId == selectedDeviceId);
    if (m.isEmpty) return l10n.analyticsDonutMemberFilterAll;
    return _displayName(m.first);
  }

  static String _displayName(GroupMember m) {
    if (m.displayName.isNotEmpty) return m.displayName;
    if (m.deviceName.isNotEmpty) return m.deviceName;
    return m.deviceId.length <= 6
        ? m.deviceId
        : '${m.deviceId.substring(0, 6)}…';
  }

  Future<void> _showMemberSheet(
    BuildContext context,
    WidgetRef ref,
    S l10n,
    List<GroupMember> members,
  ) {
    final selected = ref.read(donutDimensionStateProvider).memberFilterDeviceId;
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.analyticsDonutMemberFilterLabel,
                  style: AppTextStyles.titleSmall.copyWith(
                    color: context.palette.textPrimary,
                  ),
                ),
                const SizedBox(height: 16),
                // 所有成员 (default / clear).
                _MemberOptionTile(
                  selected: selected == null,
                  emoji: null,
                  title: l10n.analyticsDonutMemberFilterAll,
                  onTap: () {
                    ref
                        .read(donutDimensionStateProvider.notifier)
                        .setMemberFilter(null);
                    Navigator.of(sheetContext).pop();
                  },
                ),
                for (final m in members)
                  _MemberOptionTile(
                    selected: selected == m.deviceId,
                    emoji: m.avatarEmoji,
                    title: _displayName(m),
                    onTap: () {
                      ref
                          .read(donutDimensionStateProvider.notifier)
                          .setMemberFilter(m.deviceId);
                      Navigator.of(sheetContext).pop();
                    },
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _MemberFilterTrigger extends StatelessWidget {
  const _MemberFilterTrigger({
    super.key,
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    // v15 mock `.analytics-member-filter`: pill with a leading person icon,
    // centered ellipsized label, and a trailing expand_more chevron.
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        height: 42,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        decoration: BoxDecoration(
          color: palette.card,
          border: Border.all(color: palette.borderDefault),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.person_outline, size: 16, color: palette.textSecondary),
            const SizedBox(width: 3),
            Flexible(
              child: Text(
                label,
                textAlign: TextAlign.center,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 2),
            Icon(Icons.expand_more, size: 15, color: palette.textSecondary),
          ],
        ),
      ),
    );
  }
}

class _MemberOptionTile extends StatelessWidget {
  const _MemberOptionTile({
    required this.selected,
    required this.emoji,
    required this.title,
    required this.onTap,
  });

  final bool selected;
  final String? emoji;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return ListTile(
      selected: selected,
      selectedColor: palette.accentPrimary,
      leading: (emoji != null && emoji!.isNotEmpty)
          ? Text(emoji!, style: const TextStyle(fontSize: 20))
          : null,
      title: Text(
        title,
        style: AppTextStyles.bodyMedium.copyWith(
          color: selected ? palette.accentPrimary : palette.textPrimary,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        ),
      ),
      onTap: onTap,
    );
  }
}
