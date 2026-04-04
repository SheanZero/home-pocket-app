import 'package:flutter/material.dart';

import '../../../../generated/app_localizations.dart';

class GroupRenameDialog extends StatefulWidget {
  const GroupRenameDialog({super.key, required this.currentName});

  final String currentName;

  static Future<String?> show(BuildContext context, String currentName) {
    return showDialog<String>(
      context: context,
      builder: (_) => GroupRenameDialog(currentName: currentName),
    );
  }

  @override
  State<GroupRenameDialog> createState() => _GroupRenameDialogState();
}

class _GroupRenameDialogState extends State<GroupRenameDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.currentName);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = S.of(context);
    return AlertDialog(
      title: Text(l10n.groupRename),
      content: TextField(
        controller: _controller,
        maxLength: 50,
        autofocus: true,
        decoration: InputDecoration(
          hintText: l10n.groupName,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(l10n.groupCancel),
        ),
        FilledButton(
          onPressed: () {
            final trimmed = _controller.text.trim();
            if (trimmed.isNotEmpty) Navigator.pop(context, trimmed);
          },
          child: Text(l10n.profileSave),
        ),
      ],
    );
  }
}
