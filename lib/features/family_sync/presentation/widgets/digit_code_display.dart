import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class DigitCodeDisplay extends StatelessWidget {
  const DigitCodeDisplay({super.key, required this.code, this.digitCount = 6});

  final String code;
  final int digitCount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(digitCount, (index) {
        final value = index < code.length ? code[index] : '';
        return Padding(
          padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
          child: Container(
            width: 44,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFEEF4FA)),
            ),
            alignment: Alignment.center,
            child: Text(
              value,
              style: const TextStyle(
                fontFamily: 'IBM Plex Sans',
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
          ),
        );
      }),
    );
  }
}
