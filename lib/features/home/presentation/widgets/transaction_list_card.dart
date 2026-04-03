import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme_colors.dart';

/// A rounded card container that wraps transaction rows with dividers.
///
/// Children are separated by 1px [AppColors.backgroundDivider] lines.
/// The outer container has a 1px [AppColors.borderList] stroke and
/// 12px border radius.
class TransactionListCard extends StatelessWidget {
  const TransactionListCard({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.hardEdge,
      decoration: BoxDecoration(
        color: context.wmCard,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.wmBorderList),
      ),
      child: Column(children: _intersperseDividers(context, children)),
    );
  }

  List<Widget> _intersperseDividers(BuildContext context, List<Widget> items) {
    if (items.isEmpty) return items;
    final result = <Widget>[];
    for (var i = 0; i < items.length; i++) {
      result.add(items[i]);
      if (i < items.length - 1) {
        result.add(Container(height: 1, color: context.wmBackgroundDivider));
      }
    }
    return result;
  }
}
