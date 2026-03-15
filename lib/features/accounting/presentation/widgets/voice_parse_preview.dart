import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_text_styles.dart';
import '../../../../infrastructure/i18n/formatters/number_formatter.dart';
import '../../../settings/presentation/providers/locale_provider.dart';
import '../../domain/models/transaction.dart';
import '../../domain/models/voice_parse_result.dart';

/// Preview card showing the parsed voice input data.
///
/// Displays the extracted amount, merchant name, category, and ledger type.
/// Renders nothing if [parseResult] is null.
class VoiceParsePreview extends ConsumerWidget {
  final VoiceParseResult? parseResult;

  const VoiceParsePreview({super.key, this.parseResult});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final result = parseResult;
    if (result == null) return const SizedBox.shrink();

    final locale = ref.watch(currentLocaleProvider);

    final rows = <Widget>[];

    if (result.amount != null) {
      rows.add(
        _InfoRow(
          icon: Icons.payments_outlined,
          iconColor: AppColors.survival,
          label: NumberFormatter.formatCurrency(
            result.amount!.toDouble(),
            'JPY',
            locale,
          ),
        ),
      );
    }

    if (result.merchantName != null) {
      rows.add(
        _InfoRow(
          icon: Icons.store_outlined,
          iconColor: AppColors.survival,
          label: result.merchantName!,
        ),
      );
    }

    if (result.categoryMatch != null) {
      rows.add(
        _InfoRow(
          icon: Icons.folder_outlined,
          iconColor: AppColors.survival,
          label: result.categoryMatch!.categoryId,
        ),
      );
    }

    if (result.ledgerType != null) {
      final isSOul = result.ledgerType == LedgerType.soul;
      rows.add(
        _InfoRow(
          icon: isSOul ? Icons.favorite_outlined : Icons.home_outlined,
          iconColor: isSOul ? AppColors.soul : AppColors.survival,
          label: isSOul ? '灵魂帐本' : '生存帐本',
        ),
      );
    }

    if (rows.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: rows,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String label;

  const _InfoRow({
    required this.icon,
    required this.iconColor,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(icon, size: 18, color: iconColor),
          const SizedBox(width: 8),
          Expanded(child: Text(label, style: AppTextStyles.bodyMedium)),
        ],
      ),
    );
  }
}
