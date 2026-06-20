import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../family_sync/domain/models/group_member.dart';
import '../../../family_sync/presentation/providers/state_sync.dart';
import '../providers/state_donut_dimension.dart';

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

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // 分类 / 成员 segmented toggle.
          Wrap(
            spacing: 8,
            children: [
              _DimPill(
                key: const ValueKey('donut_dim_category'),
                label: l10n.analyticsDonutDimensionCategory,
                selected: view.dimension == DonutDimension.category,
                onTap: () => ref
                    .read(donutDimensionStateProvider.notifier)
                    .setDimension(DonutDimension.category),
              ),
              _DimPill(
                key: const ValueKey('donut_dim_member'),
                label: l10n.analyticsDonutDimensionMember,
                selected: view.dimension == DonutDimension.member,
                onTap: () => ref
                    .read(donutDimensionStateProvider.notifier)
                    .setDimension(DonutDimension.member),
              ),
            ],
          ),
          // Member filter trigger.
          _MemberFilterTrigger(
            label: _filterLabel(l10n, members, view.memberFilterDeviceId),
            onTap: () => _showMemberSheet(context, ref, l10n, members),
          ),
        ],
      ),
    );
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

class _DimPill extends StatelessWidget {
  const _DimPill({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final bg = selected ? palette.daily : palette.card;
    final fg = selected ? palette.card : palette.textSecondary;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: palette.daily, width: 1),
        ),
        child: Text(
          label,
          style: AppTextStyles.caption.copyWith(
            color: fg,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
    );
  }
}

class _MemberFilterTrigger extends StatelessWidget {
  const _MemberFilterTrigger({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: palette.card,
          border: Border.all(color: palette.borderDefault),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: palette.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 4),
            Text(
              '▼',
              style: AppTextStyles.caption.copyWith(
                fontSize: 9,
                color: palette.textSecondary,
              ),
            ),
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
