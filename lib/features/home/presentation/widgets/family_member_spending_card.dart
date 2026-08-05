import 'package:flutter/material.dart';

import '../../../../application/i18n/formatter_service.dart';
import '../../../../core/theme/app_palette.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../generated/app_localizations.dart';
import '../../../profile/presentation/widgets/avatar_display.dart';

class FamilyMemberSpendingItem {
  const FamilyMemberSpendingItem({
    required this.deviceId,
    required this.displayName,
    required this.avatarEmoji,
    this.avatarImagePath,
    required this.totalExpenses,
    required this.joyTotal,
    required this.dailyTotal,
  });

  final String deviceId;
  final String displayName;
  final String avatarEmoji;
  final String? avatarImagePath;
  final int totalExpenses;
  final int joyTotal;
  final int dailyTotal;
}

/// Mockup A2 member-spending block: a section heading outside the card, then
/// one detailed row per family member with avatar, ledger split, and amount.
class FamilyMemberSpendingCard extends StatelessWidget {
  const FamilyMemberSpendingCard({
    super.key,
    required this.items,
    required this.currencyCode,
    required this.locale,
    this.onMemberTap,
  });

  final List<FamilyMemberSpendingItem> items;
  final String currencyCode;
  final Locale locale;
  final ValueChanged<FamilyMemberSpendingItem>? onMemberTap;

  static const FormatterService _formatter = FormatterService();

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) return const SizedBox.shrink();
    final palette = context.palette;
    final l10n = S.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.groups_rounded,
              size: 16,
              color: palette.accentPrimaryText,
            ),
            const SizedBox(width: 6),
            Text(
              l10n.homeMembersSectionTitle,
              style: AppTextStyles.label.copyWith(
                fontWeight: FontWeight.w700,
                color: palette.textPrimary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: palette.card,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: palette.borderDefault),
            boxShadow: [
              BoxShadow(
                color: palette.navShadow,
                blurRadius: 22,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Column(
            children: [
              for (var index = 0; index < items.length; index++) ...[
                _MemberRow(
                  item: items[index],
                  currencyCode: currencyCode,
                  locale: locale,
                  onTap: onMemberTap == null
                      ? null
                      : () => onMemberTap!(items[index]),
                ),
                if (index < items.length - 1)
                  Divider(
                    height: 1,
                    thickness: 1,
                    color: palette.borderDivider,
                  ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MemberRow extends StatelessWidget {
  const _MemberRow({
    required this.item,
    required this.currencyCode,
    required this.locale,
    this.onTap,
  });

  final FamilyMemberSpendingItem item;
  final String currencyCode;
  final Locale locale;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    final l10n = S.of(context);
    final total = item.joyTotal + item.dailyTotal;
    final joyRatio = total <= 0 ? 0.0 : (item.joyTotal / total).clamp(0.0, 1.0);
    return InkWell(
      key: Key('family-member-row-${item.deviceId}'),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 17, 10, 16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AvatarDisplay(
              emoji: item.avatarEmoji,
              imagePath: item.avatarImagePath,
              size: 44,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          item.displayName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.itemTitle.copyWith(
                            fontWeight: FontWeight.w700,
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        FamilyMemberSpendingCard._formatter.formatCurrency(
                          item.totalExpenses,
                          currencyCode,
                          locale,
                        ),
                        style: AppTextStyles.numerals(
                          AppTextStyles.amountSmall.copyWith(
                            color: palette.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 2),
                      Icon(
                        Icons.chevron_right,
                        size: 17,
                        color: palette.textSecondary,
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Wrap(
                    spacing: 9,
                    runSpacing: 2,
                    children: [
                      _LedgerAmount(
                        dotColor: palette.joy,
                        label: l10n.joy,
                        amount: item.joyTotal,
                        amountColor: palette.joyText,
                        currencyCode: currencyCode,
                        locale: locale,
                      ),
                      _LedgerAmount(
                        dotColor: palette.daily,
                        label: l10n.daily,
                        amount: item.dailyTotal,
                        amountColor: palette.dailyText,
                        currencyCode: currencyCode,
                        locale: locale,
                      ),
                    ],
                  ),
                  const SizedBox(height: 7),
                  ClipRRect(
                    key: Key('family-member-split-${item.deviceId}'),
                    borderRadius: BorderRadius.circular(999),
                    child: Stack(
                      children: [
                        Container(height: 5, color: palette.daily),
                        FractionallySizedBox(
                          widthFactor: joyRatio,
                          child: Container(height: 5, color: palette.joy),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerAmount extends StatelessWidget {
  const _LedgerAmount({
    required this.dotColor,
    required this.label,
    required this.amount,
    required this.amountColor,
    required this.currencyCode,
    required this.locale,
  });

  final Color dotColor;
  final String label;
  final int amount;
  final Color amountColor;
  final String currencyCode;
  final Locale locale;

  @override
  Widget build(BuildContext context) {
    final palette = context.palette;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 7,
          height: 7,
          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: AppTextStyles.compact.copyWith(color: palette.textSecondary),
        ),
        const SizedBox(width: 4),
        Text(
          FamilyMemberSpendingCard._formatter.formatCurrency(
            amount,
            currencyCode,
            locale,
          ),
          style: AppTextStyles.numerals(
            AppTextStyles.compact.copyWith(
              fontWeight: FontWeight.w700,
              color: amountColor,
            ),
          ),
        ),
      ],
    );
  }
}
