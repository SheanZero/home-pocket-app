import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class InfoHintBox extends StatelessWidget {
  const InfoHintBox({
    super.key,
    required this.message,
    this.icon = Icons.info_outline,
  });

  final String message;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFEEF4FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: AppColors.survival),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 12,
                color: AppColors.survival,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
