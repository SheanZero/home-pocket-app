import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';

/// Shows a dialog to enter a backup password.
///
/// [isExport] true for export (requires confirm), false for import (single field).
/// Returns the password or null if cancelled.
Future<String?> showPasswordDialog(
  BuildContext context, {
  required String title,
  bool isExport = false,
}) async {
  return showDialog<String>(
    context: context,
    builder: (context) => _PasswordDialog(title: title, isExport: isExport),
  );
}

class _PasswordDialog extends StatefulWidget {
  const _PasswordDialog({required this.title, required this.isExport});

  final String title;
  final bool isExport;

  @override
  State<_PasswordDialog> createState() => _PasswordDialogState();
}

class _PasswordDialogState extends State<_PasswordDialog> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  String? _errorText;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  void _submit() {
    final password = _passwordController.text;

    if (password.length < 8) {
      setState(() => _errorText = S.of(context).passwordMinLength);
      return;
    }

    if (widget.isExport && password != _confirmController.text) {
      setState(() => _errorText = S.of(context).passwordsDoNotMatch);
      return;
    }

    Navigator.pop(context, password);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text(widget.title),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _passwordController,
            obscureText: true,
            decoration: InputDecoration(
              hintText: S.of(context).enterPassword,
              errorText: _errorText,
            ),
            onSubmitted: widget.isExport ? null : (_) => _submit(),
          ),
          if (widget.isExport) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _confirmController,
              obscureText: true,
              decoration: InputDecoration(hintText: S.of(context).confirmPassword),
              onSubmitted: (_) => _submit(),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(S.of(context).cancel),
        ),
        TextButton(onPressed: _submit, child: Text(S.of(context).ok)),
      ],
    );
  }
}
