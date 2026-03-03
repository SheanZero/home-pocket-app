import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class SyncStatsCard extends StatelessWidget {
  const SyncStatsCard({
    super.key,
    required this.memberCount,
    required this.syncedEntries,
    required this.lastSyncText,
    required this.memberLabel,
    required this.syncedLabel,
    required this.lastSyncLabel,
  });

  final int memberCount;
  final int syncedEntries;
  final String lastSyncText;
  final String memberLabel;
  final String syncedLabel;
  final String lastSyncLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEEF4FA)),
      ),
      child: Row(
        children: [
          _StatItem(value: '$memberCount', label: memberLabel),
          const SizedBox(width: 12),
          _StatItem(value: '$syncedEntries', label: syncedLabel),
          const SizedBox(width: 12),
          _StatItem(
            value: lastSyncText,
            label: lastSyncLabel,
            smallValue: true,
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.value,
    required this.label,
    this.smallValue = false,
  });

  final String value;
  final String label;
  final bool smallValue;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.background,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: smallValue ? 16 : 24,
                fontWeight: FontWeight.w700,
                color: AppColors.survival,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
