import 'package:flutter/material.dart';

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    super.key,
    required this.label,
    required this.backgroundColor,
    required this.textColor,
    this.dotColor,
  });

  const StatusBadge.owner({Key? key, required String label})
    : this(
        key: key,
        label: label,
        backgroundColor: const Color(0xFFE8F5E9),
        textColor: const Color(0xFF2E7D32),
      );

  const StatusBadge.pending({Key? key, required String label})
    : this(
        key: key,
        label: label,
        backgroundColor: const Color(0xFFFFF8E1),
        textColor: const Color(0xFFF57F17),
        dotColor: const Color(0xFFF9A825),
      );

  const StatusBadge.synced({Key? key, required String label})
    : this(
        key: key,
        label: label,
        backgroundColor: const Color(0xFFE8F5E9),
        textColor: const Color(0xFF2E7D32),
        dotColor: const Color(0xFF4CAF50),
      );

  final String label;
  final Color backgroundColor;
  final Color textColor;
  final Color? dotColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (dotColor != null) ...[
            Container(
              width: 8,
              height: 8,
              decoration: BoxDecoration(
                color: dotColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: TextStyle(
              fontFamily: 'IBM Plex Sans',
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
