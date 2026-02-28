import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Input widget for entering a 6-digit pair code.
class PairCodeInput extends StatefulWidget {
  const PairCodeInput({
    super.key,
    required this.onSubmit,
    this.isLoading = false,
    this.errorMessage,
  });

  final void Function(String code) onSubmit;
  final bool isLoading;
  final String? errorMessage;

  @override
  State<PairCodeInput> createState() => _PairCodeInputState();
}

class _PairCodeInputState extends State<PairCodeInput> {
  final _controller = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void dispose() {
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleSubmit() {
    final code = _controller.text.replaceAll(' ', '');
    if (code.length == 6) {
      widget.onSubmit(code);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TextField(
          controller: _controller,
          focusNode: _focusNode,
          autofocus: true,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineLarge?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: 8,
          ),
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(6),
          ],
          decoration: InputDecoration(
            hintText: '000 000',
            hintStyle: theme.textTheme.headlineLarge?.copyWith(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              letterSpacing: 8,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ),
            errorText: widget.errorMessage,
          ),
          onChanged: (_) => setState(() {}),
          onSubmitted: (_) => _handleSubmit(),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: FilledButton(
            onPressed: _controller.text.replaceAll(' ', '').length == 6 &&
                    !widget.isLoading
                ? _handleSubmit
                : null,
            child: widget.isLoading
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Join'),
          ),
        ),
      ],
    );
  }
}
