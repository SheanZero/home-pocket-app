import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

class OtpDigitInput extends StatefulWidget {
  const OtpDigitInput({
    super.key,
    required this.onChanged,
    required this.onCompleted,
    this.digitCount = 6,
  });

  final ValueChanged<String> onChanged;
  final ValueChanged<String> onCompleted;
  final int digitCount;

  @override
  State<OtpDigitInput> createState() => _OtpDigitInputState();
}

class _OtpDigitInputState extends State<OtpDigitInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleTextChanged);
  }

  void _handleTextChanged() {
    final text = _controller.text;
    widget.onChanged(text);
    if (text.length == widget.digitCount) {
      widget.onCompleted(text);
    }
    setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_handleTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = _controller.text;

    return GestureDetector(
      onTap: _focusNode.requestFocus,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Opacity(
            opacity: 0,
            child: SizedBox(
              width: 1,
              height: 1,
              child: TextField(
                controller: _controller,
                focusNode: _focusNode,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(widget.digitCount),
                ],
                decoration: const InputDecoration(border: InputBorder.none),
              ),
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(widget.digitCount, (index) {
              final hasDigit = index < text.length;
              final isActive = index == text.length && _focusNode.hasFocus;
              final borderColor = isActive || hasDigit
                  ? AppColors.survival
                  : AppColors.divider;

              return Padding(
                padding: EdgeInsets.only(left: index == 0 ? 0 : 8),
                child: Container(
                  width: 48,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: borderColor,
                      width: isActive || hasDigit ? 2 : 1,
                    ),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    hasDigit ? text[index] : '',
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
          ),
        ],
      ),
    );
  }
}
