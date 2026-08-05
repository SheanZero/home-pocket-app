import 'package:flutter/material.dart';

import '../../core/theme/app_text_styles.dart';

/// Shared ledger badge and merchant detail for transaction rows.
///
/// Both the full List row and the compact Home row render this identical
/// personal-ledger detail. The caller retains ownership of the surrounding
/// family-row and layout decisions.
class TransactionLedgerDetail extends StatelessWidget {
  const TransactionLedgerDetail({
    super.key,
    required this.tagText,
    required this.tagBackgroundColor,
    required this.tagTextColor,
    required this.supportingTextColor,
    this.merchant,
    this.tagFontWeight,
  });

  final String tagText;
  final Color tagBackgroundColor;
  final Color tagTextColor;
  final Color supportingTextColor;
  final String? merchant;
  final FontWeight? tagFontWeight;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: tagBackgroundColor,
            borderRadius: BorderRadius.circular(4),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          child: Text(
            tagText,
            style: AppTextStyles.compact.copyWith(
              color: tagTextColor,
              fontWeight: tagFontWeight,
            ),
            maxLines: 1,
          ),
        ),
        if (merchant != null) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              merchant!,
              style: AppTextStyles.supporting.copyWith(
                color: supportingTextColor,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
